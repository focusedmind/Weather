//
//  Gateways.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import Foundation
import CoreLocation
import Combine

protocol WeatherGateway {
    func currentWeatherPublisher(at location: CLLocation?) -> AnyPublisher<WeatherResponseEntity, Error>
}

protocol LocationsGateway {
    func locationsPublisher(for searchPhrase: String) -> AnyPublisher<[LocationEntity], Error>
}

protocol LocalCachingGateway {
    func store(location: LocationEntity, isCurrent: Bool, weather: WeatherEntity?) -> AnyPublisher<Void, Error>
    func storedLocationsPublisher() -> AnyPublisher<[LocationEntity], Error>
}


typealias NetworkGateway = WeatherGateway & LocationsGateway
typealias LocalGateway = WeatherGateway & LocalCachingGateway
