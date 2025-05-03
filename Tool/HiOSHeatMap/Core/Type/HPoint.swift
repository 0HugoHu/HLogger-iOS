//
//  HPoint.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/6/25.
//

import Foundation
import MapKit

/// Represents a heat point in the heatmap
struct HPoint {
    var heatLevel: Int = 0
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var radiusInKilometer: Double = HIOSHEATMAP_DEFAULT_ACCURACY_IN_KILOMETER
    
    /// Computes the midpoint of the heat point in map coordinates
    var midMapPoint: MKMapPoint { MKMapPoint(coordinate) }
    
    /// Converts radius in kilometers to MKMap distance
    var radiusInMKDistance: Double {
        let meterPerMapPoint = MKMetersPerMapPointAtLatitude(coordinate.latitude)
        return radiusInKilometer / (meterPerMapPoint / 1000)
    }
    
    /// Computes the bounding map rectangle for the heat point
    var mapRect: MKMapRect {
        let origin = MKMapPoint(x: midMapPoint.x - radiusInMKDistance, y: midMapPoint.y - radiusInMKDistance)
        return MKMapRect(origin: origin, size: MKMapSize(width: 2 * radiusInMKDistance, height: 2 * radiusInMKDistance))
    }
    
    /// Default initializer
    init() {}
    
    /// Initializes a heat point with specific parameters
    /// - Parameters:
    ///   - heatLevel: The intensity of the heat point
    ///   - coordinate: The geographic coordinate of the heat point
    ///   - heatRadiusInKM: The radius of influence of the heat point in kilometers
    init(heatLevel: Int, coordinate: CLLocationCoordinate2D, heatRadiusInKM: Double) {
        self.radiusInKilometer = heatRadiusInKM
        self.heatLevel = heatLevel
        self.coordinate = coordinate
    }
    
    /// Calculates the Euclidean distance between two heat points
    /// - Parameter point: The target heat point
    /// - Returns: The computed distance
    func distance(to point: HPoint) -> Double {
        let latDiff = point.coordinate.latitude - coordinate.latitude
        let longDiff = point.coordinate.longitude - coordinate.longitude
        return sqrt(latDiff * latDiff + longDiff * longDiff)
    }
}
