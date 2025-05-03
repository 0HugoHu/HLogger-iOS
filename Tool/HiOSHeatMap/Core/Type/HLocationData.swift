//
//  s.swift
//  HLogger
//
//  Created by Hugooooo on 3/6/25.
//

import MapKit

struct HLocationData: CoordinateProtocol {
    var timestamp: String?
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var horizontalAccuracy: Double?
    var verticalAccuracy: Double?
    
    init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(timestamp: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees, horizontalAccuracy: Double, verticalAccuracy: Double) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
    }
}


protocol CoordinateProtocol {
    var latitude: CLLocationDegrees { get set }
    var longitude: CLLocationDegrees { get set }
    
    init(latitude: CLLocationDegrees, longitude: CLLocationDegrees)
}

/// Extend `CLLocationCoordinate2D` to conform to `CoordinateProtocol`
extension CLLocationCoordinate2D: CoordinateProtocol { }
