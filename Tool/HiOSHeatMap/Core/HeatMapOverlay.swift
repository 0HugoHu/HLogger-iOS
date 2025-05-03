//
//  HeatMapOverlay.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/5/25.
//

import UIKit
import MapKit

/// Base class for heatmap overlays
class HeatMapOverlay: NSObject, MKOverlay {
    /// Collection of heat points contained in the overlay
    var heatPoints: [HPoint] = []
    private(set) var calculatedMapRect: MKMapRect?
    
    /// The center coordinate of the overlay
    var coordinate: CLLocationCoordinate2D {
        MKMapPoint(x: boundingMapRect.midX, y: boundingMapRect.midY).coordinate
    }
    
    /// The bounding map rectangle of the overlay
    var boundingMapRect: MKMapRect {
        guard let rect = calculatedMapRect else {
            fatalError("boundingMapRect has not been calculated yet")
        }
        return rect
    }
    
    /// Initializes an overlay with an initial heat point
    /// - Parameter initialHeatPoint: The initial heat point to be added
    init(initialHeatPoint: HPoint) {
        super.init()
        calculateMapRect(for: initialHeatPoint)
        heatPoints.append(initialHeatPoint)
    }
    
    /// Override in subclasses to define how the bounding map rect is calculated
    /// - Parameter newPoint: The new heat point to consider
    func calculateMapRect(for newPoint: HPoint) {
        fatalError("Subclasses must implement calculateMapRect")
    }
    
    /// Adds a new heat point and updates the bounding rectangle
    /// - Parameter point: The heat point to be added
    func insertHeatPoint(_ point: HPoint) {
        calculateMapRect(for: point)
        heatPoints.append(point)
    }
    
    /// Updates the bounding map rectangle to include the new point
    /// - Parameter newPoint: The new heat point to consider
    func updateBoundingMapRect(using newPoint: HPoint) {
        let heatmapRect = newPoint.mapRect
        
        if let existingRect = calculatedMapRect {
            calculatedMapRect = existingRect.union(heatmapRect)
        } else {
            calculatedMapRect = heatmapRect
        }
    }
}

/// Overlay for radius-based heatmap points
class HeatRadiusPointOverlay: HeatMapOverlay {
    override func calculateMapRect(for newPoint: HPoint) {
        updateBoundingMapRect(using: newPoint)
    }
}

/// Overlay for flat-point heatmaps
class HeatFlatPointOverlay: HeatMapOverlay {
    override func calculateMapRect(for newPoint: HPoint) {
        updateBoundingMapRect(using: newPoint)
    }
}
