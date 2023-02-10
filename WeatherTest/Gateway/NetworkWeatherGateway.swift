//
//  NetworkWeatherGateway.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/10/23.
//

import Foundation
import Combine
import CoreLocation
import Alamofire

class NetworkWeatherGateway: WeatherGateway, LocationsGateway {
    
    enum Constants {
        static let host = "https://api.weatherapi.com/v1/"
        //MARK: - TODO store secret in keychain
        static let key = "89f7c1735875426f82c122657230902"
    }
    
    func currentWeatherPublisher(at location: CLLocation?) -> AnyPublisher<WeatherResponseEntity, Error> {
        let params: [String : String]
        if let location {
            params = createParams(using: "\(location.coordinate.latitude),\(location.coordinate.longitude)")
        } else {
            params = createParams(using: "auto:ip")
        }
        return AF
            .request(Constants.host + "current.json", parameters: params)
            .publishDecodable()
            .value()
            .mapError({ GenericError(errorDescription: $0.localizedDescription) })
            .eraseToAnyPublisher()
    }
    
    func locationsPublisher(for searchPhrase: String) -> AnyPublisher<[LocationEntity], Error> {
        AF
            .request(Constants.host + "search.json", parameters: createParams(using: searchPhrase))
            .publishDecodable()
            .value()
            .mapError({ GenericError(errorDescription: $0.localizedDescription) })
            .eraseToAnyPublisher()
    }
    
    private func createParams(using query: String) -> [String : String] {
        ["key" : Constants.key, "q": query]
    }
}
