//
//  WeatherResponseEntity.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import Foundation

struct WeatherResponseEntity: Codable {
    let weather: WeatherEntity
    let location: LocationEntity
    
    enum CodingKeys: String, CodingKey {
        case weather = "current"
        case location
    }
}
