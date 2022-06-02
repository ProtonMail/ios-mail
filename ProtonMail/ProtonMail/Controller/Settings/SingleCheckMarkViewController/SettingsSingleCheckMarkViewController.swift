// Copyright (c) 2022 Proton AG
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

import MBProgressHUD
import ProtonCore_UIFoundations
import UIKit

extension SettingsSingleCheckMarkViewController {
    private enum Key {
        static let headerCell: String = "header_cell"
        static let cell: String = "select_cell"
    }
}

final class SettingsSingleCheckMarkViewController: UITableViewController {

    private let viewModel: SettingsSingleCheckMarkVMProtocol

    init(viewModel: SettingsSingleCheckMarkVMProtocol) {
        self.viewModel = viewModel
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        self.viewModel.sectionNumber
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.viewModel.rowNumber
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Key.cell, for: indexPath)
        cell.backgroundColor = ColorProvider.BackgroundNorm
        if let title = viewModel.cellTitle(of: indexPath) {
            cell.textLabel?.attributedText = title.apply(style: FontManager.Default)
            if viewModel.cellShouldShowSelection(of: indexPath) {
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
        viewModel.selectItem(indexPath: indexPath)
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let text = self.viewModel.sectionHeader(of: section) else {
            return nil
        }
        let padding = self.viewModel.headerTopPadding
        return self.getHeaderFooterView(text: text,
                                        titleTopPadding: padding)
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let text = self.viewModel.sectionFooter(of: section) else {
            return nil
        }
        let padding = self.viewModel.footerTopPadding
        return self.getHeaderFooterView(text: text,
                                        titleTopPadding: padding)
    }
}

// MARK: UI related
extension SettingsSingleCheckMarkViewController {
    private func setupUI() {
        self.title = self.viewModel.title
        self.setupTableView()
    }

    private func setupTableView() {
        tableView.backgroundView = nil
        tableView.backgroundColor = ColorProvider.BackgroundSecondary
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: Key.cell)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 36.0
        tableView.sectionHeaderHeight = self.viewModel.headerHeight
        tableView.estimatedSectionFooterHeight = 36.0
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.separatorInset = .zero
    }

    private func getHeaderFooterView(text: NSAttributedString, titleTopPadding: CGFloat) -> UIView? {
        guard let hfView = tableView
            .dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell) else {
            return nil
        }
        hfView.contentView.backgroundColor = ColorProvider.BackgroundSecondary
        hfView.contentView.subviews.forEach { $0.removeFromSuperview() }

        let textLabel = UILabel(attributedString: text)
        textLabel.numberOfLines = 0
        hfView.contentView.addSubview(textLabel)

        [
            textLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 20.0),
            textLabel.topAnchor.constraint(equalTo: hfView.contentView.topAnchor, constant: titleTopPadding),
            textLabel.bottomAnchor.constraint(equalTo: hfView.contentView.bottomAnchor, constant: -8),
            textLabel.leftAnchor.constraint(equalTo: hfView.contentView.leftAnchor, constant: 16),
            textLabel.rightAnchor.constraint(equalTo: hfView.contentView.rightAnchor, constant: -16)
        ].activate()
        return hfView
    }
}

extension SettingsSingleCheckMarkViewController: SettingsSingleCheckMarkUIProtocol {
    func show(error: String) {
        error.alertToastBottom()
    }

    func reloadTable() {
        self.tableView.reloadData()
    }

    func showLoading(shouldShow: Bool) {
        if shouldShow {
            MBProgressHUD.showAdded(to: self.view, animated: true)
        } else {
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
}
