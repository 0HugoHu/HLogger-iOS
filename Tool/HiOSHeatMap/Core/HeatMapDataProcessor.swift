//
//  HeatMapDataProcessor.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/5/25.
//

import Foundation
import MapKit

/// Represents the overlay bit map size
struct HBitMapSize {
    var width: Int = 0
    var height: Int = 0
}

/// Represents a single heat data point used in row-based heatmap processing
struct RowFormHeatData {
    var heatLevel: Double = 0
    var localCGPoint: CGPoint = .zero
    var radius: Double = 0
}

/// Base class for processing raw heatmap data into pixel-based row data
class HeatMapDataProcessor: NSObject {
    let originRowData: [RowFormHeatData]
    let originalSize: CGSize
    static var colorMixer: HeatMapColorMixer!
    
    var rowData: [UInt8] = []
    var processedRowData: [RowFormHeatData] = []
    var optimizedSize: HBitMapSize!
    
    var bytesPerRow: Int {
        4 * optimizedSize.width
    }
    
    /// Initializes the processor with heatmap data
    /// - Parameters:
    ///   - size: The original size of the heatmap
    ///   - rowHeatData: The raw heatmap data points
    init(size: CGSize, rowHeatData: [RowFormHeatData]) {
        self.originRowData = rowHeatData
        self.originalSize = size
        super.init()
    }
    
    /// Reduces heatmap size to optimize memory usage.
    /// - Parameter scale: The scale factor to reduce the size
    func reduceSize(scale: Double) {
        let scaleFactor = scale * 1.5
        optimizedSize = HBitMapSize(
            width: Int(originalSize.width * scaleFactor),
            height: Int(originalSize.height * scaleFactor)
        )
        
        processedRowData = originRowData.map {
            RowFormHeatData(
                heatLevel: $0.heatLevel,
                localCGPoint: CGPoint(
                    x: $0.localCGPoint.x * scaleFactor,
                    y: $0.localCGPoint.y * scaleFactor
                ),
                radius: $0.radius * scaleFactor
            )
        }
        
        rowData = Array(repeating: 0, count: 4 * optimizedSize.width * optimizedSize.height)
    }
    
    /// Subclasses should override this method to generate heatmap row data.
    func produceRowData() { }
}

/// Base class for row data calculation.
class HeatMapRowDataProducer: HeatMapDataProcessor {
    override func produceRowData() {
        rowData = Array(repeating: 0, count: 4 * optimizedSize.width * optimizedSize.height)
        
        for y in 0..<optimizedSize.height {
            for x in 0..<optimizedSize.width {
                let pixelCGPoint = CGPoint(x: x, y: y)
                let heatIntensity = calculateHeatIntensity(at: pixelCGPoint)
                let rgb = HeatMapDataProcessor.colorMixer.getColor(for: heatIntensity)
                
                let byteIndex = (y * optimizedSize.width + x) * 4
                rowData[byteIndex] = rgb.red
                rowData[byteIndex + 1] = rgb.green
                rowData[byteIndex + 2] = rgb.blue
                rowData[byteIndex + 3] = adjustAlpha(for: rgb.alpha, with: heatIntensity)
            }
        }
    }
    
    /// Calculates heat intensity at a specific pixel location.
    /// - Parameter pixelCGPoint: The coordinate of the pixel
    /// - Returns: The computed heat intensity value (0.0 - 1.0)
    private func calculateHeatIntensity(at pixelCGPoint: CGPoint) -> Double {
        let intensity = processedRowData.reduce(0) { intensity, heatPoint in
            let distance = pixelCGPoint.distance(to: heatPoint.localCGPoint)
            let radius = heatPoint.radius
            let ratio = max(0, 1 - (distance / radius))
            return intensity + (ratio * heatPoint.heatLevel)
        }
        
        return min(max(intensity, 0.0), 1.0)
    }
    
    /// Adjusts alpha values based on heat intensity.
    /// - Parameters:
    ///   - alpha: The base alpha value
    ///   - intensity: The computed heat intensity
    /// - Returns: The adjusted alpha value
    private func adjustAlpha(for alpha: UInt8, with intensity: Double) -> UInt8 {
        max(1, UInt8(intensity * 255))
    }
}

/// Generates heatmap data for **radius-based points**.
class RadiusPointRowDataProducer: HeatMapRowDataProducer { }

/// Generates heatmap data for **flat-based points**.
class FlatPointRowDataProducer: HeatMapRowDataProducer { }

extension CGPoint {
    /// Calculates Euclidean distance between two points.
    /// - Parameter point: The second point to calculate distance to
    /// - Returns: The Euclidean distance between the two points
    func distance(to point: CGPoint) -> Double {
        let dx = Double(x - point.x)
        let dy = Double(y - point.y)
        return sqrt(dx * dx + dy * dy)
    }
}
