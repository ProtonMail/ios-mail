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
import UIKit

class SettingsEncryptedSearchDownloadedMessagesViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel: SettingsEncryptedSearchDownloadedMessagesViewModel!
    internal var coordinator: SettingsDeviceCoordinator?
    
    struct Key  {
        static let cellHeight: CGFloat = 48.0
        static let footerHeight: CGFloat = 48.0
        static let headerCell: String = "header_cell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateTitle()
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        label.center = CGPoint(x: 160, y: 285)
        label.textAlignment = .center
        label.text = LocalString._encrypted_search_downloaded_messages_explanation
        self.view.addSubview(label)
        
        self.view.backgroundColor = UIColorManager.BackgroundSecondary
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(ProgressBarButtonTableViewCell.self)
        self.tableView.register(ButtonTableViewCell.self)
        self.tableView.register(SliderTableViewCell.self)
        
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
    
    func set(viewModel: SettingsEncryptedSearchDownloadedMessagesViewModel) {
        self.viewModel = viewModel
    }
    
    private func updateTitle() {
        self.title = LocalString._encrypted_search_downloaded_messages
    }
}

extension SettingsEncryptedSearchDownloadedMessagesViewController {
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
        case .messageHistory:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProgressBarButtonTableViewCell.CellID, for: indexPath)
            return cell
        case .storageLimit:
            let cell = tableView.dequeueReusableCell(withIdentifier: SliderTableViewCell.CellID, for: indexPath)
            return cell
        case .storageUsage:
            let cell = tableView.dequeueReusableCell(withIdentifier: ButtonTableViewCell.CellID, for: indexPath)
            if let buttonCell = cell as? ButtonTableViewCell {
                let sizeOfIndex: String = "5" //EncryptedSearchIndexService.shared.getSizeOfSearchIndex(for: "userid here")
                let storageLimit: Float = self.viewModel.storageLimit
                let bottomLine = String(sizeOfIndex) + "MB of " + String(storageLimit) + " GB"
                buttonCell.configCell(LocalString._settings_title_of_storage_usage, bottomLine, "Clear")
            }
            return cell
        }
    }
}
