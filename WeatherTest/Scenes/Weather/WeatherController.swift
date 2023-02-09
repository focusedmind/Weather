//
//  WeatherController.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/9/23.
//

import UIKit
import Combine

class WeatherController: UIViewController {
    
    private let presenter: WeatherPresenter
    private lazy var cancellables = Set<AnyCancellable>()
    private weak var imageView: UIImageView!
    private weak var locationLabel, temperatureLabel, humidityLabel: UILabel!
    private weak var activityIndicator: UIActivityIndicatorView!
    
    
    init(presenter: WeatherPresenter) {
        self.presenter = presenter
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        setupPresenter()
        setupSearchButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.layoutMargins = .init(top: 16, left: 8, bottom: 16, right: 8)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            view.topAnchor.constraint(equalTo: stackView.topAnchor),
            view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
        
        let locationLabel = UILabel()
        locationLabel.font = .preferredFont(forTextStyle: .largeTitle)
        self.locationLabel = locationLabel
        let temperatureLabel = UILabel()
        temperatureLabel.font = .preferredFont(forTextStyle: .title2)
        self.temperatureLabel = temperatureLabel
        let humidityLabel = UILabel()
        humidityLabel.font = .preferredFont(forTextStyle: .title3)
        self.humidityLabel = humidityLabel
        [locationLabel, temperatureLabel, humidityLabel].forEach(stackView.addArrangedSubview(_:))
    }
    
    private func setupSearchButton() {
        let searchButton = UIBarButtonItem(systemItem: .search)
        searchButton.target = self
        searchButton.action = #selector(handleSearchButtonTap)
        navigationItem.setRightBarButton(searchButton, animated: false)
    }
    
    @objc private func handleSearchButtonTap(_ button: UIBarButtonItem) {
        
    }
}

