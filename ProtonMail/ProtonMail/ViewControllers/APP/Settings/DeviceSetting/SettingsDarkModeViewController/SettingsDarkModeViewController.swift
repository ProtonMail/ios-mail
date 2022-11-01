// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

class SettingsDarkModeViewController: UITableViewController {
    private enum Key {
        static let headerCell: String = "header_cell"
        static let cell: String = "select_cell"
    }

    let viewModel: SettingsDarkModeViewModel

    init(viewModel: SettingsDarkModeViewModel) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = LocalString._dark_mode
        tableView.backgroundView = nil
        tableView.backgroundColor = ColorProvider.BackgroundSecondary
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Key.cell)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        tableView.tableFooterView = UIView()
        tableView.rowHeight = 48.0
        tableView.estimatedSectionHeaderHeight = 36.0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = 36.0
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.separatorInset = .zero
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Key.cell, for: indexPath)
        cell.backgroundColor = ColorProvider.BackgroundNorm
        if let title = viewModel.getCellTitle(of: indexPath) {
            cell.textLabel?.attributedText = title.apply(style: FontManager.Default)
            cell.tintColor = ColorProvider.BrandNorm
            if viewModel.getCellShouldShowSelection(of: indexPath) {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }
        viewModel.updateDarkModeStatus(to: viewModel.getDarkModeStatus(for: indexPath))
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.backgroundColor = ColorProvider.BackgroundSecondary
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }

        if let headerCell = header {
            let textLabel = UILabel()

            let textAttribute = FontManager.DefaultSmallWeak.alignment(.left)
            textLabel.attributedText = NSAttributedString(string: LocalString._settings_dark_mode_section_title,
                                                          attributes: textAttribute)
            textLabel.translatesAutoresizingMaskIntoConstraints = false

            headerCell.contentView.addSubview(textLabel)

            NSLayoutConstraint.activate([
                textLabel.heightAnchor.constraint(equalToConstant: 20.0),
                textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 24),
                textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8),
                textLabel.leftAnchor.constraint(equalTo: headerCell.contentView.leftAnchor, constant: 16),
                textLabel.rightAnchor.constraint(equalTo: headerCell.contentView.rightAnchor, constant: -8)
            ])
        }
        return header
    }

    required init?(coder: NSCoder) {
        nil
    }
}
