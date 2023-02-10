//
//  RealmEntities.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/10/23.
//

import Foundation
import RealmSwift

class WeatherConditionRealmEntity: Object {
    
    @Persisted(primaryKey: true) var _id: String = UUID().uuidString
    @Persisted var text: String
    @Persisted var icon: String
    @Persisted var code: Int
    
    var domainEntity: WeatherEntity.Condition {
        .init(text: text, icon: icon, code: code)
    }
    
    func update(from domainEntity: WeatherEntity.Condition) {
        text = domainEntity.text
        icon = domainEntity.icon
        code = domainEntity.code
    }
}

class WeatherRealmEntity: Object {
    
    @Persisted(primaryKey: true) var _id: String = UUID().uuidString
    @Persisted var tempC: Double
    @Persisted var humidity: Double
    @Persisted var isDay: Int
    @Persisted var condition: WeatherConditionRealmEntity!
    @Persisted var cloud: Int
    @Persisted var lastUpdatedEpoch: Double
    
    var timestamp: Date { .init(timeIntervalSince1970: lastUpdatedEpoch) }
    var iconURL: URL? { .init(string: "https:" + condition.icon) }
    
    var domainEntity: WeatherEntity {
        .init(tempC: tempC, isDay: isDay, condition: condition.domainEntity,
              humidity: humidity, cloud: cloud, lastUpdatedEpoch: lastUpdatedEpoch)
    }
    
    func update(from domainEntity: WeatherEntity) {
        tempC = domainEntity.tempC
        humidity = domainEntity.humidity
        isDay = domainEntity.isDay
        cloud = domainEntity.cloud
        lastUpdatedEpoch = domainEntity.lastUpdatedEpoch
        if condition == nil {
            condition = .init()
        }
        condition.update(from: domainEntity.condition)
    }
}

class LocationRealmEntity: Object {
    
    @Persisted(primaryKey: true) var _id: String = UUID().uuidString
    @Persisted var name: String
    @Persisted var region: String
    @Persisted var country: String
    @Persisted var lat: Double
    @Persisted var lon: Double
    @Persisted var latestWeather: WeatherRealmEntity?
    @Persisted var isCurrent: Bool
    @Persisted var createDate: Date
    
    var domainLocationEntity: LocationEntity {
        .init(name: name, region: region, country: country, lat: lat, lon: lon, isCurrent: isCurrent)
    }
    
    var domainWeatherEntity: WeatherEntity? {
        if let latestWeather {
            return .init(tempC: latestWeather.tempC, isDay: latestWeather.isDay, condition: latestWeather.condition.domainEntity,
                         humidity: latestWeather.humidity, cloud: latestWeather.cloud, lastUpdatedEpoch: latestWeather.lastUpdatedEpoch)
        } else {
            return  nil
        }
    }
    
    func update(from domainEntity: LocationEntity, weatherDomainEntity: WeatherEntity?, isCurrent: Bool) {
        name = domainEntity.name
        region = domainEntity.region
        country = domainEntity.country
        lat = domainEntity.lat
        lon = domainEntity.lon
        self.isCurrent = isCurrent
        if let weatherDomainEntity {
            if let latestWeather {
                latestWeather.update(from: weatherDomainEntity)
            } else {
                latestWeather = .init()
                latestWeather?.update(from: weatherDomainEntity)
            }
        }
    }
}
