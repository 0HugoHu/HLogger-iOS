//
//  HeatMapColorMixer.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/6/25.
//

import UIKit

/// Enum defining color mixing modes
enum ColorMixerMode {
    case blurry
    case distinct
}

/// A struct representing an RGB color in bytes
struct HBytesRGB {
    var red: UInt8 = 0
    var green: UInt8 = 0
    var blue: UInt8 = 0
    var alpha: UInt8 = 255
}

/// A class responsible for color interpolation and mixing for heatmaps
class HeatMapColorMixer: NSObject {
    private(set) var colorArray: [UIColor] = []
    private let queue = DispatchQueue(label: "ColorMixer.Thread", qos: .userInitiated)
    var mixerMode: ColorMixerMode
    
    /// Initializes a new color mixer
    /// - Parameters:
    ///   - colors: An array of base colors used for the gradient
    ///   - levels: Number of gradient steps between colors
    ///   - mode: Color mixing mode (blurry or distinct)
    init(colors: [UIColor], levels: Int, mode: ColorMixerMode = .distinct) {
        self.mixerMode = mode
        super.init()
        
        guard levels > 1 else {
            self.colorArray = colors
            return
        }
        
        queue.async { [weak self] in
            self?.generateColorGradient(from: colors, levels: levels)
        }
    }
    
    /// Generates a color gradient between given colors
    /// - Parameters:
    ///   - colors: The base colors
    ///   - levels: The number of gradient steps
    private func generateColorGradient(from colors: [UIColor], levels: Int) {
        guard colors.count > 1 else { return }
        
        for i in 0..<colors.count - 1 {
            guard let startRGB = colors[i].rgb(),
                  let endRGB = colors[i + 1].rgb() else { continue }
            
            let step = 1.0 / Double(levels)
            
            for j in 0...levels {
                let weight = Double(j) * step
                let blendedRGB = HBytesRGB(
                    red: UInt8(startRGB.red * (1 - weight) + endRGB.red * weight),
                    green: UInt8(startRGB.green * (1 - weight) + endRGB.green * weight),
                    blue: UInt8(startRGB.blue * (1 - weight) + endRGB.blue * weight),
                    alpha: 255
                )
                colorArray.append(blendedRGB.toUIColor())
            }
        }
    }
    
    /// Retrieves the color for a given intensity
    /// - Parameter intensity: The intensity value (0.0 to 1.0)
    /// - Returns: The corresponding color in `HBytesRGB`
    func getColor(for intensity: Double) -> HBytesRGB {
        guard intensity > 0, !colorArray.isEmpty else { return HBytesRGB(alpha: 0) }
        return mixerMode == .blurry ? getBlurryColor(for: intensity) : getDistinctColor(for: intensity)
    }
    
    /// Retrieves a distinct color for a given intensity
    /// - Parameter intensity: The intensity value (0.0 to 1.0)
    /// - Returns: A distinct color from the predefined gradient
    private func getDistinctColor(for intensity: Double) -> HBytesRGB {
        let index = min(Int(Double(colorArray.count - 1) * intensity), colorArray.count - 1)
        return colorArray[index].rgbAsBytes()
    }
    
    /// Retrieves a blended color between two closest gradient colors
    /// - Parameter intensity: The intensity value (0.0 to 1.0)
    /// - Returns: A smoothly blended color
    private func getBlurryColor(for intensity: Double) -> HBytesRGB {
        let index = min(Int(Double(colorArray.count - 1) * intensity), colorArray.count - 2)
        let weight = (Double(colorArray.count - 1) * intensity).truncatingRemainder(dividingBy: 1)
        
        guard index >= 0, index < colorArray.count - 1 else {
            return colorArray.last?.rgbAsBytes() ?? HBytesRGB()
        }
        
        let leftColor = colorArray[index].rgb() ?? (0, 0, 0, 1)
        let rightColor = colorArray[index + 1].rgb() ?? (0, 0, 0, 1)
        
        return HBytesRGB(
            red: UInt8(leftColor.red * (1 - weight) + rightColor.red * weight),
            green: UInt8(leftColor.green * (1 - weight) + rightColor.green * weight),
            blue: UInt8(leftColor.blue * (1 - weight) + rightColor.blue * weight),
            alpha: UInt8(intensity * 255)
        )
    }
}

extension UIColor {
    /// Converts `UIColor` to its RGB components
    /// - Returns: A tuple of (red, green, blue, alpha)
    func rgb() -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return (red * 255, green * 255, blue * 255, alpha)
    }
    
    /// Converts `UIColor` to `HBytesRGB`
    func rgbAsBytes() -> HBytesRGB {
        guard let (red, green, blue, _) = rgb() else { return HBytesRGB() }
        return HBytesRGB(red: UInt8(red), green: UInt8(green), blue: UInt8(blue))
    }
    
    /// Converts `UIColor` to `HBytesRGB`
    func toBytesRGB() -> HBytesRGB {
        return self.rgbAsBytes()
    }
    
    /// Creates a `UIColor` from `HBytesRGB`
    static func fromBytes(_ bytes: HBytesRGB) -> UIColor {
        return UIColor(
            red: Double(bytes.red) / 255.0,
            green: Double(bytes.green) / 255.0,
            blue: Double(bytes.blue) / 255.0,
            alpha: Double(bytes.alpha) / 255.0
        )
    }
}

extension HBytesRGB {
    /// Converts `HBytesRGB` to `UIColor`
    func toUIColor() -> UIColor {
        return UIColor.fromBytes(self)
    }
}
