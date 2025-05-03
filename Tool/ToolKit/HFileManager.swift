//
//  HFileManager.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import Foundation

struct LogMetadata: Codable {
    let fileName: String
    let timestamp: String
    let entryCount: Int
    let fileSize: Int64
}

class HFileManager {
    static let shared = HFileManager()
    public let fileManager = FileManager.default
    
    private init() {}
    
    /// Get the app's document directory
    func getDocumentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Get the file URL using a dynamic suffix and prefix length
    func getFileURL(for suffix: String, filenamePrefixLength: Int) -> URL {
        getDocumentsDirectory().appendingPathComponent("\(HDateTime.shared.utcString(from: Date()).prefix(filenamePrefixLength))_\(suffix).pb")
    }
    
    /// Get the file URL for a specific filename
    func getFileURL(for fileName: String) -> URL {
        getDocumentsDirectory().appendingPathComponent(fileName)
    }
    
    /// Save data to a file
    func saveLogData(_ data: Data, to fileURL: URL) throws {
        try data.write(to: fileURL, options: .atomic)
    }
    
    /// Delete a file by name
    func deleteFile(named fileName: String) throws {
        try fileManager.removeItem(at: getFileURL(for: fileName))
    }
    
    /// List files in the document directory with a specific suffix
    func listFiles(withSuffix suffix: String) -> [String] {
        (try? fileManager.contentsOfDirectory(atPath: getDocumentsDirectory().path)
            .filter { $0.hasSuffix(suffix) }) ?? []
    }
}
