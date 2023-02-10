//
//  Settings.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import Foundation

protocol Settings: AnyObject {
    
    var hasLocationServicesDisabledAlertPresented: Bool { get set }
    var hasLocationServicesDeniedAlertPresented: Bool { get set }
    var isLowAccuracyModeEnabled: Bool { get set }
}

extension UserDefaults: Settings {
    
    enum Constants {
        static var locationDisabledAlertKey = "kLocationDisabledAlert"
        static var locationDeniedAlertKey = "kLocationDeniedAlert"
        static var lowAccuracyModeEnabledKey = "kLowAccuracyModeEnabled"
    }
    
    var hasLocationServicesDisabledAlertPresented: Bool {
        get { bool(forKey: Constants.locationDisabledAlertKey) }
        set { setValue(newValue, forKey: Constants.locationDisabledAlertKey) }
    }
    
    var hasLocationServicesDeniedAlertPresented: Bool {
        get { bool(forKey: Constants.locationDeniedAlertKey) }
        set { setValue(newValue, forKey: Constants.locationDeniedAlertKey) }
    }
    
    var isLowAccuracyModeEnabled: Bool {
        get { bool(forKey: Constants.lowAccuracyModeEnabledKey) }
        set { setValue(newValue, forKey: Constants.lowAccuracyModeEnabledKey) }
    }
}
