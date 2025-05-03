//
//  AppState.swift
//  HLogger
//
//  Created by Hugooooo on 5/2/25.
//

import Foundation

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var lastSyncedDate: Date? = nil

    private init() {}
}
