//
//  LocationTrackingModule.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import CoreLocation
import CoreMotion
import UIKit

class LocationTrackingModule: NSObject, CLLocationManagerDelegate {
    /// High-accuracy location manager for continuous updates
    private let preciseLocationManager = CLLocationManager()
    
    /// Fallback location manager for significant location changes
    private let fallbackLocationManager = CLLocationManager()
    
    /// Motion activity manager to determine walking/driving/etc.
    private let motionActivityManager = CMMotionActivityManager()
    
    /// Last recorded location and status
    private var lastLoggedLocation: CLLocation?
    
    /// Avoid race conditions when two location managers both invoke callback method
    private let locationUpdateLock = NSLock()
    
    override init() {
        super.init()
        
        /// Shared setup for both managers
        [preciseLocationManager, fallbackLocationManager].forEach {
            $0.delegate = self
            $0.allowsBackgroundLocationUpdates = true
            $0.pausesLocationUpdatesAutomatically = false
            $0.requestAlwaysAuthorization()
        }
        
        /// Configure precise location manager
        preciseLocationManager.desiredAccuracy = LOCATION_MANAGER_LOG_CONDITION_ACCURACY_HUNDREDTHS
        preciseLocationManager.distanceFilter = LOCATION_MANAGER_DISTANCE_FILTER
    }
    
    /// Start both tracking modes
    func startTracking() {
        preciseLocationManager.startUpdatingLocation()
        fallbackLocationManager.startMonitoringSignificantLocationChanges()
    }
    
    /// Stop both tracking modes
    func stopTracking() {
        preciseLocationManager.stopUpdatingLocation()
        fallbackLocationManager.stopMonitoringSignificantLocationChanges()
    }
    
    //// Check tracking services status
    func checkLocationModuleStatus() -> Bool {
        // This method is safe in the latest iOS version
        guard CLLocationManager.locationServicesEnabled() else {
            return false
        }
        
        let authStatus = preciseLocationManager.authorizationStatus
        let isAuthorized: Bool = (authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse)
        
        let isConfigured = preciseLocationManager.delegate != nil &&
        preciseLocationManager.allowsBackgroundLocationUpdates
        
        return isAuthorized && isConfigured
    }
    
    /// Called when either location manager receives updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Prevent concurrent access
        guard locationUpdateLock.try() else {
            print("Location update skipped due to in-progress lock")
            return
        }
        
        // Proceed with normal location filtering
        let bestLocation = locations
            .filter { $0.horizontalAccuracy >= 0 }
            .min(by: { $0.horizontalAccuracy < $1.horizontalAccuracy })
        
        guard let location = bestLocation else { return }
        guard shouldLog(location) else { return }
        
        determineStatus(for: location) { status in
            self.log(location, status: status)
            do {
                self.locationUpdateLock.unlock()
            }
        }
    }
    
    /// Filter to avoid logging too frequently
    private func shouldLog(_ location: CLLocation) -> Bool {
        guard let last = lastLoggedLocation else { return true }
        
        let timeElapsed = location.timestamp.timeIntervalSince(last.timestamp)
        
        // Always log if enough time has passed (normal interval)
        if timeElapsed > LOCATION_MANAGER_LOG_CONDITION_TIME_INTERVAL_SEC {
            return true
        }
        
        return false
    }
    
    /// Classify motion type based on CoreMotion activity history
    private func determineStatus(for location: CLLocation, completion: @escaping (ActivityStatus) -> Void) {
        guard CMMotionActivityManager.isActivityAvailable() else {
            completion(location.speed > LOCATION_MANAGER_MOVING_THRESHOLD ? .other : .stationary)
            return
        }
        
        motionActivityManager.queryActivityStarting(
            from: Date().addingTimeInterval(-LOCATION_MANAGER_ACTIVITY_LOOK_BACK_SEC),
            to: Date(),
            to: .main
        ) { activities, _ in
            guard let activities = activities, !activities.isEmpty else {
                completion(location.speed > LOCATION_MANAGER_MOVING_THRESHOLD ? .other : .stationary)
                return
            }
            
            let mostConfident = activities
                .sorted {
                    ($0.confidence.rawValue, $0.startDate) >
                    ($1.confidence.rawValue, $1.startDate)
                }
                .first
            
            guard let activity = mostConfident else {
                completion(.unknown)
                return
            }
            
            switch true {
            case activity.automotive: completion(.driving)
            case activity.cycling: completion(.cycling)
            case activity.running: completion(.running)
            case activity.walking: completion(.walking)
            case activity.stationary: completion(.stationary)
            default: completion(.stationary)
            }
        }
    }
    
    /// Create and save log entry
    private func log(_ location: CLLocation, status: ActivityStatus) {
        var entry = Locationlogging_LocationEntry()
        entry.timestamp = HDateTime.shared.utcString(from: Date())
        entry.latitude = location.coordinate.latitude
        entry.longitude = location.coordinate.longitude
        entry.speed = location.speed
        entry.altitude = location.altitude
        entry.horizontalAccuracy = location.horizontalAccuracy
        entry.verticalAccuracy = location.verticalAccuracy
        entry.status = status.rawValue
        entry.deviceID = UIDevice.current.identifierForVendor?.uuidString ?? LOCATION_MANAGER_UNKNOWN
        
        /// Dynamically adjust distance filter based on activity
        switch status {
        case .driving:
            if location.speed > LOCATION_MANAGER_DRIVING_LOW_SPEED_THRESHOLD {
                preciseLocationManager.distanceFilter = LOCATION_MANAGER_DISTANCE_FILTER_DRIVING
            } else {
                preciseLocationManager.distanceFilter = LOCATION_MANAGER_DISTANCE_FILTER_WALKING
            }
        case .walking:
            preciseLocationManager.distanceFilter = LOCATION_MANAGER_DISTANCE_FILTER_CYCLING
        case .cycling:
            preciseLocationManager.distanceFilter = LOCATION_MANAGER_DISTANCE_FILTER_RUNNING
        case .running:
            preciseLocationManager.distanceFilter = LOCATION_MANAGER_DISTANCE_FILTER_WALKING
        default:
            preciseLocationManager.distanceFilter = LOCATION_MANAGER_DISTANCE_FILTER
        }
        
        do {
            _ = try entry.jsonString()
            print("Logging location: \(entry.latitude), \(entry.longitude), status: \(entry.status)")
            HFileManager.shared.logLocationEntry(entry, suffix: LOCATION_MANAGER_LOG_FILE_NAME_SUFFIX, filenamePrefix: 10)
            
            lastLoggedLocation = location
        } catch {
            print("Failed to encode log entry: \(error)")
        }
    }
}
