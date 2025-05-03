//
//  HeatMapProcessor.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/5/25.
//

import Foundation
import MapKit

/// Processes and manages heatmap data for rendering
class HeatMapProcessor: NSObject {
    typealias ProducerFor = [HeatMapRender: HeatMapDataProcessor]
    
    public var biggestRegion: MKMapRect = .null
    
    private(set) var renderProducerPairs: ProducerFor = [:]
    weak var swiftHeatMap: HeatMapView!
    private var isCalculating = false
    private let dataType: HDataPointType
    private let mapWidthInUIView: CGFloat
    private var maxHeatLevelInMap = 0
    private let missionQueue = DispatchQueue(label: "site.hugohu.hlogger.heatmap.missionQueue", qos: .userInitiated)
    
    /// Initializes the heatmap processor
    /// - Parameters:
    ///   - map: The heatmap instance
    ///   - dataType: The type of heat data points
    ///   - mode: The color mixing mode
    init(map: HeatMapView, dataType: HDataPointType, mode: ColorMixerMode) {
        self.swiftHeatMap = map
        self.dataType = dataType
        self.mapWidthInUIView = map.frame.width
        HeatMapDataProcessor.colorMixer.mixerMode = mode
    }
    
    /// Retrieves the renderer for a given overlay
    func renderer(for overlay: HeatMapOverlay) -> HeatMapRender? {
        return swiftHeatMap.renderer(for: overlay) as? HeatMapRender
    }
    
    /// Refreshes and processes heatmap data
    func refreshMap() {
        renderProducerPairs.removeAll()
        swiftHeatMap.removeOverlays(swiftHeatMap.overlays)
        
        guard let heatDelegate = swiftHeatMap.heatmapDelegate else { return }
        
        let dataCount = heatDelegate.heatmap(heatPointCount: swiftHeatMap)
        for i in 0..<dataCount {
            let heatPoint = HPoint(
                heatLevel: heatDelegate.heatmap(heatLevelFor: i),
                coordinate: heatDelegate.heatmap(coordinateFor: i),
                heatRadiusInKM: heatDelegate.heatmap(radiusInKMFor: i)
            )
            
            maxHeatLevelInMap = max(maxHeatLevelInMap, heatPoint.heatLevel)
            
            switch dataType {
            case .flatPoint:
                processFlatPoint(heatPoint)
            case .radiusPoint:
                processRadiusPoint(heatPoint)
            }
        }
        
        precondition(maxHeatLevelInMap > 0, "Max Heat level should not be 0")
        optimizeOverlays()
        calculateHeatmapRegion()
        startComputingRowData()
    }
    
    /// Processes flat point overlays
    private func processFlatPoint(_ heatPoint: HPoint) {
        if let overlay = swiftHeatMap.overlays.compactMap({ $0 as? HeatFlatPointOverlay }).first {
            overlay.insertHeatPoint(heatPoint)
        } else {
            swiftHeatMap.addOverlay(HeatFlatPointOverlay(initialHeatPoint: heatPoint), level: .aboveLabels)
        }
    }
    
    /// Processes radius-based overlays
    private func processRadiusPoint(_ heatPoint: HPoint) {
        for overlay in swiftHeatMap.overlays.compactMap({ $0 as? HeatRadiusPointOverlay }) {
            if overlay.boundingMapRect.intersects(heatPoint.mapRect) {
                overlay.insertHeatPoint(heatPoint)
                return
            }
        }
        swiftHeatMap.addOverlay(HeatRadiusPointOverlay(initialHeatPoint: heatPoint), level: .aboveLabels)
    }
    
    /// Optimizes and merges overlapping overlays
    private func optimizeOverlays() {
        var overlays = swiftHeatMap.overlays.compactMap { $0 as? HeatRadiusPointOverlay }
        
        var i = 0
        while i < overlays.count {
            var j = i + 1
            while j < overlays.count {
                if overlays[i].boundingMapRect.intersects(overlays[j].boundingMapRect) {
                    overlays[j].heatPoints.forEach { overlays[i].insertHeatPoint($0) }
                    swiftHeatMap.removeOverlay(overlays[j])
                    overlays.remove(at: j)
                } else {
                    j += 1
                }
            }
            i += 1
        }
    }
    
    /// Calculates the region covered by the heatmap
    private func calculateHeatmapRegion() {
        biggestRegion = swiftHeatMap.overlays
            .compactMap { $0 as? HeatMapOverlay }
            .map { $0.boundingMapRect }
            .max(by: { $0.size.width * $0.size.height < $1.size.width * $1.size.height }) ?? .null
    }
    
    /// Starts computing heatmap row data
    func startComputingRowData() {
        lastVisibleMapRect = swiftHeatMap.visibleMapRect
        missionQueue.async {
            self.computeOverlayData()
            self.calculateStart()
        }
    }
    
    /// Computes data for each overlay
    private func computeOverlayData() {
        swiftHeatMap.overlays.compactMap { $0 as? HeatMapOverlay }.forEach { overlay in
            guard let render = self.renderer(for: overlay),
                  let calculatedData = render.calculateRowFormData(maxHeat: maxHeatLevelInMap) else { return }
            
            let producer: HeatMapDataProcessor = self.dataType == .radiusPoint
            ? RadiusPointRowDataProducer(size: calculatedData.rect.size, rowHeatData: calculatedData.data)
            : FlatPointRowDataProducer(size: calculatedData.rect.size, rowHeatData: calculatedData.data)
            
            renderProducerPairs[render] = producer
            producer.reduceSize(scale: Double(self.mapWidthInUIView) / self.biggestRegion.size.width)
        }
    }
    
    /// Begins rendering calculation
    func calculateStart() {
        self.isCalculating = true
        missionQueue.async {
            self.swiftHeatMap.overlays.compactMap { $0 as? HeatMapOverlay }.forEach { overlay in
                guard let render = self.renderer(for: overlay),
                      let producer = self.renderProducerPairs[render] else { return }
                
                producer.produceRowData()
                render.updateBitmap(from: producer)
                render.setNeedsDisplay()
            }
            
            DispatchQueue.main.sync {
                self.swiftHeatMap.indicator?.stopAnimating()
                self.isCalculating = false
                self.zoomOutToRegion()
            }
        }
    }
    
    /// Adjusts the map to fit the computed heatmap region
    private func zoomOutToRegion() {
        let zoomOutRect = biggestRegion.insetBy(dx: -biggestRegion.size.width * HIOSHEATMAP_DEFAULT_MAP_REGION_SIZE_FACTOR, dy: -biggestRegion.size.height * HIOSHEATMAP_DEFAULT_MAP_REGION_SIZE_FACTOR)
        swiftHeatMap.setVisibleMapRect(zoomOutRect, animated: true)
    }
    
    private var lastVisibleMapRect: MKMapRect = .null
}
