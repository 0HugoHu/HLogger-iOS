//
//  ContentView.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var statusBarHeight: CGFloat = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SystemStatusView()
                .tabItem {
                    Label("System Status", systemImage: "gearshape.fill")
                }
                .tag(0)
            
            HiOSHeatMap()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(1)
                .padding(.top, -statusBarHeight)
            
            LogBrowserView()
                .tabItem {
                    Label("Logs", systemImage: "doc.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(3)
        }
        .onAppear {
            getStatusBarHeight()
        }
    }
    
    /// Get the status bar height dynamically
    private func getStatusBarHeight() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let statusBarManager = windowScene.statusBarManager {
            statusBarHeight = statusBarManager.statusBarFrame.height
        }
    }
}
