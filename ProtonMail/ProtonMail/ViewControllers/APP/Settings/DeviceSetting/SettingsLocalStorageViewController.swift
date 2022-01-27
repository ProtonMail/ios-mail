// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import CoreGraphics
import UIKit

class SettingsLocalStorageViewController: ProtonMailTableViewController, ViewModelProtocol, CoordinatedNew {
    internal var viewModel: SettingsLocalStorageViewModel!
    internal var coordinator: SettingsDeviceCoordinator?

    struct Key {
        static let cellHeight: CGFloat = 144.0
        static let cellHeightDownloadedMessages: CGFloat = 140.0
        static let footerHeight: CGFloat = 48.0
        static let headerHeightFirstCell: CGFloat = 32.0
        static let headerHeight: CGFloat = 8.0
        static let headerCell: String = "header_cell"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateTitle()

        self.view.backgroundColor = ColorProvider.BackgroundSecondary
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(LocalStorageTableViewCell.self)

        self.tableView.estimatedSectionFooterHeight = Key.footerHeight
        self.tableView.estimatedRowHeight = Key.cellHeight
        self.tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Disable table selection to prevent multiple viewcontrollers loaded
        self.tableView.allowsSelection = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Enable table selection
        self.tableView.allowsSelection = true
    }

    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }

    func set(coordinator: SettingsDeviceCoordinator) {
        self.coordinator = coordinator
    }

    func set(viewModel: SettingsLocalStorageViewModel) {
        self.viewModel = viewModel
    }

    private func updateTitle() {
        self.title = LocalString._settings_title_of_local_storage
    }
}

extension SettingsLocalStorageViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return Key.headerHeightFirstCell
        }
        return Key.headerHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = ColorProvider.BackgroundSecondary
        headerView.translatesAutoresizingMaskIntoConstraints = false

        if section == 0 {
            headerView.frame = CGRect(x: 0, y: 0, width: 375.0, height: Key.headerHeightFirstCell)
            NSLayoutConstraint.activate([
                headerView.heightAnchor.constraint(equalToConstant: Key.headerHeightFirstCell)
            ])
        } else {
            headerView.frame = CGRect(x: 0, y: 0, width: 375.0, height: Key.headerHeight)
            NSLayoutConstraint.activate([
                headerView.heightAnchor.constraint(equalToConstant: Key.headerHeight)
            ])
        }

        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 2 {
            return Key.footerHeight
        }
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = indexPath.section

        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .cachedData:
            return Key.cellHeight
        case .attachments:
            return Key.cellHeight
        case .downloadedMessages:
            return Key.cellHeightDownloadedMessages
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let section = indexPath.section
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .cachedData:
            let cell = tableView.dequeueReusableCell(withIdentifier: LocalStorageTableViewCell.CellID, for: indexPath)
            if let localStorageCell = cell as? LocalStorageTableViewCell {
                localStorageCell.button.setTitle(LocalString._settings_local_storage_cached_data_button, for: UIControl.State.normal)
                let cachedData: String = "" // This should be the size of the messages in core data
                let infoText = NSMutableAttributedString(string: LocalString._settings_local_storage_cached_data_text)
                localStorageCell.configCell(eSection.title, infoText, cachedData){
                    //TODO implement button action
                    print("Button pressed in cached data")
                }
            }
            return cell
        case .attachments:
            let cell = tableView.dequeueReusableCell(withIdentifier: LocalStorageTableViewCell.CellID, for: indexPath)
            if let localStorageCell = cell as? LocalStorageTableViewCell {
                localStorageCell.button.setTitle(LocalString._settings_local_storage_attachments_button, for: UIControl.State.normal)
                let attachments: String = ""// This should be the size of the attachments of the emails
                let attr = FontManager.CaptionWeak.lineBreakMode(.byWordWrapping)
                let infoText = NSMutableAttributedString(string: LocalString._settings_local_storage_attachments_text, attributes: attr)
                localStorageCell.configCell(eSection.title, infoText, attachments){
                    //TODO implement button action
                    print("Button pressed in attachments")
                }
            }
            return cell
        case .downloadedMessages:
            let cell = tableView.dequeueReusableCell(withIdentifier: LocalStorageTableViewCell.CellID, for: indexPath)
            if let localStorageCell = cell as? LocalStorageTableViewCell {
                localStorageCell.button.isHidden = true
                var downloadedMessages: String = ""

                let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                if let userID = usersManager.firstUser?.userInfo.userId {
                    if EncryptedSearchService.shared.getESState(userID: userID) == .disabled {
                        downloadedMessages = LocalString._settings_local_storage_downloaded_messages_text_disabled
                        localStorageCell.bottomLabel.textColor = ColorProvider.NotificationError
                    } else {
                        downloadedMessages = EncryptedSearchIndexService.shared.getSizeOfSearchIndex(for: userID).asString
                    }
                }

                let seeDetails = LocalString._settings_local_storage_downloaded_messages_text_link
                let full = String.localizedStringWithFormat(LocalString._settings_local_storage_downloaded_messages_text, seeDetails)
                let attr = FontManager.CaptionWeak.lineBreakMode(.byWordWrapping)

                let infoText = NSMutableAttributedString(string: full, attributes: attr)

                if let subrange = full.range(of: seeDetails){
                    let nsRange = NSRange(subrange, in: full)
                    infoText.addAttribute(NSAttributedString.Key.foregroundColor, value: ColorProvider.InteractionNorm, range: nsRange)
                }

                localStorageCell.configCell(eSection.title, infoText, downloadedMessages){}
                localStorageCell.accessoryType = .disclosureIndicator
            }
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: Key.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }
        header?.contentView.backgroundColor = ColorProvider.BackgroundSecondary

        if let headerCell = header {
            let eSection = self.viewModel.sections[section]
            switch eSection {
            case .cachedData, .attachments:
                break
            case .downloadedMessages:
                let textLabel = UILabel()
                textLabel.numberOfLines = 0
                textLabel.translatesAutoresizingMaskIntoConstraints = false
                textLabel.attributedText = NSAttributedString(string: eSection.foot, attributes: FontManager.CaptionWeak)
                headerCell.contentView.addSubview(textLabel)

                NSLayoutConstraint.activate([
                    textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 8),
                    textLabel.leadingAnchor.constraint(equalTo: headerCell.contentView.leadingAnchor, constant: 16),
                    textLabel.trailingAnchor.constraint(equalTo: headerCell.contentView.trailingAnchor, constant: -16)
                ])
                break
            }
        }
        return header
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section

        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .cachedData, .attachments:
            break
        case .downloadedMessages:
            let vm = SettingsEncryptedSearchViewModel(encryptedSearchCache: userCachedStatus)
            let vc = SettingsEncryptedSearchViewController()
            vc.set(viewModel: vm)
            show(vc, sender: self)
            break
        }
    }
}
