//
//  LogBrowser.swift
//  HLogger
//
//  Created by Hugooooo on 3/5/25.
//

import SwiftUI

struct LogBrowserView: View {
    // App-level State
    @StateObject private var appState = AppState.shared
    
    @State private var logFiles: [HFileManager.FileMetadata] = []
    @State private var selectedFileContent: HFileManager.FileContent?
    
    @State private var showDeleteConfirmation = false
    @State private var pendingDeleteFile: HFileManager.FileMetadata?
    
    private let logSuffix = "location.pb"
    private let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    @State private var timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            List {
                let sortedFiles = logFiles.sorted { $0.timestamp > $1.timestamp }
                ForEach(sortedFiles) { metadata in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(metadata.fileName)
                                .font(.headline)
                            Text("Entries: \(metadata.entryCount), Size: \(metadata.fileSize / 1024) KB")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button("View") {
                            previewLog(metadata.fileName)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .onDelete(perform: handleDelete)
            }
            .onAppear(perform: loadFileList)
            .navigationTitle("Log Files")
            
            // File Preview Sheet
            .sheet(item: $selectedFileContent) { content in
                VStack {
                    HStack {
                        Spacer()
                        Button("Close") {
                            selectedFileContent = nil
                        }
                        .padding()
                    }
                    ScrollView {
                        HStack {
                            Text(content.text)
                                .padding()
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                }
            }
            
            // Repeated Refresh
            .onReceive(timer) { _ in
                loadFileList()
            }
            
            // Delete Alert
            .alert("Delete Confirmation", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let metadata = pendingDeleteFile {
                        deleteFile(metadata)
                    }
                }
            } message: {
                Text("This log file may not have been uploaded yet. Are you sure you want to delete it?")
            }
        }
    }
    
    /// Load log files
    private func loadFileList() {
        logFiles = HFileManager.shared.listLocationLogMetadata(withSuffix: logSuffix)
    }
    
    /// Load and preview .txt (or fallback to .pb) log
    private func previewLog(_ fileName: String) {
        Task {
            do {
                let text = try await HFileManager.shared.loadLogTextWithFallback(for: fileName)
                selectedFileContent = HFileManager.FileContent(text: text)
            } catch {
                selectedFileContent = HFileManager.FileContent(text: "Failed to preview log.")
                print("Preview error: \(error)")
            }
        }
    }
    
    /// Determine if the log is safe to delete
    private func handleDelete(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let metadata = logFiles.sorted { $0.timestamp > $1.timestamp }[index]
        
        let fileDateString = String(metadata.fileName.prefix(10))
        if let logDate = fileDateFormatter.date(from: fileDateString),
           let synced = appState.lastSyncedDate,
           logDate > synced {
            pendingDeleteFile = metadata
            showDeleteConfirmation = true
        } else {
            deleteFile(metadata)
        }
    }
    
    /// Delete both .pb and .txt logs
    private func deleteFile(_ metadata: HFileManager.FileMetadata) {
        do {
            try HFileManager.shared.deleteFile(named: metadata.fileName)
            let txtFile = metadata.fileName.replacingOccurrences(of: ".pb", with: ".txt")
            try HFileManager.shared.deleteFile(named: txtFile)
            
            logFiles.removeAll { $0.fileName == metadata.fileName }
        } catch {
            print("Failed to delete file: \(error)")
        }
    }
}
