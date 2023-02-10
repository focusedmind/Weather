//
//  LocalWeatherGateway.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/10/23.
//

import Foundation
import CoreLocation
import RealmSwift
import Combine

class LocalWeatherGateway: WeatherGateway, LocalCachingGateway {
    
    private lazy var realm: Realm = {
        let config = Realm.Configuration(schemaVersion: 2, migrationBlock: { _, _ in })
        Realm.Configuration.defaultConfiguration = config
        return try! Realm()
    }()
    
    private static func filterPredicate(by location: CLLocation, mustHaveWeather: Bool) -> ((LocationRealmEntity) -> Bool) {
        let result: (LocationRealmEntity) -> Bool = { $0.lat == location.coordinate.latitude && $0.lon == location.coordinate.longitude }
        return mustHaveWeather ? { result($0) && $0.latestWeather != nil } : result
    }
    
    func currentWeatherPublisher(at location: CLLocation?) -> AnyPublisher<WeatherResponseEntity, Error> {
        Deferred { [weak self] in
            Future { completion in
                guard let self else {
                    completion(.failure(GenericError.selfIsDeallocated))
                    return
                }

                if let location, let entity = self.realm.objects(LocationRealmEntity.self)
                    .filter(Self.filterPredicate(by: location, mustHaveWeather: true)).first,
                   let domainWeatherEntity = entity.domainWeatherEntity {
                    completion(.success(.init(weather: domainWeatherEntity, location: entity.domainLocationEntity)))
                } else {
                    completion(.failure(GenericError(errorDescription: "Item is not found in cache")))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func store(location: LocationEntity, isCurrent: Bool, weather: WeatherEntity?) -> AnyPublisher<Void, Error> {
        Deferred { [weak self] in
            Future { completion in
                guard let self else {
                    completion(.failure(GenericError.selfIsDeallocated))
                    return
                }
                let objectsToUpdate: LazyFilterSequence<Results<LocationRealmEntity>>
                if isCurrent {
                    objectsToUpdate = self.realm
                        .objects(LocationRealmEntity.self)
                        .filter(\.isCurrent)
                } else {
                    objectsToUpdate = self.realm
                        .objects(LocationRealmEntity.self)
                        .filter(Self.filterPredicate(by: .init(latitude: location.lat, longitude: location.lon),
                                                     mustHaveWeather: false))
                }
                print("## will update: \(objectsToUpdate.count) by \(location.description)")
                self.realm.writeAsync({
                    if !objectsToUpdate.isEmpty {
                        objectsToUpdate.forEach { entity in
                            entity.update(from: location, weatherDomainEntity: weather, isCurrent: isCurrent)
                        }
                    } else {
                        let entity = LocationRealmEntity()
                        entity.createDate = .init()
                        entity.update(from: location, weatherDomainEntity: weather, isCurrent: isCurrent)
                        self.realm.add(entity, update: .modified)
                    }
                }, onComplete: { error in
                    if let error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                })
            }
        }
        .eraseToAnyPublisher()
    }
    
    func storedLocationsPublisher() -> AnyPublisher<[LocationEntity], Error> {
        Deferred { [weak self] in
            Future { completion in
                guard let self else {
                    completion(.failure(GenericError.selfIsDeallocated))
                    return
                }

                let result = self.realm.objects(LocationRealmEntity.self)
                    .sorted(by: { l, r in
                        if l.isCurrent != r.isCurrent {
                            return l.isCurrent
                        } else {
                            return l.createDate < r.createDate
                        }
                    })
                completion(.success(result.map(\.domainLocationEntity)))
            }
        }.eraseToAnyPublisher()
    }
}

fileprivate extension GenericError {
    
    static var selfIsDeallocated: GenericError { .init(errorDescription: "Self is deallocated") }
}
