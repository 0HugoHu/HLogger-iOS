//
//  AppController.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import Foundation

class AppController : ObservableObject {
    private let locationModule = LocationModule()
    
    func startApp() {
        SchemaManager.fetchSchema { schema in
            if let schema = schema {
                print("Schema fetched: \(schema)")
            }
        }
        locationModule.startTracking()
    }
}
