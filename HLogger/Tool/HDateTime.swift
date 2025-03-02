//
//  HDateTime.swift
//  HLogger
//
//  Created by Hugooooo on 3/1/25.
//

import Foundation

class HDateTime {
    static let shared = HDateTime()
    private let isoFormatter: ISO8601DateFormatter
    
    private init() {
        isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
    }
    
    func string(from date: Date) -> String {
        isoFormatter.timeZone = TimeZone.current
        return isoFormatter.string(from: date)
    }
    
    func date(from string: String) -> Date? {
        isoFormatter.timeZone = TimeZone.current
        return isoFormatter.date(from: string)
    }
}
