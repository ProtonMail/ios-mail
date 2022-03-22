//
//  SettingsPrivacyViewController.swift
//  ProtonMail - Created on 3/17/15.
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

    @IBOutlet private var settingTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundView = nil
        self.tableView.backgroundColor = ColorProvider.BackgroundSecondary
        self.updateTitle()
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(SettingsGeneralCell.self)
        self.tableView.register(SwitchTableViewCell.self)
        self.tableView.tableFooterView = UIView()

        self.tableView.rowHeight = 48.0
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
        let cell = tableView.dequeueReusableCell(withIdentifier: SwitchTableViewCell.CellID, for: indexPath)
        cell.backgroundColor = ColorProvider.BackgroundNorm
        switch item {
        case .autoLoadRemoteContent:
            configureAutoLoadImageCell(cell, item, tableView, indexPath)
        case .autoLoadEmbeddedImage:
            configureAutoLoadEmbeddedImageCell(cell, item, tableView, indexPath)
        case .linkOpeningMode:
            configureLinkOpeningModeCell(cell, item, tableView, indexPath)
        case .metadataStripping:
            if let cellToUpdate = cell as? SwitchTableViewCell {
                cellToUpdate.configCell(item.description,
                                        bottomLine: "",
                                        status: viewModel.isMetadataStripping) { _, newStatus, _ in
                    self.viewModel.isMetadataStripping = newStatus
                }
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
    private func configureAutoLoadImageCell(_ cell: UITableViewCell,
                                            _ item: SettingPrivacyItem,
                                            _ tableView: UITableView,
                                            _ indexPath: IndexPath) {
        if let cellToUpdate = cell as? SwitchTableViewCell {
            cellToUpdate.configCell(item.description,
                                    bottomLine: "",
                                    status: viewModel.userInfo.showImages.contains(.remote),
                                    complete: { (_, newStatus, feedback: @escaping SwitchTableViewCell.ActionStatus) -> Void in
                                        if let indexp = tableView.indexPath(for: cellToUpdate), indexPath == indexp {
                                            let view = UIApplication.shared.keyWindow ?? UIView()
                                            MBProgressHUD.showAdded(to: view, animated: true)

                                            self.viewModel.updateAutoLoadImageStatus(newStatus: newStatus) { error in
                                                MBProgressHUD.hide(for: view, animated: true)
                                                if let error = error {
                                                    feedback(false)
                                                    error.alertToast()
                                                } else {
                                                    feedback(true)
                                                }
                                            }
                                        } else {
                                            feedback(false)
                                        }
                                    })
        }
    }

    private func configureAutoLoadEmbeddedImageCell(_ cell: UITableViewCell,
                                            _ item: SettingPrivacyItem,
                                            _ tableView: UITableView,
                                            _ indexPath: IndexPath) {
        if let cellToUpdate = cell as? SwitchTableViewCell {
            cellToUpdate.configCell(item.description,
                                    bottomLine: "",
                                    status: viewModel.userInfo.showImages.contains(.embedded),
                                    complete: { (_, newStatus, feedback: @escaping SwitchTableViewCell.ActionStatus) -> Void in
                                        if let indexp = tableView.indexPath(for: cellToUpdate), indexPath == indexp {
                                            let view = UIApplication.shared.keyWindow ?? UIView()
                                            MBProgressHUD.showAdded(to: view, animated: true)
                                            self.viewModel.updateAutoLoadEmbeddedImageStatus(newStatus: newStatus) { error in
                                                MBProgressHUD.hide(for: view, animated: true)
                                                if let error = error {
                                                    feedback(false)
                                                    error.alertToast()
                                                } else {
                                                    feedback(true)
                                                }
                                            }
                                        } else {
                                            feedback(false)
                                        }
                                    })
        }
    }

    private func configureLinkOpeningModeCell(_ cell: UITableViewCell,
                                              _ item: SettingPrivacyItem,
                                              _ tableView: UITableView,
                                              _ indexPath: IndexPath) {
        if let cellToUpdate = cell as? SwitchTableViewCell {
            let userinfo = self.viewModel.userInfo
            cellToUpdate.configCell(item.description,
                                    bottomLine: "",
                                    status: userinfo.linkConfirmation == .confirmationAlert,
                                    complete: { (_, newStatus, feedback: @escaping SwitchTableViewCell.ActionStatus) -> Void in
                                        if let indexp = tableView.indexPath(for: cellToUpdate), indexPath == indexp {
                                            let view = UIApplication.shared.keyWindow ?? UIView()
                                            MBProgressHUD.showAdded(to: view, animated: true)

                                            self.viewModel.updateLinkConfirmation(newStatus: newStatus) { error in
                                                MBProgressHUD.hide(for: view, animated: true)
                                                if let error = error {
                                                    feedback(false)
                                                    error.alertToast()
                                                } else {
                                                    feedback(true)
                                                }
                                            }
                                        } else {
                                            feedback(false)
                                        }
                                    })
        }
    }
}
