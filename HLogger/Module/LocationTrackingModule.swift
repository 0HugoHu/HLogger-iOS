//
//  LocationModule.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import CoreLocation
import CoreMotion
import UIKit

class LocationModule: NSObject, CLLocationManagerDelegate {
    private let motionActivityManager = CMMotionActivityManager()
    private let locationManager = CLLocationManager()
    private var lastLoggedLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = LOCATION_MANAGER_DISTANCE_FILTER
    }
    
    func startTracking() {
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if shouldLogLocation(location) {
            processLocation(location)
            lastLoggedLocation = location
        }
    }
    
    private func shouldLogLocation(_ location: CLLocation) -> Bool {
        guard let last = lastLoggedLocation else { return true }
        let distance = location.distance(from: last)
        let timeInterval = location.timestamp.timeIntervalSince(last.timestamp)
        return (distance > LOCATION_MANAGER_LOG_CONDITION_DISTANCE || timeInterval > LOCATION_MANAGER_LOG_CONDITION_TIME_INTERVAL_SEC)
    }
    
    private func processLocation(_ location: CLLocation) {
        determineStatus(location) { status in
            var entry = Locationlogging_LocationEntry()
            entry.timestamp = HDateTime.shared.string(from: Date())
            entry.latitude = location.coordinate.latitude
            entry.longitude = location.coordinate.longitude
            entry.speed = location.speed
            entry.altitude = location.altitude
            entry.horizontalAccuracy = location.horizontalAccuracy
            entry.verticalAccuracy = location.verticalAccuracy
            entry.status = status.rawValue
            entry.deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
            
            HProtoBuf.shared.logEntry(entry, suffix: "location", filenamePrefix: 10)
        }
    }
    
    private func determineStatus(_ location: CLLocation, completion: @escaping (ActivityStatus) -> Void) {
        guard CMMotionActivityManager.isActivityAvailable() else {
            completion(location.speed > LOCATION_MANAGER_ACTIVITY_STATIONARY_THRESHOLD ? .unknown : .stationary)
            return
        }
        
        motionActivityManager.queryActivityStarting(from: Date().addingTimeInterval(LOCATION_MANAGER_LOG_CONDITION_TIME_OFFSET_SEC), to: Date(), to: .main) { activities, _ in
            if let activity = activities?.last, activity.confidence.rawValue >= LOCATION_MANAGER_ACTIVITY_CONFIDENCE_THRESHOLD.rawValue {
                if activity.automotive { completion(.driving) }
                else if activity.cycling { completion(.cycling) }
                else if activity.running { completion(.running) }
                else if activity.walking { completion(.walking) }
                else if activity.stationary { completion(.stationary) }
                else if activity.unknown { completion(.unknown) }
                else { completion(.other) }
            } else {
                completion(location.speed > LOCATION_MANAGER_ACTIVITY_STATIONARY_THRESHOLD ? .unknown : .stationary)
            }
        }
    }
}

