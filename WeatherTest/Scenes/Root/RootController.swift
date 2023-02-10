//
//  RootController.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import UIKit
import Combine
import CoreLocation

class RootController: UIPageViewController {
    
    private lazy var presenter = RootPresenter(networkGateway: NetworkWeatherGateway(), localGateway: LocalWeatherGateway())
    private lazy var cancellables = Set<AnyCancellable>()
    private weak var searchResultsController: SearchResultsTableViewController!
    private weak var currentVC: WeatherController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        dataSource = self
        delegate = self
        bindToPresenter()
        navigationController?.view.backgroundColor = .systemBackground
        setupSearchButton()
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.handleViewWillAppear()
    }
    
    private func bindToPresenter() {
        presenter
            .alertPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] model in self?.displayAlert(with: model) })
            .store(in: &cancellables)
        presenter
            .$pagePresenters
            .sink(receiveValue: { [weak self] presenters in
                guard let self else { return }
                let controllers: [UIViewController]
                if let vc = self.currentVC, presenters.isEmpty {
                    controllers = [vc]
                } else {
                    controllers = [presenters.first.flatMap(WeatherController.init(presenter:))]
                        .compactMap({ $0 })
                    self.currentVC = controllers.first as? WeatherController
                }
                self.setViewControllers(controllers, direction: .forward, animated: false)
            })
            .store(in: &cancellables)
    }
    
    private func setupSearchButton() {
        let searchButton = UIBarButtonItem(systemItem: .search)
        searchButton.target = self
        searchButton.action = #selector(handleSearchButtonTap)
        navigationItem.setRightBarButton(searchButton, animated: false)
    }
    
    private func setupSearchController() {
        let resultsViewController = SearchResultsTableViewController(searchGateway: presenter.networkGateway,
                                                                     localGateway: presenter.localGateway,
                                                                     delegate: presenter)
        self.searchResultsController = resultsViewController
        let searchController = UISearchController(searchResultsController: resultsViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchTextField.placeholder = "Enter location name"
        searchController.searchBar.returnKeyType = .done
        searchController.searchBar.becomeFirstResponder()
        searchController.searchBar.layer.opacity = 0
        UIView.animate(withDuration: 0.3) {
            searchController.searchBar.layer.opacity = 1
        }
        searchController.searchBar.searchTextField.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.05)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.delegate = self
    }
    
    private func displayAlert(with model: AlertModel) {
        let alert = UIAlertController(title: model.title, message: model.subtitle, preferredStyle: .alert)
        model.actions.forEach(alert.addAction(_:))
        present(alert, animated: true)
    }
    
    @objc private func handleSearchButtonTap() {
        UIView.animate(withDuration: 0.2,
                       animations: {
            self.currentVC?.view.layer.opacity = 0
        }, completion: { _ in
            self.setupSearchController()
        })
    }
}

extension RootController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let weatherVC = viewController as? WeatherController else {
            assertionFailure("Unexpected type of view controller: \(String(describing: type(of: viewController)))")
            return nil
        }
        if let index = presenter.pagePresenters.firstIndex(where: { $0.id == weatherVC.presenter.id }), index > 0 {
            return WeatherController(presenter: presenter.pagePresenters[index - 1])
        } else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let weatherVC = viewController as? WeatherController else {
            assertionFailure("Unexpected type of view controller: \(String(describing: type(of: viewController)))")
            return nil
        }
        if let index = presenter.pagePresenters.firstIndex(where: { $0.id == weatherVC.presenter.id }),
            index < presenter.pagePresenters.count - 1 {
            return WeatherController(presenter: presenter.pagePresenters[index + 1])
        } else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            currentVC = viewControllers?.first as? WeatherController
        }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        presenter.pagePresenters.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        if let currentVC, let index = presenter.pagePresenters.firstIndex(of: currentVC.presenter) {
            return index
        } else {
            return 0
        }
    }
}

extension RootController: UISearchControllerDelegate, UISearchResultsUpdating {
    
    func presentSearchController(_ searchController: UISearchController) {
        searchController.showsSearchResultsController = true
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        navigationItem.searchController = nil
        currentVC?.view.layer.opacity = 1
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        searchResultsController.handleEnterSearch(phrase: searchController.searchBar.text ?? "")
    }
}
