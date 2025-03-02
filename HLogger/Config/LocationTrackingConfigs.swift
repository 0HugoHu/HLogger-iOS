//
//  LocationTrackingConfigs.swift
//  HLogger
//
//  Created by Hugooooo on 2/25/25.
//

import CoreMotion

let LOCATION_MANAGER_DISTANCE_FILTER = 60.0

let LOCATION_MANAGER_LOG_CONDITION_DISTANCE = 50.0
let LOCATION_MANAGER_LOG_CONDITION_TIME_INTERVAL_SEC = 60 * 60.0
let LOCATION_MANAGER_LOG_CONDITION_TIME_OFFSET_SEC = -10.0

let LOCATION_MANAGER_ACTIVITY_STATIONARY_THRESHOLD = 0.5
let LOCATION_MANAGER_ACTIVITY_CONFIDENCE_THRESHOLD = CMMotionActivityConfidence.high


enum ActivityStatus: String {
    case driving = "Driving"
    case cycling = "Cycling"
    case running = "Running"
    case walking = "Walking"
    case stationary = "Stationary"
    case unknown = "Unknown Activity"
    case other = "Other Movement"
}
