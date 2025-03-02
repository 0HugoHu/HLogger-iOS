//
//  HFileManager.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import Foundation

class HFileManager {
    static let shared = HFileManager()
    private let fileManager = FileManager.default
    
    private init() {}
    
    func getDocumentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func getFileURL(for suffix: String, filenamePrefix: Int) -> URL {
        getDocumentsDirectory().appendingPathComponent("\(HDateTime.shared.string(from: Date()).prefix(filenamePrefix))_\(suffix).pb")
    }
    
    func getFileURL(for fileName: String) -> URL {
        getDocumentsDirectory().appendingPathComponent(fileName)
    }
    
    func saveLogData(_ data: Data, to fileURL: URL) throws {
        try data.write(to: fileURL, options: .atomic)
    }
    
    func loadLog(from fileURL: URL) throws -> Locationlogging_LocationLog? {
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try Locationlogging_LocationLog(serializedBytes: data)
    }
    
    func deleteFile(named fileName: String) throws {
        try fileManager.removeItem(at: getDocumentsDirectory().appendingPathComponent(fileName))
    }
    
    func listFiles(withSuffix suffix: String) -> [String] {
        (try? fileManager.contentsOfDirectory(atPath: getDocumentsDirectory().path)
            .filter { $0.hasSuffix(suffix) }) ?? []
    }
}
