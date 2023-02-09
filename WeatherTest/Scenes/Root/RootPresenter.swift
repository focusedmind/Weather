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
}

class RootPresenter: NSObject {
    
    private let locationManager = CLLocationManager()
    private var settings: Settings = UserDefaults.standard
    private var hasPermissionsBeenCheckedOnAppear = false
    private var notificatonCancellable: AnyCancellable? = nil
    let alertPublisher = PassthroughSubject<AlertModel, Never>()
    let locationPublisher = CurrentValueSubject<LocationState, Never>(.waiting)
    
    override init() {
        super.init()
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
    
    func handleCurrentLocationRequest() {
        checkPermissions(using: locationManager)
    }
}

// MARK: - RootPresenterProtocol
extension RootPresenter: RootPresenterProtocol {
    
    func handleTriggeredAlert(with model: AlertModel) { alertPublisher.send(model) }
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
        let alertModel = AlertModel(title: NSLocalizedString("general.error", comment: ""),
                                    subtitle: error.localizedDescription,
                                    actions: [.init(title: "general.ok", style: .default)])
        alertPublisher.send(alertModel)
    }
}
