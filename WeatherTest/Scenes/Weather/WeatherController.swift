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
    private lazy var measurementFormatter = MeasurementFormatter()
    
    init(presenter: WeatherPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupUI()
        setupSearchButton()
        bindToPresenter()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.handleViewWillAppear()
    }
    
    private func bindToPresenter() {
        presenter.weatherSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] weather in weather.flatMap { self?.configure(for: $0) } }
            .store(in: &cancellables)
    }
    
    private func configure(for weatherEntity: WeatherResponseEntity) {
        locationLabel.text = [weatherEntity.location.name,
                              weatherEntity.location.region,
                              weatherEntity.location.country].joined(separator: ", ")
        let tempMeasurement = Measurement(value: weatherEntity.current.tempC, unit: UnitTemperature.celsius)
        temperatureLabel.text = measurementFormatter.string(from: tempMeasurement)
        humidityLabel.text = NumberFormatter.localizedString(from: .init(value: weatherEntity.current.humidity / 100), number: .percent)
        activityIndicator.stopAnimating()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        self.activityIndicator = activityIndicatorView
        view.addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        let stackView = UIStackView()
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.layoutMargins = .init(top: 16, left: 8, bottom: 16, right: 8)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        [stackView].forEach { subView in
            view.addSubview(subView)
            NSLayoutConstraint.activate([
                view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: subView.leadingAnchor),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: subView.trailingAnchor),
                view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: subView.topAnchor),
                view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: subView.bottomAnchor)
           ])
        }
        
        let locationLabel = UILabel()
        locationLabel.font = .preferredFont(forTextStyle: .largeTitle)
        locationLabel.numberOfLines = 0
        self.locationLabel = locationLabel
        let temperatureLabel = UILabel()
        temperatureLabel.font = .preferredFont(forTextStyle: .title2)
        self.temperatureLabel = temperatureLabel
        let humidityLabel = UILabel()
        humidityLabel.font = .preferredFont(forTextStyle: .title3)
        self.humidityLabel = humidityLabel
        let emptyView = UIView()
        emptyView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        emptyView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        [locationLabel, temperatureLabel, humidityLabel, emptyView].forEach(stackView.addArrangedSubview(_:))
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

