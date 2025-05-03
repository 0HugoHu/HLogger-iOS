//
//  LocationTrackingConfigs.swift
//  HLogger
//
//  Created by Hugooooo on 2/25/25.
//

import CoreMotion

let LOCATION_MANAGER_LOG_CONDITION_ACCURACY_HUNDREDTHS: CLLocationAccuracy = kCLLocationAccuracyBestForNavigation

let LOCATION_MANAGER_LOG_CONDITION_TIME_INTERVAL_SEC = 50.0
let LOCATION_MANAGER_ACTIVITY_LOOK_BACK_SEC = 10.0

let LOCATION_MANAGER_DISTANCE_FILTER = 50.0
let LOCATION_MANAGER_DISTANCE_FILTER_WALKING = 20.0
let LOCATION_MANAGER_DISTANCE_FILTER_CYCLING = 20.0
let LOCATION_MANAGER_DISTANCE_FILTER_RUNNING = 20.0
let LOCATION_MANAGER_DISTANCE_FILTER_DRIVING = 200.0

let LOCATION_MANAGER_MOVING_THRESHOLD = 1.2
let LOCATION_MANAGER_DRIVING_LOW_SPEED_THRESHOLD = 5.0

let LOCATION_MANAGER_UNKNOWN = "Unknown"

let LOCATION_MANAGER_LOG_FILE_NAME_SUFFIX = "location"


enum ActivityStatus: String {
    case driving = "Driving"
    case cycling = "Cycling"
    case running = "Running"
    case walking = "Walking"
    case stationary = "Stationary"
    case unknown = "Unknown"
    case unsuppported = "Unsupported"
    case other = "Other"
}
