//
//  SettingsContactCombineViewController.swift
//  Proton Mail - Created on 2020/4/27.
//
//
//  Copyright (c) 2019 Proton AG
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

import ProtonCore_UIFoundations
import UIKit

class SettingsContactCombineViewController: ProtonMailTableViewController {
    private let viewModel: SettingsCombineContactViewModel

    struct Key {
        static let cellHeight: CGFloat = 48.0

        static let headerCell: String = "header_cell"
    }

    init(viewModel: SettingsCombineContactViewModel, coordinator: SettingsDeviceCoordinator) {
        self.viewModel = viewModel

        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateTitle()
        self.view.backgroundColor = ColorProvider.BackgroundSecondary
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(SwitchTableViewCell.self)

        self.tableView.estimatedSectionFooterHeight = 36.0
        self.tableView.sectionFooterHeight = UITableView.automaticDimension

        self.tableView.estimatedRowHeight = Key.cellHeight
        self.tableView.rowHeight = UITableView.automaticDimension
    }

    private func updateTitle() {
        self.title = LocalString._combined_contacts
    }
}

extension SettingsContactCombineViewController {
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
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.CellID, for: indexPath)

            if let switchCell = cell as? SwitchTableViewCell {
                switchCell.configCell(eSection.title, status: viewModel.isContactCombined) { _, _, _ in
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
        header?.contentView.backgroundColor = ColorProvider.BackgroundSecondary

        if let headerCell = header {
            let textLabel = UILabel()
            textLabel.numberOfLines = 0
            textLabel.translatesAutoresizingMaskIntoConstraints = false

            let eSection = self.viewModel.sections[section]
            textLabel.attributedText = NSAttributedString(string: eSection.foot, attributes: FontManager.CaptionWeak)

            headerCell.contentView.addSubview(textLabel)

            NSLayoutConstraint.activate([
                textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 8),
                textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8),
                textLabel.leadingAnchor.constraint(equalTo: headerCell.contentView.leadingAnchor, constant: 16),
                textLabel.trailingAnchor.constraint(equalTo: headerCell.contentView.trailingAnchor, constant: -16)
            ])
        }
        return header
    }
}
