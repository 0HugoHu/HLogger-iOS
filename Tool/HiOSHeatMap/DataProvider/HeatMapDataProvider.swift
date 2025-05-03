//
//  HeatMapDataProvider.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/6/25.
//

import UIKit
import MapKit

/// Provides data points for heatmaps
class HeatMapDataProvider {
    private var dataPointCoords: [HLocationData]
    
    /// Initializes the data provider with a custom set of data points
    init(dataPoints: [HLocationData]) {
        self.dataPointCoords = dataPoints
    }
    
    func getDataPoints() -> [HLocationData] {
        return dataPointCoords
    }
}

extension HeatMapContainerViewController: MKMapViewDelegate {
    /// Provides the appropriate renderer for a given map overlay
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return heatMap?.heatmapView(mapView, rendererFor: overlay) ?? MKOverlayRenderer()
    }
    
    /// Called when the map starts rendering overlays
    func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
        heatMap?.heatmapViewWillStartRenderingMap(mapView)
    }
}

extension HeatMapContainerViewController: HeatMapDelegate {
    /// Returns the number of heat points
    func heatmap(heatPointCount heatmap: HeatMapView) -> Int {
        return dataProvider.getDataPoints().count
    }
    
    /// Returns the heat level for a given index
    func heatmap(heatLevelFor index: Int) -> Int {
        return 1 + index
    }
    
    /// Returns the radius in kilometers for a given index
    func heatmap(radiusInKMFor index: Int) -> Double {
        let horizontalAccuracy = dataProvider.getDataPoints()[index].horizontalAccuracy ?? HIOSHEATMAP_DEFAULT_ACCURACY_IN_KILOMETER
        let verticalAccuracy = dataProvider.getDataPoints()[index].verticalAccuracy ?? HIOSHEATMAP_DEFAULT_ACCURACY_IN_KILOMETER
        let averageAccuracy = 2 * horizontalAccuracy * verticalAccuracy / (horizontalAccuracy + verticalAccuracy) / 10
        return averageAccuracy
    }
    
    /// Returns the coordinate for a given index
    func heatmap(coordinateFor index: Int) -> CLLocationCoordinate2D {
        let locationData = dataProvider.getDataPoints()[index]
        return CLLocationCoordinate2D(latitude: locationData.latitude, longitude: locationData.longitude)
    }
}
