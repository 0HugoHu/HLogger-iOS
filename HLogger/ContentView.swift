//
//  ContentView.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LocationLoggerView()
                .tabItem {
                    Label("Logger", systemImage: "location.fill")
                }
                .tag(0)
            
            FileListView()
                .tabItem {
                    Label("Logs", systemImage: "doc.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
    }
}

struct LocationLoggerView: View {
    @StateObject private var appController = AppController()
    
    var body: some View {
        VStack {
            Text("Location Logger Running")
                .font(.title)
                .padding()
            
            Button("Start Tracking") {
                appController.startApp()
            }
            .padding()
        }
        .onAppear {
            appController.startApp()
        }
    }
}

struct FileListView: View {
    @State private var logFiles: [String] = []
    @State private var selectedFileContent: FileContent?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(logFiles, id: \ .self) { file in
                    HStack {
                        Text(file)
                        Spacer()
                        Button("View") {
                            previewLog(file)
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
            .onAppear(perform: loadLogFiles)
            .navigationTitle("Log Files")
            .sheet(item: $selectedFileContent) { content in
                ScrollView {
                    Text(content.text)
                        .padding()
                }
            }
        }
    }
    
    private func loadLogFiles() {
        logFiles = HFileManager.shared.listFiles(withSuffix: "location.pb")
    }
    
    private func previewLog(_ fileName: String) {
        let fileURL = HFileManager.shared.getFileURL(for: fileName)
        do {
            let log = try HFileManager.shared.loadLog(from: fileURL)
            
            let formattedText = log?.entries.map { entry in
                """
                Timestamp: \(entry.timestamp)
                Latitude: \(entry.latitude)
                Longitude: \(entry.longitude)
                Speed: \(entry.speed) m/s
                Altitude: \(entry.altitude) m
                Status: \(entry.status)
                """
            }.joined(separator: "\n\n")
            
            selectedFileContent = FileContent(text: formattedText ?? "Empty File")
            
        } catch {
            print("Failed to preview log: \(error)")
        }
    }
    
}


struct FileContent: Identifiable {
    let id = UUID()
    let text: String
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .font(.title)
            .padding()
    }
}
