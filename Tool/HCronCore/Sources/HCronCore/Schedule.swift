//
//  Schedule.swift
//  HCronCore
//
//  Created by Hugooooo on 3/24/25.
//

import Foundation

public enum RepeatType {
    case once
    case daily
    case hourly
    case minutely(Int)
}

public struct Schedule {
    let startTime: Date
    let repeatType: RepeatType
    private var hasRunOnce: Bool = false
    
    public init(startTime: Date, repeatType: RepeatType, hasRunOnce: Bool) {
        self.startTime = startTime
        self.repeatType = repeatType
        self.hasRunOnce = hasRunOnce
    }
    
    public mutating func shouldRun(at date: Date) -> Bool {
        switch repeatType {
        case .once:
            if !hasRunOnce && Calendar.current.isDate(date, equalTo: startTime, toGranularity: .minute) {
                hasRunOnce = true
                return true
            }
        case .daily:
            let calendar = Calendar.current
            return calendar.component(.hour, from: date) == calendar.component(.hour, from: startTime)
            && calendar.component(.minute, from: date) == calendar.component(.minute, from: startTime)
        case .hourly:
            return Calendar.current.component(.minute, from: date) == Calendar.current.component(.minute, from: startTime)
        case .minutely(let interval):
            let startMinute = Calendar.current.component(.minute, from: startTime)
            let currentMinute = Calendar.current.component(.minute, from: date)
            return currentMinute % interval == startMinute % interval
        }
        return false
    }
}
