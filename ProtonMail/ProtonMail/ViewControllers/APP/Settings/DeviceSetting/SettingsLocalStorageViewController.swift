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
import UIKit

class SettingsLocalStorageViewController: ProtonMailTableViewController {
    private let viewModel: SettingsLocalStorageViewModel

    struct Key {
        static let cellHeight: CGFloat = 144.0
        static let cellHeightDownloadedMessages: CGFloat = 140.0
        static let footerHeight: CGFloat = 48.0
        static let headerHeightFirstCell: CGFloat = 32.0
        static let headerHeight: CGFloat = 8.0
        static let headerCell: String = "header_cell"
    }

    init(viewModel: SettingsLocalStorageViewModel) {
        self.viewModel = viewModel

        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateTitle()
        self.view.backgroundColor = ColorProvider.BackgroundSecondary
        self.view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)

        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: Key.headerCell)
        self.tableView.register(LocalStorageTableViewCell.self)

        self.tableView.estimatedSectionFooterHeight = Key.footerHeight
        self.tableView.estimatedRowHeight = Key.cellHeight
        self.tableView.rowHeight = UITableView.automaticDimension

        let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
        if let userID = usersManager.firstUser?.userInfo.userId {
            if userCachedStatus.isEncryptedSearchOn == false {
                EncryptedSearchService.shared.setESState(userID: userID, indexingState: .disabled)
            }
        }

        setupAttachmentsDeletionObserver()
        setupCachedDataDeletionObserver()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Disable table selection to prevent multiple viewcontrollers loaded
        self.tableView.allowsSelection = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Enable table selection - only when state is not undetermined or disabled
        if userCachedStatus.isEncryptedSearchOn {
            let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
            if let userID = usersManager.firstUser?.userInfo.userId {
                let expectedESStates: [EncryptedSearchService.EncryptedSearchIndexState] = [.complete,
                    .partial,
                    .downloading,
                    .paused,
                    .background,
                    .refresh,
                    .backgroundStopped,
                    .lowstorage,
                    .metadataIndexing]
                if expectedESStates.contains(EncryptedSearchService.shared.getESState(userID: userID)) {
                    self.tableView.allowsSelection = true
                }
            }
        }

        // reload table if view appears
        self.tableView.reloadData()
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

    // swiftlint:disable function_body_length
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .cachedData:
            let cell = tableView.dequeueReusableCell(withIdentifier: LocalStorageTableViewCell.CellID, for: indexPath)
            if let localStorageCell = cell as? LocalStorageTableViewCell {
                localStorageCell.button.setTitle(LocalString._settings_local_storage_cached_data_button,
                                                 for: UIControl.State.normal)
                let cachedData: String = EncryptedSearchService.shared.getSizeOfCachedData().asString
                let infoText = NSMutableAttributedString(string: LocalString._settings_local_storage_cached_data_text)
                localStorageCell.configCell(eSection.title, infoText, cachedData) {
                    let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                    if let userID = usersManager.firstUser?.userInfo.userId {
                        EncryptedSearchService.shared.deleteCachedData(userID: userID,
                                                                       localStorageViewModel: self.viewModel)
                    } else {
                        print("Error: cannot clean cached data - user unknown")
                    }

                    // Update UI
                    DispatchQueue.main.async {
                        UIView.performWithoutAnimation {
                            localStorageCell.bottomLabel.text = ByteCountFormatter.string(fromByteCount: 0,
                                                                                          countStyle: ByteCountFormatter.CountStyle.file)
                        }
                    }
                }
            }
            cell.selectionStyle = .none
            return cell
        case .attachments:
            let cell = tableView.dequeueReusableCell(withIdentifier: LocalStorageTableViewCell.CellID, for: indexPath)
            if let localStorageCell = cell as? LocalStorageTableViewCell {
                localStorageCell.button.setTitle(LocalString._settings_local_storage_attachments_button,
                                                 for: UIControl.State.normal)
                let attachments: String = EncryptedSearchService.shared.calculateSizeOfAttachments().asString
                let attr = FontManager.CaptionWeak.lineBreakMode(.byWordWrapping)
                let infoText = NSMutableAttributedString(string: LocalString._settings_local_storage_attachments_text,
                                                         attributes: attr)
                localStorageCell.configCell(eSection.title, infoText, attachments) {
                    EncryptedSearchService.shared.deleteAttachments(localStorageViewModel: self.viewModel)

                    // Update UI
                    DispatchQueue.main.async {
                        let path: IndexPath = IndexPath.init(row: 0,
                                                             section: SettingsLocalStorageViewModel.SettingsSection.attachments.rawValue)
                        UIView.performWithoutAnimation {
                            if self.tableView.hasRowAtIndexPath(indexPath: path) {
                                self.tableView.reloadRows(at: [path], with: .none)
                            }
                        }
                    }
                }
            }
            cell.selectionStyle = .none
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
                        downloadedMessages = EncryptedSearchIndexService.shared.getSizeOfSearchIndex(for: userID)
                                                                                .asString
                    }
                }

                // Add attributed string
                let full = String.localizedStringWithFormat(
                    LocalString._settings_local_storage_downloaded_messages_text,
                    LocalString._settings_local_storage_downloaded_messages_text_link)
                let attr = FontManager.CaptionWeak.lineBreakMode(.byWordWrapping)
                let infoText = NSMutableAttributedString(string: full, attributes: attr)
                if let subrange = full.range(of: LocalString._settings_local_storage_downloaded_messages_text_link) {
                    let nsRange = NSRange(subrange, in: full)
                    infoText.addAttribute(NSAttributedString.Key.foregroundColor,
                                          value: ColorProvider.InteractionNorm as UIColor,
                                          range: nsRange)
                }

                // Add tap recognizer for see details string
                let tap = UITapGestureRecognizer(target: self, action: #selector(tapAttributedStringHandler(_:)))
                tap.delegate = self
                localStorageCell.middleLabel.isUserInteractionEnabled = true
                localStorageCell.middleLabel.addGestureRecognizer(tap)

                // Config cell
                localStorageCell.configCell(eSection.title, infoText, downloadedMessages) {}

                // Add chevron when state is not undetermined or disabled
                if let userID = usersManager.firstUser?.userInfo.userId {
                    let expectedESStates: [EncryptedSearchService.EncryptedSearchIndexState] = [.complete,
                        .partial,
                        .downloading,
                        .paused,
                        .background,
                        .refresh,
                        .backgroundStopped,
                        .lowstorage]
                    if expectedESStates.contains(EncryptedSearchService.shared.getESState(userID: userID)) {
                        localStorageCell.accessoryType = .disclosureIndicator
                    }
                }
            }
            cell.selectionStyle = .none
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
                textLabel.attributedText = NSAttributedString(string: eSection.foot,
                                                              attributes: FontManager.CaptionWeak)
                headerCell.contentView.addSubview(textLabel)

                NSLayoutConstraint.activate([
                    textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 8),
                    textLabel.leadingAnchor.constraint(equalTo: headerCell.contentView.leadingAnchor, constant: 16),
                    textLabel.trailingAnchor.constraint(equalTo: headerCell.contentView.trailingAnchor, constant: -16)
                ])
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
            if userCachedStatus.isEncryptedSearchOn {
                let usersManager: UsersManager = sharedServices.get(by: UsersManager.self)
                if let userID = usersManager.firstUser?.userInfo.userId {
                    let expectedESStates: [EncryptedSearchService.EncryptedSearchIndexState] = [.complete,
                        .partial,
                        .downloading,
                        .paused,
                        .background,
                        .refresh,
                        .backgroundStopped,
                        .lowstorage,
                        .metadataIndexing]
                    if expectedESStates.contains(EncryptedSearchService.shared.getESState(userID: userID)) {
                        let viewModel = SettingsEncryptedSearchDownloadedMessagesViewModel(
                            encryptedSearchDownloadedMessagesCache: userCachedStatus)
                        let viewController = SettingsEncryptedSearchDownloadedMessagesViewController(
                            viewModel: viewModel)
                        show(viewController, sender: self)
                    }
                }
            }
        }
    }

    func setupAttachmentsDeletionObserver() {
        self.viewModel.areAttachmentsDeleted.bind { _ in
            DispatchQueue.main.async {
                let path: IndexPath = IndexPath.init(row: 0,
                                                     section: SettingsLocalStorageViewModel.SettingsSection.attachments.rawValue)
                UIView.performWithoutAnimation {
                    if self.tableView.hasRowAtIndexPath(indexPath: path) {
                        self.tableView.reloadRows(at: [path], with: .none)
                    }
                }
            }
        }
    }

    func setupCachedDataDeletionObserver() {
        self.viewModel.isCachedDataDeleted.bind { _ in
            DispatchQueue.main.async {
                let path: IndexPath = IndexPath.init(row: 0,
                                                     section: SettingsLocalStorageViewModel.SettingsSection.cachedData.rawValue)
                UIView.performWithoutAnimation {
                    if self.tableView.hasRowAtIndexPath(indexPath: path) {
                        self.tableView.reloadRows(at: [path], with: .none)
                    }
                }
            }
        }
    }
}

extension SettingsLocalStorageViewController: UIGestureRecognizerDelegate {
    @objc func tapAttributedStringHandler(_ sender: UITapGestureRecognizer) {
        if let label = sender.view as? UILabel {
            let layoutManager: NSLayoutManager = NSLayoutManager()
            let textContainer: NSTextContainer = NSTextContainer(size: .zero)
            let textStorage: NSTextStorage = NSTextStorage(
                attributedString: label.attributedText ?? NSAttributedString(string: ""))
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)

            // configure textcontainer
            textContainer.lineFragmentPadding = 0.0
            textContainer.lineBreakMode = label.lineBreakMode
            textContainer.maximumNumberOfLines = label.numberOfLines
            textContainer.size = label.bounds.size

            // Find tapped character location
            let locationOfTouchInLabel = sender.location(in: label)
            let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInLabel,
                                                                in: textContainer,
                                                                fractionOfDistanceBetweenInsertionPoints: nil)

            // Range
            let text: String = label.attributedText?.string ?? ""
            let subrange = text.range(of: LocalString._settings_local_storage_downloaded_messages_text_link)
            let range = NSRange(subrange!, in: text)
            if range.contains(indexOfCharacter) {
                /* let vm = SettingsEncryptedSearchViewModel(encryptedSearchCache: userCachedStatus)
                let coord = SettingsDeviceCoordinator()
                let vc = SettingsEncryptedSearchViewController(viewModel: vm, coordinator: coord)
                show(vc, sender: self) */
            }
        }
    }
}
