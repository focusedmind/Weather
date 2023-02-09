//
//  SearchResponseEntity.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import Foundation

struct SearchResponseEntity: Codable {
    let id: Int
    let name, region, country: String
    let lat, lon: Double
    let url: String
}
