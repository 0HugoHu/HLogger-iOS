//
//  HLoggerApp.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import SwiftUI
import BackgroundTasks
import HCronCore

@main
struct HLoggerApp: App {
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
    
//        SilentAudioManager.shared.startBackgroundAudio()
//        
//        let task = LocationTrackingTask()
//        TaskScheduler.shared.register(task: task)
//        
//        TaskScheduler.shared.start()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
