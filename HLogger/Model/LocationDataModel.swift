//
//  LocationDataModel.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import Foundation

struct LocationEntry: Codable {
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let speed: Double?
    let altitude: Double?
    let horizontalAccuracy: Double
    let verticalAccuracy: Double
    let status: String  // "Moving", "Stationary", etc.
}
