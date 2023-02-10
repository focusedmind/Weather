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

class WeatherPresenter: NSObject {
    
    private weak var delegate: RootPresenterProtocol?
    private let isCurrent: Bool
    private let gateway: WeatherGateway
    private var locationState: LocationState { didSet { loadData() } }
    private var cancellables = Set<AnyCancellable>()
    private var dataLoadCancellable: AnyCancellable?
    let weatherSubject = CurrentValueSubject<WeatherResponseEntity?, Never>(nil)

    init(isCurrent: Bool,
         location: CLLocation?,
         gateway: WeatherGateway,
         delegate: RootPresenterProtocol) {
        self.isCurrent = isCurrent
        self.locationState = isCurrent ? .waiting : .value(location)
        self.gateway = gateway
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
    
    private func loadData() {
        if case .value(let location) = locationState {
            dataLoadCancellable = gateway
                .currentWeatherPublisher(at: location)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.handle(error: error)
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
        delegate?.handleTriggeredAlert(with: .init(title: "Couldn't fetch weather",
                                                   subtitle: error.localizedDescription,
                                                   actions: [action]))
    }
}
