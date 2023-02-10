//
//  WeatherResponseEntity.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import Foundation

struct WeatherResponseEntity: Codable {
    let current: WeatherEntity
    let location: LocationEntity
}

struct LocationEntity: Codable {
    let name, region, country: String
    let lat, lon: Double
    let localtimeEpoch: Double?
    
    var timestamp: Date? { localtimeEpoch.flatMap { .init(timeIntervalSince1970: $0) } }
    var description: String { [name, region, country].joined(separator: ", ") }

    enum CodingKeys: String, CodingKey {
        case name, region, country, lat, lon
        case localtimeEpoch = "localtime_epoch"
    }
}
struct WeatherEntity: Codable {
    
    struct Condition: Codable {
        let text, icon: String
        let code: Int
    }
    
    private let lastUpdatedEpoch: Double
    var timestamp: Date { .init(timeIntervalSince1970: lastUpdatedEpoch) }
    let tempC, tempF: Double
    let isDay: Int
    let condition: Condition
    let humidity: Double
    let cloud: Int

    enum CodingKeys: String, CodingKey {
        case lastUpdatedEpoch = "last_updated_epoch"
        case tempC = "temp_c"
        case tempF = "temp_f"
        case isDay = "is_day"
        case condition, humidity, cloud
    }
}

