//
//  WeatherEntity.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/10/23.
//

import Foundation

struct WeatherEntity: Codable {
    
    struct Condition: Codable {
        let text, icon: String
        let code: Int
    }
    
    let tempC: Double
    let isDay: Int
    let condition: Condition
    let humidity: Double
    let cloud: Int
    let lastUpdatedEpoch: Double
    
    var timestamp: Date { .init(timeIntervalSince1970: lastUpdatedEpoch) }
    var iconURL: URL? { .init(string: "https:" + condition.icon) }

    enum CodingKeys: String, CodingKey {
        case lastUpdatedEpoch = "last_updated_epoch"
        case tempC = "temp_c"
        case isDay = "is_day"
        case condition, humidity, cloud
    }
}
