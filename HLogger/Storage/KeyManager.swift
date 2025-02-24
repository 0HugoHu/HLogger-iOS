//
//  KeyManager.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import CryptoKit
import Foundation

class KeyManager {
    private static let keyIdentifier = "site.hugohu.hlogger"
    
    static func getKey() -> SymmetricKey {
        if let storedKey = loadKey() {
            return storedKey
        } else {
            let newKey = SymmetricKey(size: .bits256)
            saveKey(newKey)
            return newKey
        }
    }
    
    private static func saveKey(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyIdentifier,
            kSecValueData as String: keyData
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private static func loadKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        if let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        }
        return nil
    }
}
