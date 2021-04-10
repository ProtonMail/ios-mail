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

import PMUIFoundations
import UIKit

class SettingsContactCombineViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel: SettingsCombineContactViewModel!
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

    func set(viewModel: SettingsCombineContactViewModel) {
        self.viewModel = viewModel
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
                switchCell.configCell(eSection.title, bottomLine: "", status: viewModel.isContactCombined) { _, _, _ in
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
        header?.contentView.backgroundColor = UIColorManager.BackgroundSecondary

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
