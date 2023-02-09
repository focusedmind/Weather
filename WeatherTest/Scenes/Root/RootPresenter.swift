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

protocol RootPresenterProtocol: AnyObject {
    var locationPublisher: PassthroughSubject<CLLocation?, Never> { get }
    
    func handleTriggeredAlert(with model: AlertModel)
}

class RootPresenter: NSObject {
    
    private let locationManager = CLLocationManager()
    private var settings: Settings = UserDefaults.standard
    private var hasPermissionsBeenCheckedOnAppear = false
    let alertPublisher = PassthroughSubject<AlertModel, Never>()
    let locationPublisher = PassthroughSubject<CLLocation?, Never>()
    
    override init() {
        super.init()
        locationManager.delegate = self
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
            let openSettingsAction = UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
                if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            })
            let continueWithLowAccuracy = UIAlertAction(title: "Continue with low accuracy", style: .default, handler: { [weak self] _ in
                self?.settings.isLowAccuracyModeEnabled = true
                self?.locationPublisher.send(nil)
            })
            let alertModel = AlertModel(title: "Warning",
                                        subtitle: "Warning",
                                        actions: [openSettingsAction, continueWithLowAccuracy])
            alertPublisher.send(alertModel)
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            break
        }
    }
}

// MARK: - RootPresenterProtocol
extension RootPresenter: RootPresenterProtocol {
    
    func handleTriggeredAlert(with model: AlertModel) { alertPublisher.send(model) }
}

// MARK: - CLLocationManagerDelegate
extension RootPresenter: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.last.flatMap(locationPublisher.send)
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
