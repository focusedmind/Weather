//
//  SearchResultsTableViewController.swift
//  WeatherTest
//
//  Created by iOS Developer on 2/10/23.
//

import UIKit
import Combine

class SearchResultsTableViewController: UITableViewController {
    
    struct LocationCellModel: Identifiable {
        var id: Int { [location.lat, location.lon, isStored ? 1 : 0].hashValue }
        
        let location: LocationEntity
        var isStored: Bool
    }
    
    private let searchGateway: LocationsGateway
    private let localGateway: LocalGateway
    private weak var delegate: RootPresenterProtocol?
    private let cellId = "locationCellID"
    private var cellModels = [LocationCellModel]() { didSet { tableView.reloadData() } }
    private let inputPublisher = PassthroughSubject<String, Error>()
    private var fetchCancellable: AnyCancellable?
    
    init(searchGateway: LocationsGateway, localGateway: LocalGateway, delegate: RootPresenterProtocol?) {
        self.searchGateway = searchGateway
        self.localGateway = localGateway
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        setupFetcher()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)
        tableView.allowsSelection = false
    }
    
    func handleEnterSearch(phrase: String) {
        if !phrase.isEmpty {
            inputPublisher.send(phrase)
        } else {
            cellModels = []
        }
    }
    
    @objc private func handleAddButtonTap(_ button: UIButton) {
        guard !cellModels[button.tag].isStored else {
            assertionFailure("Location is already stored")
            return
        }
        cellModels[button.tag].isStored = true
        tableView.beginUpdates()
        tableView.reloadRows(at: [.init(row: button.tag, section: 0)], with: .none)
        tableView.endUpdates()
        delegate?.handleNewLocationAdded(entity: cellModels[button.tag].location)
        setupFetcher()
    }
    
    private func setupFetcher() {
        fetchCancellable = inputPublisher
            .debounce(for: 0.64, scheduler: DispatchQueue.main)
            .flatMap(self.searchGateway.locationsPublisher(for:))
            .combineLatest(localGateway.storedLocationsPublisher())
            .map { searchResult, storedLocations in
                searchResult.map { location in
                    LocationCellModel(location: location,
                                      isStored: storedLocations.contains(where: { $0.coordinatesHash == location.coordinatesHash }))
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] models in self?.cellModels = models })
    }
}

// MARK: - Table view data source
extension SearchResultsTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cellModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellId, for: indexPath)
        let model = cellModels[indexPath.row]
        cell.textLabel?.text = [model.location.name, model.location.region].joined(separator: ", ")
        cell.detailTextLabel?.text = model.location.country
        if !model.isStored {
            let button = UIButton(type: .contactAdd)
            button.addTarget(self, action: #selector(handleAddButtonTap), for: .touchUpInside)
            button.tag = indexPath.row
            cell.accessoryView = button
        } else {
            cell.accessoryView = nil
        }
        return cell
    }
}
