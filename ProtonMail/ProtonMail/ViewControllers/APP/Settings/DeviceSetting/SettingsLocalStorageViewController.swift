// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import CoreGraphics

class SettingsLocalStorageViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel: SettingsLocalStorageViewModel!
    internal var coordinator: SettingsDeviceCoordinator?
    
    struct Key {
        static let cellHeight: CGFloat = 144.0
        static let footerHeight: CGFloat = 48.0
        static let headerCell: String = "header_cell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateTitle()
        
        self.view.backgroundColor = ColorProvider.BackgroundSecondary
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(LocalStorageTableViewCell.self)
        
        self.tableView.estimatedSectionFooterHeight = Key.footerHeight
        self.tableView.sectionFooterHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = Key.cellHeight
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    func set(coordinator: SettingsDeviceCoordinator) {
        self.coordinator = coordinator
    }
    
    func set(viewModel: SettingsLocalStorageViewModel) {
        self.viewModel = viewModel
    }
    
    private func updateTitle() {
        self.title = "Local storage"
    }
}

extension SettingsLocalStorageViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let section = indexPath.section
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .cachedData:
            let cell = tableView.dequeueReusableCell(withIdentifier: LocalStorageTableViewCell.CellID, for: indexPath)
            if let localStorageCell = cell as? LocalStorageTableViewCell {
                localStorageCell.configCell(eSection.title, "middle line", "bottom line"){
                    //TODO button action
                }
            }
            return cell
        case .attachments:
            let cell = tableView.dequeueReusableCell(withIdentifier: LocalStorageTableViewCell.CellID, for: indexPath)
            if let localStorageCell = cell as? LocalStorageTableViewCell {
                localStorageCell.configCell(eSection.title, "middle line", "bottom line"){
                    //TODO button action
                }
            }
            return cell
        case .downloadedMessages:
            let cell = tableView.dequeueReusableCell(withIdentifier: LocalStorageTableViewCell.CellID, for: indexPath)
            if let localStorageCell = cell as? LocalStorageTableViewCell {
                localStorageCell.configCell(eSection.title, "middle line", "bottom line"){
                    
                }
            }
            return cell
        }
    }
}
