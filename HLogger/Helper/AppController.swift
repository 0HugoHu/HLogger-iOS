//
//  AppController.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import Foundation

class AppController : ObservableObject {
    private let locationModule = LocationTrackingModule()
    
    func startLocationModule() {
        locationModule.startTracking()
    }
    
    func stopLocationModule() {
        locationModule.stopTracking()
    }
    
    func checkLocationModuleStatus() -> Bool {
        return locationModule.checkLocationModuleStatus()
    }
}
