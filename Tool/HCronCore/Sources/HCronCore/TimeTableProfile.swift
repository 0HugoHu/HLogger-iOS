//
//  TimeTableProfile.swift
//  HCronCore
//
//  Created by Hugooooo on 3/24/25.
//

import Foundation

public struct TimeTableEntry {
    public let hour: Int
    public let minute: Int
    
    public func matches(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.hour, from: date) == hour &&
        calendar.component(.minute, from: date) == minute
    }
}

public class TimeTableProfile {
    public init() {}
    public var entries: [TimeTableEntry] = []
    
    public func add(hour: Int, minute: Int) {
        entries.append(TimeTableEntry(hour: hour, minute: minute))
    }
    
    public func isNowScheduled(for date: Date = Date()) -> Bool {
        return entries.contains { $0.matches(date) }
    }
}
