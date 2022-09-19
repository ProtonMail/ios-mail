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

import MBProgressHUD
import ProtonCore_AccountDeletion
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import ProtonCore_DataModel
import UIKit

class SettingsAccountViewController: UITableViewController, AccessibleView {
    private let viewModel: SettingsAccountViewModel
    private let coordinator: SettingsAccountCoordinator

    init(viewModel: SettingsAccountViewModel, coordinator: SettingsAccountCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator

        super.init(style: .grouped)
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

        viewModel.reloadTable = { [weak self] in
            self?.tableView.reloadData()
        }

        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: CellKey.headerCell)
        tableView.register(SettingsGeneralCell.self)
        tableView.register(SettingsTwoLinesCell.self)

        tableView.rowHeight = CellKey.cellHeight

        tableView.estimatedSectionHeaderHeight = 52.0
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.separatorInset = .zero

        view.backgroundColor = ColorProvider.BackgroundSecondary
        generateAccessibilityIdentifiers()
    }

    private func updateTitle() {
        self.title = LocalString._account_settings
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.updateItems()
        navigationController?.setNavigationBarHidden(false, animated: true)
        self.tableView.reloadData()
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
                return UserInfo.isEncryptedSearchEnabled ? self.viewModel.mailboxItems.count : self.viewModel.mailboxItemsESdisabled.count
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
            configureCellInAddressSection(cell, row)
        case .snooze:
            if let cellToUpdate = cell as? SettingsGeneralCell {
                cellToUpdate.configure(left: "AppVersion")
                cellToUpdate.configure(right: "")
            }
        case .mailbox:
            configureCellInMailboxSection(cell, row)
        case .deleteAccount:
            configureCellInDeleteAccountSection(cell, row)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let eSection = self.viewModel.sections[section]

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: CellKey.headerCell)
        header?.contentView.subviews.forEach { $0.removeFromSuperview() }

        if let headerCell = header {
            let textLabel = UILabel()

            let textAttribute = FontManager
                .DefaultSmallWeak
                .alignment(.left)
            textLabel.attributedText = NSAttributedString(string: eSection.description, attributes: textAttribute)
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
            handleDeleteAccountSectionAction(tableView, row)
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
        let label = UILabel(attributedString: string)
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
        accountDeletionFooter.preferredMaxLayoutWidth = tableView.frame.width
        return accountDeletionFooter
    }
}

extension SettingsAccountViewController {
    private func configureCellInAccountSection(_ cell: UITableViewCell, _ row: Int) {
        if let cellToUpdate = cell as? SettingsGeneralCell {
            let item = self.viewModel.accountItems[row]
            cellToUpdate.configure(left: item.description)
            switch item {
            case .singlePassword, .loginPassword, .mailboxPassword:
                break
            case .recovery:
                cellToUpdate.configure(right: viewModel.recoveryEmail)
            case .storage:
                cellToUpdate.configureCell(left: nil, right: viewModel.storageText, imageType: .none)
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

    private func configureCellInMailboxSection(_ cell: UITableViewCell, _ row: Int) {
        if let cellToUpdate = cell as? SettingsGeneralCell {
            let item = UserInfo.isEncryptedSearchEnabled ? self.viewModel.mailboxItems[row] : self.viewModel.mailboxItemsESdisabled[row]
            cellToUpdate.configure(left: item.description)
            switch item {
            case .privacy:
                cellToUpdate.configure(right: "")
            case .conversation:
                cellToUpdate.configure(right: "")
            case .undoSend:
                cellToUpdate.configure(right: "")
            case .search:
                cellToUpdate.configure(right: "")
            case .localStorage:
                cellToUpdate.configure(right: "")
            case .labels:
                cellToUpdate.configure(right: "")
            case .folders:
                cellToUpdate.configure(right: "")
            case .storage:
                cellToUpdate.configure(right: "100 MB (disabled)")
            }
        }
    }

    private func configureCellInDeleteAccountSection(_ cell: UITableViewCell, _ row: Int) {
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
        case .recovery:
            self.coordinator.go(to: .recoveryEmail)
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

                    let view = UIApplication.shared.keyWindow ?? UIView()
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
        let item = UserInfo.isEncryptedSearchEnabled ? self.viewModel.mailboxItems[row] : self.viewModel.mailboxItemsESdisabled[row]
        switch item {
        case .privacy:
            self.coordinator.go(to: .privacy)
        case .search:
            self.coordinator.go(to: .search)
        case .localStorage:
            self.coordinator.go(to: .localStorage)
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
        }
    }

    private func handleDeleteAccountSectionAction(_ tableView: UITableView, _ row: Int) {
        guard isAccountDeletionPending == false else { return }
        self.coordinator.go(to: .deleteAccount)
    }
}
