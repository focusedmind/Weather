//
//  RootPresenter.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import Foundation
import Combine
import CoreLocation
import UIKit

enum LocationState {
    case value(CLLocation?)
    case waiting
}

protocol RootPresenterProtocol: AnyObject {
    var locationPublisher: CurrentValueSubject<LocationState, Never> { get }
    
    func handleCurrentLocationRequest()
    func handleTriggeredAlert(with model: AlertModel)
    func handleNewLocationAdded(entity: LocationEntity)
}

class RootPresenter: NSObject {
    
    private let locationManager = CLLocationManager()
    private let settings: Settings
    private var hasPermissionsBeenCheckedOnAppear = false
    private var notificatonCancellable: AnyCancellable? = nil
    private var locationsCancellable: AnyCancellable? = nil
    private var storeCancellables = Set<AnyCancellable>()
    private lazy var defaultPagePresenter = WeatherPresenter(isCurrent: true, location: nil, localGateway: self.localGateway,
                                                             networkGateway: self.networkGateway, delegate: self)
    @Published private(set) var pagePresenters: [WeatherPresenter] = []
    let networkGateway: NetworkGateway
    let localGateway: LocalGateway
    let alertPublisher = PassthroughSubject<AlertModel, Never>()
    let locationPublisher = CurrentValueSubject<LocationState, Never>(.waiting)
    
    init(networkGateway: NetworkGateway,
         localGateway: LocalGateway,
         settings: Settings = UserDefaults.standard) {
        self.networkGateway = networkGateway
        self.localGateway = localGateway
        self.settings = settings
        super.init()
        setupPagePresenters()
        locationManager.delegate = self
        notificatonCancellable = NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink(receiveValue: { [weak self] _ in self?.handleCurrentLocationRequest() })
    }
    
    func handleViewWillAppear() {
        if !hasPermissionsBeenCheckedOnAppear {
            hasPermissionsBeenCheckedOnAppear = true
            checkPermissions(using: locationManager)
        }
    }

    private func checkPermissions(using locationManager: CLLocationManager) {
        switch locationManager.authorizationStatus {
        case .denied, .restricted:
            if !settings.isLowAccuracyModeEnabled {
                let openSettingsAction = UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
                    
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                })
                let continueWithLowAccuracy = UIAlertAction(title: "Continue with low accuracy", style: .default, handler: { [weak self] _ in
                    self?.settings.isLowAccuracyModeEnabled = true
                    self?.locationPublisher.send(.value(nil))
                })
                let alertModel = AlertModel(title: "Warning",
                                            subtitle: "Missing location permissions",
                                            actions: [openSettingsAction, continueWithLowAccuracy])
                alertPublisher.send(alertModel)
            } else {
                locationPublisher.send(.value(nil))
            }
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            break
        }
    }
    
    private func setupPagePresenters() {
        if pagePresenters.isEmpty {
            self.pagePresenters = [defaultPagePresenter]
        }
        locationsCancellable = localGateway
            .storedLocationsPublisher()
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { [weak self] locations in
                guard let self else { return }
                if !locations.isEmpty {
                    self.pagePresenters = locations
                        .map { location in
                            return WeatherPresenter(isCurrent: location.isCurrent ?? false,
                                                    location: .init(latitude: location.lat, longitude: location.lon),
                                                    localGateway: self.localGateway,
                                                    networkGateway: self.networkGateway, delegate: self)
                        }
                } else {
                    self.pagePresenters = [self.defaultPagePresenter]
                }
            }
    }
    
    func handleCurrentLocationRequest() {
        checkPermissions(using: locationManager)
    }
}

// MARK: - RootPresenterProtocol
extension RootPresenter: RootPresenterProtocol {
    
    func handleTriggeredAlert(with model: AlertModel) { alertPublisher.send(model) }
    
    func handleNewLocationAdded(entity: LocationEntity) {
        pagePresenters.append(.init(isCurrent: false,
                                    location: .init(latitude: entity.lat, longitude: entity.lon),
                                    localGateway: localGateway,
                                    networkGateway: networkGateway,
                                    delegate: self))
        localGateway
            .store(location: entity, isCurrent: false, weather: nil)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &storeCancellables)
    }
}

// MARK: - CLLocationManagerDelegate
extension RootPresenter: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.last.flatMap { locationPublisher.send(.value($0)) }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkPermissions(using: manager)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let alertModel = AlertModel(title: "Error",
                                    subtitle: error.localizedDescription,
                                    actions: [.init(title: "OK", style: .default)])
        alertPublisher.send(alertModel)
    }
}
