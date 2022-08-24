//
//  SettingsSwipeActionSelectController.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.
//

import MBProgressHUD
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
            if viewModel?.isActionSyncable(selectedAction) == true {
                MBProgressHUD.showAdded(to: self.view, animated: true)
            }
            viewModel?.updateSwipeAction(selectedAction, completion: { [weak self] in
                guard let self = self else { return }
                MBProgressHUD.hide(for: self.view, animated: true)
                tableView.reloadData()
            })
        }
    }
}
