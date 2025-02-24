//
//  SchemaManager.swift
//  HLogger
//
//  Created by Hugooooo on 2/22/25.
//

import Foundation

struct SchemaManager {
    static let schemaURL = "https://s3.us-east-2.amazonaws.com/logger.protocol/location_schema.proto"
    
    static func fetchSchema(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: schemaURL) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let schemaString = String(data: data, encoding: .utf8) {
                completion(schemaString)
            } else {
                completion(nil)
            }
        }.resume()
    }
}
