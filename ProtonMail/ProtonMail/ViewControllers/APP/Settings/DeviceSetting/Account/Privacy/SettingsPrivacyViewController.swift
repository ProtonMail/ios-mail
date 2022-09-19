//
//  SettingsPrivacyViewController.swift
//  Proton Mail - Created on 3/17/15.
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

import MBProgressHUD
import ProtonCore_DataModel
import ProtonCore_UIFoundations
import UIKit

class SettingsPrivacyViewController: UITableViewController {
    private let viewModel: SettingsPrivacyViewModel
    private let coordinator: SettingsPrivacyCoordinator

    init(viewModel: SettingsPrivacyViewModel, coordinator: SettingsPrivacyCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator

        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    struct Key {
        static let headerCell: String = "header_cell"
        static let headerCellHeight: CGFloat = 36.0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundView = nil
        self.tableView.backgroundColor = ColorProvider.BackgroundSecondary
        self.updateTitle()
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(SwitchTableViewCell.self)
        self.tableView.tableFooterView = UIView()

        self.tableView.rowHeight = UITableView.automaticDimension
    }

    private func updateTitle() {
        self.title = LocalString._privacy
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    // MARK: - tableView delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.privacySections.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let item = self.viewModel.privacySections[row]

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SwitchTableViewCell.CellID,
            for: indexPath
        ) as? SwitchTableViewCell else {
            fatalError("Invalid tableView configuration")
        }

        cell.backgroundColor = ColorProvider.BackgroundNorm
        switch item {
        case .autoLoadRemoteContent:
            configureAutoLoadImageCell(cell, item, .remote)
        case .autoLoadEmbeddedImage:
            configureAutoLoadImageCell(cell, item, .embedded)
        case .linkOpeningMode:
            configureLinkOpeningModeCell(cell, item)
        case .metadataStripping:
            cell.configCell(item.description, isOn: viewModel.isMetadataStripping) { newStatus, _ in
                self.viewModel.isMetadataStripping = newStatus
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Key.headerCellHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SettingsPrivacyViewController {
    private func configureAutoLoadImageCell(_ cell: SwitchTableViewCell,
                                            _ item: SettingPrivacyItem,
                                            _ flag: ShowImages) {
        let isOn = viewModel.userInfo.showImages.contains(flag)

        configureCell(cell, item, isOn: isOn) { newStatus, completion in
            self.viewModel.updateAutoLoadImageStatus(flag: flag, newStatus: newStatus, completion: completion)
        }
    }

    private func configureLinkOpeningModeCell(_ cell: SwitchTableViewCell, _ item: SettingPrivacyItem) {
        let isOn = viewModel.userInfo.linkConfirmation == .confirmationAlert

        configureCell(cell, item, isOn: isOn) { newStatus, completion in
            self.viewModel.updateLinkConfirmation(newStatus: newStatus, completion: completion)
        }
    }

    private func configureCell(_ cell: SwitchTableViewCell,
                               _ item: SettingPrivacyItem,
                               isOn: Bool,
                               action: @escaping (_ newStatus: Bool, _ completion: @escaping (NSError?) -> Void) -> Void
    ) {
        cell.configCell(item.description, isOn: isOn) { newStatus, feedback in
            let view = UIApplication.shared.keyWindow ?? UIView()
            MBProgressHUD.showAdded(to: view, animated: true)

            action(newStatus) { error in
                MBProgressHUD.hide(for: view, animated: true)
                if let error = error {
                    feedback(false)
                    error.alertToast()
                } else {
                    feedback(true)
                }
            }
        }
    }
}
