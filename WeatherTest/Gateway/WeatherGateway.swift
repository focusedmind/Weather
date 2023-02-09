//
//  WeatherGateway.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import Foundation
import CoreLocation
import Combine
import Alamofire

protocol WeatherGateway {
    
    func fetchWeatherFuture(at location: CLLocation?) -> AnyPublisher<WeatherResponseEntity, Error>
}

class NetworkWeatherGateway: WeatherGateway {
    
    enum Constants {
        static let host = "http://api.weatherapi.com/v1/"
        //MARK: - TODO store secret in keychain
        static let key = ""
    }
    
    func fetchWeatherFuture(at location: CLLocation?) -> AnyPublisher<WeatherResponseEntity, Error> {
        let params: [String : String]
        if let location {
            params = createParams(using: "\(location.coordinate.latitude),\(location.coordinate.longitude)")
        } else {
            params = createParams(using: "auto:ip")
        }
        return AF
            .request(Constants.host + "current.json", parameters: params)
            .publishDecodable(type: WeatherResponseEntity.self)
            .value()
            .mapError({ GenericError(localizedDescription: $0.localizedDescription) })
            .eraseToAnyPublisher()
    }
    
    private func createParams(using query: String) -> [String : String] {
        ["key" : Constants.key, "q": query]
    }
}

struct GenericError: Error {
    let localizedDescription: String
}
