//
//  HeatMapView.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/5/25.
//

import Foundation
import MapKit

/// A custom `MKMapView` subclass for rendering heatmaps
public class HeatMapView: MKMapView {
    var heatmapDelegate: HeatMapDelegate?
    var mapProcessor: HeatMapProcessor!
    var indicator: UIActivityIndicatorView?
    
    /// Controls the visibility of the activity indicator
    public var showIndicator: Bool = true {
        didSet { if !showIndicator { indicator?.stopAnimating() } }
    }
    
    /// Initializes a new heatmap view
    /// - Parameters:
    ///   - frame: The frame size of the heatmap
    ///   - delegate: The delegate responsible for heat data
    ///   - mapType: The type of heatmap (flat or radius-based)
    ///   - basicColors: The gradient colors used in the heatmap
    ///   - divideLevel: The number of gradient divisions
    public init(frame: CGRect, delegate: HeatMapDelegate, mapType: HMapType, basicColors: [UIColor] = [.blue, .green, .red], divideLevel: Int = 2) {
        super.init(frame: frame)
        self.showsScale = true
        self.delegate = self
        self.heatmapDelegate = delegate
        
        HeatMapDataProcessor.colorMixer = HeatMapColorMixer(colors: basicColors, levels: divideLevel)
        configureMapProcessor(mapType: mapType)
        
        refresh()
        setupIndicator()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Refreshes the heatmap by reloading data
    public func refresh() {
        if showIndicator { indicator?.startAnimating() }
        mapProcessor.refreshMap()
    }
    
    /// Changes the heatmap type and refreshes the view
    /// - Parameter mapType: The new heatmap type
    public func setType(mapType: HMapType) {
        configureMapProcessor(mapType: mapType)
        refresh()
    }
    
    /// Configures the map processor based on the selected heatmap type
    /// - Parameter mapType: The selected heatmap type
    private func configureMapProcessor(mapType: HMapType) {
        let dataType: HDataPointType = (mapType == .flatDistinct) ? .flatPoint : .radiusPoint
        let mode: ColorMixerMode = (mapType == .radiusBlurry) ? .blurry : .distinct
        mapProcessor = HeatMapProcessor(map: self, dataType: dataType, mode: mode)
    }
    
    /// Sets up the activity indicator for loading states
    private func setupIndicator() {
        indicator = UIActivityIndicatorView(style: .large)
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicator!)
        
        NSLayoutConstraint.activate([
            indicator!.widthAnchor.constraint(equalToConstant: 60),
            indicator!.heightAnchor.constraint(equalToConstant: 60),
            indicator!.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator!.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

extension HeatMapView: MKMapViewDelegate {
    /// Provides the appropriate renderer for a given heatmap overlay
    public func heatmapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer? {
        switch overlay {
        case let flatOverlay as HeatFlatPointOverlay:
            return FlatPointOverlayRender(overlay: flatOverlay)
        case let radiusOverlay as HeatRadiusPointOverlay:
            return RadiusPointOverlayRender(overlay: radiusOverlay)
        default:
            return MKOverlayRenderer()
        }
    }
    
    /// Called when the map starts rendering
    public func heatmapViewWillStartRenderingMap(_ mapView: MKMapView) {
        mapProcessor.calculateStart()
    }
    
    /// Provides the renderer for an overlay
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        return heatmapView(mapView, rendererFor: overlay) ?? MKOverlayRenderer()
    }
    
    /// Called when the map starts rendering
    public func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
        heatmapViewWillStartRenderingMap(mapView)
    }
}

/// Protocol defining heatmap data requirements
public protocol HeatMapDelegate {
    func heatmap(heatPointCount heatmap: HeatMapView) -> Int
    func heatmap(heatLevelFor index: Int) -> Int
    func heatmap(radiusInKMFor index: Int) -> Double
    func heatmap(coordinateFor index: Int) -> CLLocationCoordinate2D
}

/// Default implementation for heat radius
extension HeatMapDelegate {
    func heatmap(radiusInKMFor index: Int) -> Double { return HIOSHEATMAP_DEFAULT_ACCURACY_IN_KILOMETER }
}
