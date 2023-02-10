//
//  WeatherPresenter.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import Foundation
import Combine
import CoreLocation
import UIKit

class WeatherPresenter: NSObject, Identifiable {
    
    var id: Int { [location?.coordinate.latitude, location?.coordinate.longitude, isCurrent ? 1 : 0].hashValue }
    private weak var delegate: RootPresenterProtocol?
    private let isCurrent: Bool
    private var location: CLLocation?
    private let localGateway: LocalGateway
    private let networkGateway: NetworkGateway
    private var locationState: LocationState { didSet { loadData() } }
    private var cancellables = Set<AnyCancellable>()
    private var dataLoadCancellable: AnyCancellable?
    private(set) var isResultFromCache = false
    let weatherSubject = CurrentValueSubject<WeatherResponseEntity?, Never>(nil)

    init(isCurrent: Bool,
         location: CLLocation?,
         localGateway: LocalGateway,
         networkGateway: NetworkGateway,
         delegate: RootPresenterProtocol) {
        self.isCurrent = isCurrent
        self.locationState = isCurrent ? .waiting : .value(location)
        self.location = location
        self.localGateway = localGateway
        self.networkGateway = networkGateway
        self.delegate = delegate
        super.init()
        if isCurrent {
            self.delegate?
                .locationPublisher
                .sink(receiveValue: { [weak self] state in self?.locationState = state })
                .store(in: &cancellables)
        }
    }
    
    func handleViewWillAppear() {
        if isCurrent {
            delegate?.handleCurrentLocationRequest()
        }
        loadData()
    }
    
    private func loadData(fromNetwork: Bool = true) {
        if case .value(let location) = locationState {
            let publisher: AnyPublisher<WeatherResponseEntity, Error>
            publisher = fromNetwork ? networkGateway.currentWeatherPublisher(at: location) : localGateway.currentWeatherPublisher(at: location)
            dataLoadCancellable = publisher
                .handleEvents(receiveOutput: { [weak self] weather in
                    guard let self else { return }
                    if fromNetwork {
                        self.localGateway
                            .store(location: weather.location, isCurrent: self.isCurrent, weather: weather.weather)
                            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                            .store(in: &self.cancellables)
                    }
                })
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    switch result {
                    case .failure(let error):
                        if fromNetwork {
                            self?.handle(error: error)
                            self?.loadData(fromNetwork: false)
                        }
                    case .finished:
                        break
                    }
                } receiveValue: { [weak self] weatherEntity in
                    self?.weatherSubject.send(weatherEntity)
                }
        }
    }
    
    private func handle(error: Error) {
        let action = UIAlertAction(title: "OK", style: .default)
        let body = error.localizedDescription + "\n\nData from cache will be used if available."
        delegate?.handleTriggeredAlert(with: .init(title: "Couldn't fetch weather",
                                                   subtitle: body,
                                                   actions: [action]))
    }
}
