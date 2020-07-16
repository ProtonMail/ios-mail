//
//  SettingsContactCombineViewController.swift
//  ProtonMail - Created on 2020/4/27.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import UIKit

class SettingsContactCombineViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel: SettingsCombineContactViewModel!
    internal var coordinator: SettingsDeviceCoordinator?
    
    struct Key {
        static let cellHeight: CGFloat = 44.0
        
        static let headerCell: String = "header_cell"
        static let switchCell: String = "switch_table_view_cell"
    }
    
    //MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        
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
    
    func set(viewModel: SettingsCombineContactViewModel) {
        self.viewModel = viewModel
    }
    
    private func updateTitle() {
        self.title = LocalString._combined_contacts
    }
}

extension SettingsContactCombineViewController {
    //MARK: Tableview setup
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .combineContact:
            let cell = tableView.dequeueReusableCell(withIdentifier: Key.switchCell, for: indexPath)
            cell.accessoryType = UITableViewCell.AccessoryType.none
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            
            
            if let c = cell as? SwitchTableViewCell {
                c.configCell(eSection.title, bottomLine: "", status: self.viewModel.isContactCombined) { (cell, newStatus, feedback) in
                    
                    let status = self.viewModel.isContactCombined
                    self.viewModel.isContactCombined = !status
                }
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        if let headerCell = header {
            let textLabel = UILabel()
            
            textLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            textLabel.adjustsFontForContentSizeCategory = true
            textLabel.numberOfLines = 0
            textLabel.textColor = UIColor.ProtonMail.Gray_8E8E8E
            let eSection = self.viewModel.sections[section]
            textLabel.text = eSection.foot
            
            headerCell.contentView.addSubview(textLabel)
            
            textLabel.mas_makeConstraints({ (make) in
                let _ = make?.top.equalTo()(headerCell.contentView.mas_top)?.with()?.offset()(8)
                let _ = make?.bottom.equalTo()(headerCell.contentView.mas_bottom)?.with()?.offset()(-8)
                let _ = make?.left.equalTo()(headerCell.contentView.mas_left)?.with()?.offset()(8)
                let _ = make?.right.equalTo()(headerCell.contentView.mas_right)?.with()?.offset()(-8)
            })
        }
        return header
    }
}
