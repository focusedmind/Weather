//
//  ViewController.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import UIKit
import Combine
import CoreLocation

class RootController: UIPageViewController {
    
    private lazy var presenter = RootPresenter()
    private lazy var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        dataSource = self
        setupPresenter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.handleViewWillAppear()
    }
    
    private func setupPresenter() {
        presenter
            .alertPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] model in self?.displayAlert(with: model) })
            .store(in: &cancellables)
    }
    
    func displayAlert(with model: AlertModel) {
        let alert = UIAlertController(title: model.title, message: model.subtitle, preferredStyle: .alert)
        model.actions.forEach(alert.addAction(_:))
        present(alert, animated: true)
    }
}

extension RootController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        nil
    }
}

