//
//  LocationEntity.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/10/23.
//

import Foundation

struct LocationEntity: Codable {
    
    var coordinatesHash: Int { [lat, lon].hashValue }
    
    let name, region, country: String
    let lat, lon: Double
    var isCurrent: Bool?
    
    var description: String { [name, region, country].filter({ !$0.isEmpty }).joined(separator: ", ") }
}
