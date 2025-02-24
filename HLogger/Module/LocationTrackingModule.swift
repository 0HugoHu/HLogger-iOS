//
//  LocationModule.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import CoreLocation
import UIKit

class LocationModule: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var lastLoggedLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5  // Only log if moved 5m
    }
    
    func startTracking() {
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        if shouldLogLocation(location) {
            logLocation(location)
            lastLoggedLocation = location
            print(location)
        }
    }
    
    private func shouldLogLocation(_ location: CLLocation) -> Bool {
        guard let last = lastLoggedLocation else { return true }
        let distance = location.distance(from: last)
        let timeInterval = location.timestamp.timeIntervalSince(last.timestamp)
        
        return (distance > 10 || timeInterval > 300)  // Log if moved >10m or after 5 mins
    }
    
    private func logLocation(_ location: CLLocation) {
        var entry = Locationlogging_LocationEntry()
        entry.timestamp = ISO8601DateFormatter().string(from: Date())
        entry.latitude = location.coordinate.latitude
        entry.longitude = location.coordinate.longitude
        entry.speed = location.speed
        entry.altitude = location.altitude
        entry.horizontalAccuracy = location.horizontalAccuracy
        entry.verticalAccuracy = location.verticalAccuracy
        entry.status = determineStatus(location)
        entry.deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        
        saveEntry(entry)
    }
    
    private func determineStatus(_ location: CLLocation) -> String {
        return location.speed > 1.5 ? "Moving" : "Stationary"
    }
    
    private func saveEntry(_ entry: Locationlogging_LocationEntry) {
        //        do {
        //            let binaryData = try entry.serializedData()
        //            if let encryptedData = StorageManager.encryptAndCompress(binaryData) {
        //                FileManager.default.saveEncryptedData(encryptedData)
        //            }
        //        } catch {
        //            print("Error saving entry: \(error)")
        //        }
        do {
            let jsonString = try entry.jsonString()
            if let jsonData = jsonString.data(using: .utf8) {
                StorageManager.saveData(jsonData)
            }
        } catch {
            print("Error saving entry: \(error)")
        }
    }
}
