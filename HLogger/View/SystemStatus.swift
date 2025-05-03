//
//  SystemStatus.swift
//  HLogger
//
//  Created by Hugooooo on 3/5/25.
//

import SwiftUI

struct SystemStatusView: View {
    @StateObject private var appController = AppController()
    
    // App state
    @State private var isLocationTrackingActive = false
    
    // S3 sync state
    @State private var s3Uploader: S3Uploader?
    @State private var lastSyncedFile: String? = "Checking..."
    
    // Log date selection
    @State private var availableLogDates: [Date] = []
    @State private var selectedDate: Date? = nil
    @State private var showUploadConfirmation = false
    
    var body: some View {
        VStack {
            List {
                // Location Toggle Section
                Section(header: Text("Service Status")) {
                    HStack {
                        Text("Location Tracking")
                        Spacer()
                        Toggle("", isOn: $isLocationTrackingActive)
                            .labelsHidden()
                            .onChange(of: isLocationTrackingActive) { _, newValue in
                                newValue ? appController.startLocationModule()
                                : appController.stopLocationModule()
                            }
                    }
                }
                
                // S3 Sync Section
                Section(header: Text("Log Sync Status")) {
                    HStack {
                        Text("Last Synced")
                        Spacer()
                        Text(lastSyncedFile ?? "N/A")
                            .foregroundColor(.secondary)
                    }
                    
                    if !availableLogDates.isEmpty {
                        DatePicker(
                            "Select Log Date",
                            selection: Binding(
                                get: { selectedDate ?? availableLogDates.last ?? Date() },
                                set: { selectedDate = $0 }
                            ),
                            in: availableLogDates.first!...availableLogDates.last!,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .padding(.vertical, 5)
                    } else {
                        Text("No logs available").foregroundColor(.gray)
                    }
                    
                    Button("Upload Selected Log") {
                        showUploadConfirmation = true
                    }
                    .padding(.top, 5)
                    .disabled(s3Uploader == nil || availableLogDates.isEmpty)
                    .alert("Upload Confirmation", isPresented: $showUploadConfirmation) {
                        Button("Cancel", role: .cancel) {}
                        Button("Upload", role: .destructive) {
                            Task { await uploadSelectedLog() }
                        }
                    } message: {
                        Text("Are you sure you want to upload the log file for \(formattedSelectedDate())?")
                    }
                }
            }
        }
        .task {
            await initializeS3Uploader()
            await checkLastSyncedFile()
            loadAvailableLogDates()
        }
        .onAppear {
            checkServiceStatus()
        }
    }
    
    /// Location Toggle Initialization
    private func checkServiceStatus() {
        isLocationTrackingActive = appController.checkLocationModuleStatus()
    }
    
    /// S3 Initialization
    private func initializeS3Uploader() async {
        s3Uploader = await S3Uploader()
    }
    
    /// Load Available Log Dates from Local Files
    private func loadAvailableLogDates() {
        let logFiles = HFileManager.shared.listFiles(withSuffix: "location.pb")
        let formatter = dateFormatter()
        
        let dates = logFiles.compactMap { fileName in
            formatter.date(from: String(fileName.prefix(10)))  // Parse yyyy-MM-dd
        }.sorted()
        
        availableLogDates = dates
        
        if selectedDate == nil || !dates.contains(selectedDate!) {
            selectedDate = dates.last
        }
    }
    
    /// Check Recently Uploaded Log File
    private func checkLastSyncedFile() async {
        guard let s3Uploader else {
            print("S3Uploader not initialized.")
            return
        }
        
        let formatter = dateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let today = Date()
        
        let fileNames: [String] = (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: today).map {
                "\(formatter.string(from: $0))_location.pb"
            }
        }
        
        let s3Paths = fileNames.map { "rawdata/location/\($0.prefix(10))Z/\($0)" }
        
        for (index, s3Path) in s3Paths.enumerated() {
            do {
                let exists = try await s3Uploader.checkIfFileExists(s3Key: s3Path)
                if exists {
                    let fileDate = formatter.date(from: String(fileNames[index].prefix(10)))
                    DispatchQueue.main.async {
                        self.lastSyncedFile = fileNames[index]
                        AppState.shared.lastSyncedDate = fileDate
                    }
                    return
                }
            } catch {
                print("S3 error checking path \(s3Path): \(error)")
            }
        }
        
        // No match found
        DispatchQueue.main.async {
            self.lastSyncedFile = "No sync found (-7d)"
            AppState.shared.lastSyncedDate = nil
        }
    }
    
    /// Upload Selected Log to S3
    private func uploadSelectedLog() async {
        guard let s3Uploader else {
            print("S3Uploader not initialized.")
            return
        }
        
        guard let selectedDate else {
            print("No valid date selected.")
            return
        }
        
        let dateString = HDateTime.shared.string(from: selectedDate).prefix(10)
        await s3Uploader.uploadFileIfNeeded(
            for: String(dateString),
            fileSuffix: "location",
            directoryPrefix: "rawdata/location"
        )
        
        await checkLastSyncedFile()
    }
    
    /// Date formatter Helpers
    private func formattedSelectedDate() -> String {
        guard let selectedDate else { return "Unknown Date" }
        return dateFormatter().string(from: selectedDate)
    }
    
    private func dateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
