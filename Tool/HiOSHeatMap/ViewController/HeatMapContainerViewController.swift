//
//  HeatMapContainerViewController.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/5/25.
//


import UIKit
import MapKit

/// View controller for displaying a heatmap on a map view
class HeatMapContainerViewController: UIViewController {
    public var mapView: MKMapView!
    public var heatMap: HeatMapView?
    public var dataProvider: HeatMapDataProvider
    public var selectedMapType: HMapType
    
    /// Initializes the heatmap view controller with a data provider and map type
    init(dataProvider: HeatMapDataProvider, mapType: HMapType) {
        self.dataProvider = dataProvider
        self.selectedMapType = mapType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setupHeatMap()
        
        DispatchQueue.main.async {
            self.applySelectedMapType()
        }
    }
    
    /// Sets up the main map view
    private func setupMapView() {
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.mapType = .mutedStandard
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
    }
    
    /// Initializes and configures the heatmap
    private func setupHeatMap() {
        heatMap = HeatMapView(frame: mapView.frame, delegate: self, mapType: selectedMapType)
        heatMap?.delegate = self
        mapView.addSubview(heatMap!)
    }
    
    /// Applies the selected map type to the heatmap
    @objc private func applySelectedMapType() {
        print("Applying selected map type: \(selectedMapType)")
        heatMap?.setType(mapType: selectedMapType)
    }
}
