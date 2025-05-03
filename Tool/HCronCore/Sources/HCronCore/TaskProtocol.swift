//
//  TaskProtocol.swift
//  HCronCore
//
//  Created by Hugooooo on 3/24/25.
//

import Foundation

public protocol ScheduledTask {
    var identifier: String { get }
    var priority: Int { get set }
    var schedule: Schedule { get set }
    var runOnMainThread: Bool { get set }
    
    mutating func shouldRun(at date: Date) -> Bool
    func execute()
}
