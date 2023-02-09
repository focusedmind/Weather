//
//  WeatherPresenter.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import Foundation
import Combine
import CoreLocation

class WeatherPresenter: NSObject {
    
    private weak var delegate: RootPresenterProtocol?
    private let isCurrent: Bool
    private let location: CLLocation?
    
    init(isCurrent: Bool, location: CLLocation?, delegate: RootPresenterProtocol) {
        self.isCurrent = isCurrent
        self.location = location
        self.delegate = delegate
    }
    
    func loadData() {
        
    }
}
