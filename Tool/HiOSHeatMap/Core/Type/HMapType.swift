//
//  HMapType.swift
//  HiOSHeatMap
//
//  Created by 0HugoHu on 3/6/25.
//

/// Defines the different types of heatmaps available
public enum HMapType {
    /// Heatmap with distinct radius-based data points
    case radiusDistinct
    
    /// Heatmap with blurry radius-based data points for smoother transitions
    case radiusBlurry
    
    /// Heatmap with distinct flat data points
    case flatDistinct
}
