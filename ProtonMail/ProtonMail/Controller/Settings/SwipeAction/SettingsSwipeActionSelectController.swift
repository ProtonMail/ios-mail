//
//  SettingsSwipeActionSelectController.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
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
//

import UIKit

class SettingsSwipeActionSelectController: UITableViewController, ViewModelProtocol {
    private var viewModel: SettingsSwipeActionSelectViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SelectableTableViewCell.self)
        tableView.rowHeight = 64.0
        tableView.separatorStyle = .none

        precondition(viewModel != nil)

        title = viewModel?.selectedAction.description
    }

    func set(viewModel: SettingsSwipeActionSelectViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.settingSwipeActions.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectableTableViewCell.CellID, for: indexPath)
        cell.addSeparator(padding: 0)

        if let cellToConfig = cell as? SelectableTableViewCell,
           let action = viewModel?.settingSwipeActions[indexPath.row] {
            cellToConfig.configure(icon: action.icon,
                                   title: action.description,
                                   isSelected: action == viewModel?.currentAction())
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedAction = viewModel?.settingSwipeActions[indexPath.row] {
            viewModel?.updateSwipeAction(selectedAction)
            tableView.reloadData()
        }
    }
}
