//
//  HeatMapRender.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/5/25.
//

import Foundation
import MapKit

/// Base class for heatmap rendering overlays
class HeatMapRender: MKOverlayRenderer {
    var lastImage: CGImage?
    var bitmapSize = HBitMapSize()
    var bytesPerRow: Int = 0
    var dataReference: [UInt8] = []
    
    var bitmapMemorySize: Int {
        bitmapSize.width * bitmapSize.height * 4
    }
    
    /// Initializes the heatmap renderer
    /// - Parameter overlay: The heatmap overlay to be rendered
    init(overlay: HeatMapOverlay) {
        super.init(overlay: overlay)
        self.alpha = HIOSHEATMAP_DEFAULT_OVERLAY_ALPHA
    }
    
    /// Calculates row form data for rendering
    /// - Parameter level: The maximum heat level
    /// - Returns: Optional tuple containing row form data and a bounding rectangle
    func calculateRowFormData(maxHeat level: Int) -> (data: [RowFormHeatData], rect: CGRect)? {
        return nil
    }
    
    /// Updates the bitmap from the processed row data
    /// - Parameter producer: The heatmap data processor
    func updateBitmap(from producer: HeatMapDataProcessor) {
        self.bitmapSize = producer.optimizedSize
        self.bytesPerRow = producer.bytesPerRow
        self.dataReference = producer.rowData
    }
    
    /// Renders the heatmap overlay on the map
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? HeatMapOverlay else { return }
        let mapCGRect = rect(for: overlay.boundingMapRect)
        
        if let lastImage = lastImage {
            context.draw(lastImage, in: mapCGRect)
            return
        } else if dataReference.isEmpty {
            return
        }
        
        if let tempImage = createHeatMapImage() {
            lastImage = tempImage
            context.clear(mapCGRect)
            dataReference.removeAll()
            context.draw(lastImage!, in: mapCGRect)
        } else {
            print("Error creating heatmap image")
        }
    }
    
    /// Creates a heatmap CGImage
    /// - Returns: Optional CGImage representing the heatmap
    private func createHeatMapImage() -> CGImage? {
        guard let tempBuffer = malloc(bitmapMemorySize) else { return nil }
        defer { free(tempBuffer) }
        
        memcpy(tempBuffer, &dataReference, bytesPerRow * bitmapSize.height)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        return CGContext(
            data: tempBuffer,
            width: bitmapSize.width,
            height: bitmapSize.height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo
        )?.makeImage()
    }
    
    /// Generates row form data from a heatmap overlay
    /// - Parameters:
    ///   - overlay: The heatmap overlay
    ///   - level: The maximum heat level
    /// - Returns: A tuple containing row form data and the bounding rectangle
    func generateRowFormData(for overlay: HeatMapOverlay, maxHeat level: Int) -> (data: [RowFormHeatData], rect: CGRect) {
        let rowFormData = overlay.heatPoints.map { heatpoint -> RowFormHeatData in
            let globalCGPoint = point(for: heatpoint.midMapPoint)
            let overlayCGRect = rect(for: overlay.boundingMapRect)
            let localCGPoint = CGPoint(
                x: globalCGPoint.x - overlayCGRect.origin.x,
                y: globalCGPoint.y - overlayCGRect.origin.y
            )
            let radiusCGDistance = rect(for: MKMapRect(origin: MKMapPoint(x: 0.0, y: 0.0), size: MKMapSize(width: heatpoint.radiusInMKDistance, height: heatpoint.radiusInMKDistance))).width
            
            return RowFormHeatData(
                heatLevel: Double(heatpoint.heatLevel) / Double(level),
                localCGPoint: localCGPoint,
                radius: radiusCGDistance
            )
        }
        
        return (data: rowFormData, rect: rect(for: overlay.boundingMapRect))
    }
}

/// Renderer for radius-based heatmap overlays
class RadiusPointOverlayRender: HeatMapRender {
    override func calculateRowFormData(maxHeat level: Int) -> (data: [RowFormHeatData], rect: CGRect)? {
        guard let overlay = overlay as? HeatRadiusPointOverlay else { return nil }
        return generateRowFormData(for: overlay, maxHeat: level)
    }
}

/// Renderer for flat-point heatmap overlays
class FlatPointOverlayRender: HeatMapRender {
    override func calculateRowFormData(maxHeat level: Int) -> (data: [RowFormHeatData], rect: CGRect)? {
        guard let overlay = overlay as? HeatFlatPointOverlay else { return nil }
        return generateRowFormData(for: overlay, maxHeat: level)
    }
}
