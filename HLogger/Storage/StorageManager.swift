//
//  StorageManager.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import Foundation
import Compression
import CryptoKit

class StorageManager {
    static var encryptionEnabled: Bool = false
    
    static func saveData(_ data: Data) {
        if encryptionEnabled {
            if let encryptedData = encryptAndCompress(data) {
                FileManager.default.saveEncryptedData(encryptedData)
            }
        } else {
            FileManager.default.savePlainTextData(data)
        }
    }
    
    static func encryptAndCompress(_ data: Data) -> Data? {
        do {
            let key = KeyManager.getKey()
            let sealedBox = try AES.GCM.seal(data, using: key)
            return compressedData(data: sealedBox.combined ?? data)
        } catch {
            return nil
        }
    }

    static func decompressAndDecrypt(_ data: Data) -> Data? {
        guard let decompressedData = decompressedData(data: data) else { return nil }
        do {
            let key = KeyManager.getKey()
            let sealedBox = try AES.GCM.SealedBox(combined: decompressedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            return nil
        }
    }
    
    static func compressedData(data: Data) -> Data? {
        var compressedData = Data()
        data.withUnsafeBytes { buffer in
            compressedData.append(buffer.bindMemory(to: UInt8.self))
        }
        return compressedData
    }
    
    static func decompressedData(data: Data) -> Data? {
        return data
    }
}
