//
//  HProtoBuf.swift
//  HLogger
//
//  Created by Hugooooo on 3/1/25.
//

import Foundation
import CoreLocation
import SwiftProtobuf

class HProtoBuf {
    static let shared = HProtoBuf()
    private var lastEntries: [String: Message] = [:]
    
    private init() {}
    
    func logEntry(_ entry: Locationlogging_LocationEntry, suffix: String, filenamePrefix: Int) {
        let fileURL = HFileManager.shared.getFileURL(for: suffix, filenamePrefix: filenamePrefix)
        
        var optimizedEntry = entry
        if let lastEntry = lastEntries[suffix] as? Locationlogging_LocationEntry {
            optimizedEntry = optimizeEntry(current: &optimizedEntry, last: lastEntry)
        }
        lastEntries[suffix] = entry
        
        do {
            var log = try HFileManager.shared.loadLog(from: fileURL) ?? Locationlogging_LocationLog()
            log.entries.append(optimizedEntry)
            
            let binaryData = try log.serializedData()
            try HFileManager.shared.saveLogData(binaryData, to: fileURL)
        } catch {
            print("Failed to log entry: \(error)")
        }
    }
    
    private func optimizeEntry(current: inout Locationlogging_LocationEntry, last: Locationlogging_LocationEntry) -> Locationlogging_LocationEntry {
        if current.timestamp == last.timestamp { current.timestamp = "*" }
        if current.latitude == last.latitude { current.latitude = -1 }
        if current.longitude == last.longitude { current.longitude = -1 }
        if current.speed == last.speed { current.speed = -1 }
        if current.altitude == last.altitude { current.altitude = -1 }
        if current.horizontalAccuracy == last.horizontalAccuracy { current.horizontalAccuracy = -1 }
        if current.verticalAccuracy == last.verticalAccuracy { current.verticalAccuracy = -1 }
        if current.status == last.status { current.status = "*" }
        if current.deviceID == last.deviceID { current.deviceID = "*" }
        
        return current
    }
}
