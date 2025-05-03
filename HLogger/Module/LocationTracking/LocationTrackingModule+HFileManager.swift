//
//  LocationTrackingModule+HFileManager.swift
//  HLogger
//
//  Created by Hugooooo on 3/24/25.
//

import Foundation

extension HFileManager {
    
    /// Logs a single location entry to both protobuf (.pb) and plain text (.txt) files.
    /// - Parameters:
    ///   - entry: The `Locationlogging_LocationEntry` to log.
    ///   - suffix: Suffix to use in the filename.
    ///   - filenamePrefix: Length of date-based prefix in the filename.
    func logLocationEntry(_ entry: Locationlogging_LocationEntry, suffix: String, filenamePrefix: Int) {
        let fileURL = getFileURL(for: suffix, filenamePrefixLength: filenamePrefix)
        
        do {
            // Load or initialize protobuf log, append new entry, and save
            var log = try loadLocationLog(from: fileURL) ?? Locationlogging_LocationLog()
            log.entries.append(entry)
            let binaryData = try log.serializedData()
            try saveLogData(binaryData, to: fileURL)
            print("Saved location entry to: \(fileURL)")
            
            // Also append formatted plain text to the .txt log
            let textURL = fileURL.deletingPathExtension().appendingPathExtension("txt")
            let text = formatTextLogEntry(entry)
            try appendText(text, to: textURL)
            
        } catch {
            print("Failed to log location: \(error)")
        }
    }
    
    /// Formats a location entry for human-readable .txt logging.
    private func formatTextLogEntry(_ entry: Locationlogging_LocationEntry) -> String {
        let inputFormatter = ISO8601DateFormatter()
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM-dd HH:mm:ss"
        
        let date = inputFormatter.date(from: entry.timestamp) ?? Date()
        let formattedDate = outputFormatter.string(from: date)
        
        return """
        Time: \(formattedDate)
        Speed: \(String(format: "%.2f", entry.speed)) m/s
        Longtitude: \(entry.longitude)
        Latitude: \(entry.latitude)
        Status: \(entry.status)
        
        """
    }
    
    /// Appends a string to a file, or creates the file if it doesn’t exist.
    private func appendText(_ text: String, to fileURL: URL) throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let handle = try FileHandle(forWritingTo: fileURL)
            try handle.seekToEnd()
            if let data = text.data(using: .utf8) {
                handle.write(data)
            }
            try handle.write(contentsOf: "\n".data(using: .utf8)!)
            try handle.close()
        } else {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    /// Attempts to load a log's `.txt` preview. If unavailable, falls back to decoding `.pb`.
    /// - Returns: A formatted display string for preview.
    func loadLogTextWithFallback(for fileName: String) async throws -> String {
        do {
            return try loadTextLog(for: fileName)
        } catch {
            print("Failed to load .txt log for \(fileName): \(error), falling back to .pb")
            let pbURL = getFileURL(for: fileName)
            let log = try await loadLocationLogAsync(from: pbURL)
            return formatLogEntriesForDisplay(log)
        }
    }
    
    /// Loads and parses a binary protobuf location log.
    func loadLocationLog(from fileURL: URL) throws -> Locationlogging_LocationLog? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try Locationlogging_LocationLog(serializedBytes: data)
    }
    
    /// Loads the plain text log content for a given `.pb` filename.
    func loadTextLog(for originalFileName: String) throws -> String {
        let textFileName = originalFileName.replacingOccurrences(of: ".pb", with: ".txt")
        let textURL = getFileURL(for: textFileName)
        return try String(contentsOf: textURL, encoding: .utf8)
    }
    
    /// Formats a full `LocationLog` into a previewable plain text block.
    func formatLogEntriesForDisplay(_ log: Locationlogging_LocationLog) -> String {
        let inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        inputDateFormatter.locale = Locale.current
        inputDateFormatter.timeZone = TimeZone.current
        
        let outputDateFormatter = DateFormatter()
        outputDateFormatter.dateFormat = "MM-dd HH:mm:ss"
        
        return log.entries
            .sorted {
                inputDateFormatter.date(from: $0.timestamp) ?? Date() >
                inputDateFormatter.date(from: $1.timestamp) ?? Date()
            }
            .map { entry in
                let date = inputDateFormatter.date(from: entry.timestamp) ?? Date()
                return """
                Time: \(outputDateFormatter.string(from: date))
                Speed: \(String(format: "%.2f", entry.speed)) m/s
                Longtitude: \(entry.longitude)
                Latitude: \(entry.latitude)
                Status: \(entry.status)
                """
            }
            .joined(separator: "\n\n")
    }
    
    /// Loads a location log from disk asynchronously (non-blocking).
    func loadLocationLogAsync(from fileURL: URL) async throws -> Locationlogging_LocationLog {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let log = try self.loadLocationLog(from: fileURL)
                    continuation.resume(returning: log ?? Locationlogging_LocationLog())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Collect file metadata in real time
    func listLocationLogMetadata(withSuffix suffix: String) -> [FileMetadata] {
        let files = listFiles(withSuffix: suffix)
        
        return files.compactMap { file in
            let fileURL = getFileURL(for: file)
            let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
            let fileSize = attributes?[.size] as? Int64 ?? 0
            
            guard let log = try? loadLocationLog(from: fileURL) else {
                return FileMetadata(fileName: file, fileSize: fileSize, entryCount: 0, timestamp: "Unknown")
            }
            
            let entryCount = log.entries.count
            let timestamp = log.entries.first?.timestamp ?? "Unknown"
            
            return FileMetadata(fileName: file, fileSize: fileSize, entryCount: entryCount, timestamp: timestamp)
        }
    }
    
    /// File metadata for listview
    struct FileMetadata: Identifiable {
        let id = UUID()
        let fileName: String
        let fileSize: Int64
        let entryCount: Int
        let timestamp: String
    }
    
    /// Wrapper for displayed log file content
    struct FileContent: Identifiable {
        let id = UUID()
        let text: String
    }
}
