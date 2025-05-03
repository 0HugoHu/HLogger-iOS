//
//  TaskScheduler.swift
//  HCronCore
//
//  Created by Hugooooo on 3/24/25.
//

import Foundation

public class TaskScheduler: @unchecked Sendable {
    public static let shared = TaskScheduler()
    private var tasks: [ScheduledTask] = []
    private var isRunning = false
    private let queue = DispatchQueue(label: "task_scheduler_queue")
    
    private init() {}
    
    public func register(task: ScheduledTask) {
        tasks.append(task)
        tasks.sort { $0.priority < $1.priority }
    }
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        queue.async {
            while self.isRunning {
                let now = Date()
                self.runDueTasks(at: now)
                
                // Sleep until the next full minute
                let nextTick = Calendar.current.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime)!
                let sleepTime = nextTick.timeIntervalSinceNow
                Thread.sleep(forTimeInterval: sleepTime)
            }
        }
    }
    
    private func runDueTasks(at now: Date) {
        for i in tasks.indices {
            if tasks[i].shouldRun(at: now) {
                if (tasks[i].runOnMainThread) {
                    DispatchQueue.main.async {
                        self.tasks[i].execute()
                    }
                } else {
                    self.tasks[i].execute()
                }
            }
        }
    }
    
    public func stop() {
        isRunning = false
    }
}
