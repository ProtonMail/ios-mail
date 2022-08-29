//
//  SettingsEncryptedSearchViewController.swift
//  ProtonMail - Created on 2021/7/1.
//
//
//  Copyright © 2021 ProtonMail. All rights reserved.
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class SettingsEncryptedSearchViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel: SettingsEncryptedSearchViewModel!
    internal var coordinator: SettingsDeviceCoordinator?
    
    struct Key {
        static let cellHeight: CGFloat = 48.0
        
        static let headerCell: String = "header_cell"
    }
    
    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.view.backgroundColor = UIColorManager.BackgroundSecondary
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(SwitchTableViewCell.self)
        
        self.tableView.estimatedSectionFooterHeight = 36.0
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
    
    func set(viewModel: SettingsEncryptedSearchViewModel) {
        self.viewModel = viewModel
    }
    
    private func updateTitle(){
        self.title = LocalString._encrypted_search
    }
}

extension SettingsEncryptedSearchViewController {
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
        case .encryptedSearch:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.CellID, for: indexPath)
            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.configCell(eSection.title, bottomLine: "", status: viewModel.isEncryptedSearch) {
                    _, _, _ in
                    let status = self.viewModel.isEncryptedSearch
                    self.viewModel.isEncryptedSearch = !status
                    
                    //If cell is active -> start building a search index
                    if self.viewModel.isEncryptedSearch {
                        //TODO check return value
                        var returnValue: Bool = false
                        returnValue = EncryptedSearchService.shared.buildSearchIndex(self.viewModel)
                        
                        //set or reset toggle switch according to successfull indexing
                        self.viewModel.isEncryptedSearch = returnValue
                    }
                }
            }
            return cell
        }
    }
    
    /*override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach {
            $0.removeFromSuperview()
        }
        header?.contentView.backgroundColor = UIColorManager.BackgroundSecondary
        
        if let headerCell = header {
            let textLabel = UILabel()
            textLabel.numberOfLines = 0
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let eSection = self.viewModel.sections[section]
            textLabel.attributedText = NSAttributedString(string: eSection.foot, attributes: FontManager.CaptionWeak)
            
            NSLayoutConstraint.activate([
                textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 8),
                textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8),
                textLabel.leadingAnchor.constraint(equalTo: headerCell.contentView.leadingAnchor, constant: 16),
                textLabel.trailingAnchor.constraint(equalTo: headerCell.contentView.trailingAnchor, constant: -16)
            ])
        }
        return header
    }*/
}
