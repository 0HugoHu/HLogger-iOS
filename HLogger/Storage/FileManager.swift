//
//  FileManager.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import Foundation

extension FileManager {
    func saveEncryptedData(_ data: Data) {
        var fileURL = getPublicDirectory().appendingPathComponent("location_logs.enc")
        do {
            try data.write(to: fileURL, options: .atomic)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false
            try? fileURL.setResourceValues(resourceValues)
            print("Encrypted log saved at: \(fileURL.path)")
        } catch {
            print("Failed to save encrypted data: \(error)")
        }
    }
    
    func savePlainTextData(_ data: Data) {
        var fileURL = getPublicDirectory().appendingPathComponent("location_logs.txt")
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        } catch {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("Failed to save plaintext data: \(error)")
            }
        }
        
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = false
        try? fileURL.setResourceValues(resourceValues)
        print("Plaintext log appended at: \(fileURL.path)")
    }
    
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func getPublicDirectory() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory
    }
}
