//
//  SettingsAccountViewController.swift
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

import LifetimeTracker
import MBProgressHUD
import ProtonCoreAccountDeletion
import ProtonCoreAccountRecovery
import ProtonCoreFeatureFlags
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

class SettingsAccountViewController: UITableViewController, AccessibleView, LifetimeTrackable {
    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    private let viewModel: SettingsAccountViewModel
    private let coordinator: SettingsAccountCoordinatorProtocol

    init(
        viewModel: SettingsAccountViewModel,
        coordinator: SettingsAccountCoordinatorProtocol
    ) {
        self.viewModel = viewModel
        self.coordinator = coordinator

        super.init(style: .grouped)
        trackLifetime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    struct CellKey {
        static let headerCell: String        = "header_cell"
        static let headerCellHeight: CGFloat = 36.0
        static let cellHeight: CGFloat = 48.0
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        emptyBackButtonTitleForNextView()

        updateTitle()

        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: CellKey.headerCell)
        tableView.register(SettingsGeneralCell.self)
        tableView.register(SettingsGeneralImageCell.self)

        tableView.rowHeight = CellKey.cellHeight

        tableView.estimatedSectionHeaderHeight = 52.0
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.separatorInset = .zero

        view.backgroundColor = ColorProvider.BackgroundSecondary
        generateAccessibilityIdentifiers()
        refreshUserInfo()
    }

    private func updateTitle() {
        self.title = LocalString._account_settings
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
        if isAccountDeletionPending {
            // reset the flag when the account view is shown again.
            isAccountDeletionPending = false
        } else {
            self.tableView.reloadData()
        }
    }

    func refreshUserInfo() {
        guard viewModel.isAccountRecoveryEnabled else { return }
        Task {
            await viewModel.refreshUserInfo()
            await MainActor.run {
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - table view delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.viewModel.sections.count > section {
            switch self.viewModel.sections[section] {
            case .account:
                return self.viewModel.accountItems.count
            case .addresses:
                return self.viewModel.addrItems.count
            case .snooze:
                return 0
            case .mailbox:
                return self.viewModel.mailboxItems.count
            case .deleteAccount:
                return 1
            }
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID, for: indexPath)

        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]

        switch eSection {
        case .account:
            configureCellInAccountSection(cell, row)
        case .addresses:
            if row == SettingsAddressItem.allCases.firstIndex(of: .mobileSignature), let pfc = premiumFeatureCell(
                for: indexPath,
                description: SettingsAddressItem.mobileSignature.description,
                isFeatureCurrentlyOn: viewModel.showMobileSignature
            ) {
                return pfc
            } else {
                configureCellInAddressSection(cell, row)
            }
        case .snooze:
            if let cellToUpdate = cell as? SettingsGeneralCell {
                cellToUpdate.configure(left: "AppVersion")
                cellToUpdate.configure(right: "")
            }
        case .mailbox:
            return configureAndReturnCellInMailboxSection(at: indexPath) ?? UITableViewCell()
        case .deleteAccount:
            configureCellInDeleteAccountSection(cell)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let eSection = self.viewModel.sections[section]

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CellKey.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }

        if let headerCell = header {
            let textLabel = UILabel()
            textLabel.set(text: eSection.description,
                          preferredFont: .subheadline,
                          textColor: ColorProvider.TextWeak)
            textLabel.translatesAutoresizingMaskIntoConstraints = false

            headerCell.contentView.addSubview(textLabel)

            NSLayoutConstraint.activate([
                textLabel.topAnchor.constraint(equalTo: headerCell.contentView.topAnchor, constant: 24),
                textLabel.bottomAnchor.constraint(equalTo: headerCell.contentView.bottomAnchor, constant: -8),
                textLabel.leftAnchor.constraint(equalTo: headerCell.contentView.leftAnchor, constant: 16),
                textLabel.rightAnchor.constraint(equalTo: headerCell.contentView.rightAnchor, constant: -8)
            ])
        }
        return header
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return CellKey.headerCellHeight
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        let eSection = self.viewModel.sections[section]
        switch eSection {
        case .account:
            handelAccountSectionAction(row)
        case .addresses:
            if self.viewModel.addrItems.count > row {
                handleAddressesSectionAction(row, tableView, indexPath)
            }
        case .snooze:
            break
        case .mailbox:
            handleMailboxSectionAction(row)
        case .deleteAccount:
            handleDeleteAccountSectionAction()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    var isAccountDeletionPending: Bool = false {
        didSet {
            tableView.reloadData()
        }
    }

    private lazy var accountDeletionFooter: UILabel = {
        var attributes = FontManager.CaptionWeak
        let paragraphStyle = NSMutableParagraphStyle()
        if let exisitingParagraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            paragraphStyle.setParagraphStyle(exisitingParagraphStyle)
        }
        paragraphStyle.headIndent = 16
        paragraphStyle.tailIndent = -16
        paragraphStyle.firstLineHeadIndent = 16
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.paragraphSpacingBefore = 8
        paragraphStyle.paragraphSpacing = 8
        attributes[.paragraphStyle] = paragraphStyle
        let string = NSAttributedString(
            string: AccountDeletionService.defaultExplanationMessage,
            attributes: attributes
        )
        let label = UILabel(AccountDeletionService.defaultExplanationMessage,
                            font: UIFont.preferredFont(for: .footnote, weight: .regular),
                            textColor: ColorProvider.TextWeak)
        label.numberOfLines = 0
        return label
    }()

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let index = self.viewModel.sections.firstIndex(of: .deleteAccount), index == section else {
            return CGFloat.leastNormalMagnitude
        }
        accountDeletionFooter.preferredMaxLayoutWidth = tableView.frame.width
        return accountDeletionFooter.intrinsicContentSize.height + 16
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let index = self.viewModel.sections.firstIndex(of: .deleteAccount), index == section else {
            return UIView()
        }
        let container = UIView()
        container.addSubview(accountDeletionFooter)
        accountDeletionFooter.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            accountDeletionFooter.topAnchor.constraint(equalTo: container.topAnchor),
            accountDeletionFooter.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            accountDeletionFooter.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            accountDeletionFooter.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        accountDeletionFooter.preferredMaxLayoutWidth = tableView.frame.width
        return container
    }
}

extension SettingsAccountViewController {
    private func configureCellInAccountSection(_ cell: UITableViewCell, _ row: Int) {
        if let cellToUpdate = cell as? SettingsGeneralCell {
            let item = self.viewModel.accountItems[row]
            cellToUpdate.configure(left: item.description)
            switch item {
            case .singlePassword, .loginPassword, .mailboxPassword, .privacyAndData, .securityKeys:
                break
            case .recovery:
                cellToUpdate.configure(right: viewModel.recoveryEmail)
            case .storage:
                cellToUpdate.configureCell(left: nil, right: viewModel.storageText, imageType: .none)
            case .accountRecovery:
                cellToUpdate.configureCell(left: nil, right: viewModel.accountRecoveryText, imageType: .none)
            }
        }
    }

    private func configureCellInAddressSection(_ cell: UITableViewCell, _ row: Int) {
        if let cellToUpdate = cell as? SettingsGeneralCell {
            let item = self.viewModel.addrItems[row]
            cellToUpdate.configure(left: item.description)
            switch item {
            case .addr:
                cellToUpdate.configure(right: self.viewModel.email)
            case .displayName:
                cellToUpdate.configure(right: self.viewModel.displayName)
            case .signature:
                cellToUpdate.configure(right: self.viewModel.defaultSignatureStatus)
            case .mobileSignature:
                cellToUpdate.configure(right: self.viewModel.defaultMobileSignatureStatus)
            }
        }
    }

    private func configureAndReturnCellInMailboxSection(at indexPath: IndexPath) -> UITableViewCell? {
        let item = self.viewModel.mailboxItems[indexPath.row]
        switch item {
        case .autoDeleteSpamTrash:
            return premiumFeatureCell(
                for: indexPath,
                description: item.description,
                isFeatureCurrentlyOn: viewModel.isAutoDeleteSpamAndTrashEnabled
            )
        case .storage:
            return generalCell(for: indexPath, item: item, rightLabel: "100 MB (disabled)")
        case .nextMsgAfterMove:
            return generalCell(for: indexPath, item: item, rightLabel: viewModel.jumpToNextMessageDescription)
        default:
            return generalCell(for: indexPath, item: item, rightLabel: "")
        }
    }

    private func generalCell(
        for indexPath: IndexPath,
        item: SettingsMailboxItem,
        rightLabel: String
    ) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralCell.CellID,
                                                       for: indexPath) as? SettingsGeneralCell else {
            return nil
        }
        cell.configure(left: item.description)
        cell.configure(right: rightLabel)
        return cell
    }

    private func premiumFeatureCell(
        for indexPath: IndexPath,
        description: String,
        isFeatureCurrentlyOn: Bool
    ) -> UITableViewCell? {
        guard let imageCell = tableView.dequeueReusableCell(withIdentifier: SettingsGeneralImageCell.CellID,
                                                            for: indexPath) as? SettingsGeneralImageCell else {
            return nil
        }
        let onOffTitle: String
        if isFeatureCurrentlyOn {
            onOffTitle = LocalString._settings_On_title
        } else {
            onOffTitle = LocalString._settings_Off_title
        }
        let image = self.viewModel.isPaidUser ? nil : Asset.upgradeIcon.image
        imageCell.configure(left: description, right: onOffTitle, leftImage: image)
        return imageCell
    }

    private func configureCellInDeleteAccountSection(_ cell: UITableViewCell) {
        guard let cellToUpdate = cell as? SettingsGeneralCell else { return }
        cellToUpdate.configureCell(left: AccountDeletionService.defaultButtonName,
                                   right: nil,
                                   imageType: isAccountDeletionPending ? .activityIndicator : .arrow,
                                   contentType: .destructive)
    }

    private func handelAccountSectionAction(_ row: Int) {
        let item = self.viewModel.accountItems[row]
        switch item {
        case .singlePassword:
            self.coordinator.go(to: .singlePwd)
        case .loginPassword:
            self.coordinator.go(to: .loginPwd)
        case .mailboxPassword:
            self.coordinator.go(to: .mailboxPwd)
        case .securityKeys:
            self.coordinator.go(to: .securityKeys)
        case .recovery:
            self.coordinator.go(to: .recoveryEmail)
        case .privacyAndData:
            coordinator.go(to: .privacyAndData)
        case .accountRecovery:
            self.coordinator.go(to: .accountRecovery)
        case .storage:
            break
        }
    }

    private func handleAddressesSectionAction(_ row: Int, _ tableView: UITableView, _ indexPath: IndexPath) {
        let item = self.viewModel.addrItems[row]
        switch item {
        case .addr:
            var needsShow: Bool = false
            let alertController = UIAlertController(title: LocalString._settings_change_default_address_to,
                                                    message: nil,
                                                    preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                    style: .cancel,
                                                    handler: nil))

            let addresses = viewModel.allSendingAddresses
            needsShow = !addresses.isEmpty
            for address in addresses {
                alertController.addAction(UIAlertAction(title: address.email, style: .default, handler: { _ in

                    if address.send == .inactive {
                        if address.email.lowercased().range(of: "@pm.me") != nil {
                            let msg = String(format: LocalString._settings_change_paid_address_warning, address.email)
                            let alertController = msg.alertController()
                            alertController.addOKAction()
                            self.present(alertController, animated: true, completion: nil)
                            return
                        }
                    }

                    let view: UIView = self.view
                    MBProgressHUD.showAdded(to: view, animated: true)

                    self.viewModel.updateDefaultAddress(with: address) { [weak self] error in
                        MBProgressHUD.hide(for: view, animated: true)
                        error?.alertToast()
                        self?.tableView.reloadData()
                    }
                }))
            }

            if needsShow {
                let cell = tableView.cellForRow(at: indexPath)
                alertController.popoverPresentationController?.sourceView = cell ?? self.view
                alertController.popoverPresentationController?.sourceRect = cell?.bounds ?? self.view.frame
                present(alertController, animated: true, completion: nil)
            }
        case .displayName:
            self.coordinator.go(to: .displayName)
        case .signature:
            self.coordinator.go(to: .signature)
        case .mobileSignature:
            self.coordinator.go(to: .mobileSignature)
        }
    }

    private func handleMailboxSectionAction(_ row: Int) {
        let item = self.viewModel.mailboxItems[row]
        switch item {
        case .privacy:
            self.coordinator.go(to: .privacy)
        case .labels:
            self.coordinator.go(to: .labels)
        case .folders:
            self.coordinator.go(to: .folders)
        case .storage:
            break
        case .conversation:
            self.coordinator.go(to: .conversation)
        case .undoSend:
            self.coordinator.go(to: .undoSend)
        case .nextMsgAfterMove:
            coordinator.go(to: .nextMsgAfterMove)
        case .blockList:
            coordinator.go(to: .blockList)
        case .autoDeleteSpamTrash:
            self.coordinator.go(to: .autoDeleteSpamTrash)
        }
    }

    private func handleDeleteAccountSectionAction() {
        guard isAccountDeletionPending == false else { return }
        self.coordinator.go(to: .deleteAccount)
    }
}
