//
//  HDataPointType.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/6/25.
//

/// Defines the types of data points used in heatmaps
enum HDataPointType {
    /// Represents a flat heatmap point without radius-based diffusion
    case flatPoint
    
    /// Represents a radius-based heatmap point with diffusion effect
    case radiusPoint
}
