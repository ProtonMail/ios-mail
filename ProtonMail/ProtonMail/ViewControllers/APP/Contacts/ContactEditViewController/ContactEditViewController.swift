// Copyright (c) 2023 Proton Technologies AG
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

import LifetimeTracker
import MBProgressHUD
import PhotosUI
import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

protocol ContactEditViewControllerDelegate: AnyObject {
    func deleted()
    func updated()
}

final class ContactEditViewController: UIViewController, AccessibleView {
    typealias Dependencies = HasContactViewsFactory

    weak var delegate: ContactEditViewControllerDelegate?

    private let dependencies: Dependencies

    private let viewModel: ContactEditViewModel
    private(set) lazy var customView = NewContactEditView()

    private(set) var doneButton: UIBarButtonItem?
    private(set) var cancelButton: UIBarButtonItem?

    private var newIndexPath: IndexPath?
    private var activeTextComponent: UIResponder?

    init(viewModel: ContactEditViewModel, dependencies: Dependencies) {
        self.viewModel = viewModel
        self.dependencies = dependencies
        super.init(nibName: nil, bundle: nil)
        trackLifetime()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupPhotoButton()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.resetCellButtonColor),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
        dismissKeyboard()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        customView.tableView.sizeHeaderToFit()
    }
}

// MARK: - UITableViewDataSource

extension ContactEditViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionCount()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections = viewModel.getSections()
        let section = sections[section]
        switch section {
        case .email_header, .display_name, .encrypted_header, .share:
            return 0
        case .type2_warning, .type3_error, .type3_warning, .debuginfo:
            return 1
        case .emails:
            return 1 + viewModel.getEmails().count
        case .cellphone:
            return 1 + viewModel.getCells().count
        case .home_address:
            return 1 + viewModel.getAddresses().count
        case .url:
            return viewModel.getUrls().count
        case .custom_field:
            return 1 + viewModel.getFields().count
        case .notes:
            return viewModel.getNotes().count
        case .delete:
            return viewModel.isNew() ? 0 : 1
        case .birthday:
            return 1
        case .organization:
            return viewModel.organizations.count
        case .nickName:
            return viewModel.nickNames.count
        case .title:
            return viewModel.contactTitles.count
        case .gender:
            return viewModel.gender == nil ? 0 : 1
        case .anniversary:
            return viewModel.anniversary == nil ? 0 : 1
        case .addNewField:
            return 1
        }
    }

    // swiftlint:disable:next function_body_length
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sections = viewModel.getSections()
        var outCell: UITableViewCell?
        let sectionNumber = indexPath.section
        let row = indexPath.row
        let section = sections[sectionNumber]

        var firstResponder = false
        if let index = newIndexPath, index == indexPath {
            firstResponder = true
            newIndexPath = nil
        }

        switch section {
        case .display_name, .encrypted_header:
            assertionFailure("Code should not be here")
        case .emails:
            let emailCount = viewModel.getEmails().count
            if row == emailCount {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ContactEditConstants.contactEditAddCell,
                    for: indexPath
                ) as? ContactEditAddCell
                cell?.configCell(value: LocalString._contacts_add_new_email)
                cell?.selectionStyle = .default
                outCell = cell
            } else {
                if viewModel.isNew() {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ContactEditConstants.contactAddEmailCell,
                        for: indexPath
                    ) as? ContactAddEmailCell
                    cell?.selectionStyle = .none
                    cell?.configCell(
                        obj: viewModel.getEmails()[row],
                        callback: self,
                        becomeFirstResponder: firstResponder
                    )
                    outCell = cell
                } else {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: ContactEditConstants.contactEditEmailCell,
                        for: indexPath
                    ) as? ContactEditEmailCell
                    cell?.selectionStyle = .none
                    cell?.configCell(
                        obj: viewModel.getEmails()[row],
                        callback: self,
                        becomeFirstResponder: firstResponder
                    )
                    outCell = cell
                }
            }
        case .cellphone:
            let cellCount = viewModel.getCells().count
            if row == cellCount {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ContactEditConstants.contactEditAddCell,
                    for: indexPath
                ) as? ContactEditAddCell
                cell?.configCell(value: LocalString._contacts_add_new_phone)
                cell?.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ContactEditConstants.contactEditCellphoneCell,
                    for: indexPath
                ) as? ContactEditPhoneCell
                cell?.selectionStyle = .none
                cell?.configCell(
                    obj: viewModel.getCells()[row],
                    callback: self,
                    becomeFirstResponder: firstResponder
                )
                outCell = cell
            }
        case .home_address:
            let addrCount = viewModel.getAddresses().count
            if row == addrCount {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ContactEditConstants.contactEditAddCell,
                    for: indexPath
                ) as? ContactEditAddCell
                cell?.configCell(value: LocalString._contacts_add_new_address)
                cell?.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ContactEditConstants.contactEditAddressCell,
                    for: indexPath
                ) as? ContactEditAddressCell
                cell?.selectionStyle = .none
                cell?.configCell(
                    obj: viewModel.getAddresses()[row],
                    callback: self,
                    becomeFirstResponder: firstResponder
                )
                outCell = cell
            }
        case .url:
            let urlCount = viewModel.getUrls().count
            if row == urlCount {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ContactEditConstants.contactEditAddCell,
                    for: indexPath
                ) as? ContactEditAddCell
                cell?.configCell(value: LocalString._add_new_url)
                cell?.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ContactEditConstants.contactEditUrlCell,
                    for: indexPath
                ) as? ContactEditUrlCell
                cell?.selectionStyle = .none
                cell?.configCell(obj: viewModel.getUrls()[row], callback: self, becomeFirstResponder: firstResponder)
                outCell = cell
            }
        case .custom_field:
            let fieldCount = viewModel.getFields().count
            if row == fieldCount {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ContactEditConstants.contactEditAddCell,
                    for: indexPath
                ) as? ContactEditAddCell
                cell?.configCell(value: LocalString._contacts_add_new_custom_field)
                cell?.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ContactEditConstants.contactEditFieldCell,
                    for: indexPath
                ) as? ContactEditFieldCell
                cell?.selectionStyle = .none
                cell?.configCell(obj: viewModel.getFields()[row], callback: self, becomeFirstResponder: firstResponder)
                outCell = cell
            }
        case .notes:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactEditConstants.contactEditTextViewCell,
                for: indexPath
            ) as? ContactEditTextViewCell
            cell?.configCell(obj: viewModel.getNotes()[row], callback: self)
            cell?.selectionStyle = .none
            outCell = cell
        case .delete:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactEditConstants.contactEditDeleteCell,
                for: indexPath
            ) as? ContactEditAddCell
            cell?.configCell(
                value: LocalString._delete_contact,
                color: ColorProvider.NotificationError
            )
            cell?.selectionStyle = .default
            outCell = cell
        case .addNewField:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactEditConstants.contactEditAddCell,
                for: indexPath
            ) as? ContactEditAddCell
            cell?.configCell(value: LocalString._contacts_add_new_field)
            cell?.selectionStyle = .default
            outCell = cell
        case .birthday:
            if let birthday = viewModel.birthday {
                outCell = createEditInfoCell(tableView: tableView, at: indexPath, info: birthday, firstResponder: firstResponder)
            } else {
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: ContactEditConstants.contactEditAddCell,
                    for: indexPath
                ) as? ContactEditAddCell
                cell?.configCell(value: LocalString._contacts_add_bd)
                cell?.selectionStyle = .default
                outCell = cell
            }
        case .organization:
            outCell = createEditInfoCell(tableView: tableView, at: indexPath, info: viewModel.organizations[row], firstResponder: firstResponder)
        case .nickName:
            outCell = createEditInfoCell(tableView: tableView, at: indexPath, info: viewModel.nickNames[row], firstResponder: firstResponder)
        case .title:
            outCell = createEditInfoCell(tableView: tableView, at: indexPath, info: viewModel.contactTitles[row], firstResponder: firstResponder)
        case .gender:
            if let gender = viewModel.gender {
                outCell = createEditInfoCell(tableView: tableView, at: indexPath, info: gender, firstResponder: firstResponder)
            }
        case .anniversary:
            if let anniversary = viewModel.anniversary {
                outCell = createEditInfoCell(tableView: tableView, at: indexPath, info: anniversary, firstResponder: firstResponder)
            }
        default:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ContactEditConstants.contactEditAddCell,
                for: indexPath
            )
            cell.selectionStyle = .none
            outCell = cell
        }
        return outCell ?? UITableViewCell()
    }

    private func createEditInfoCell(
        tableView: UITableView,
        at indexPath: IndexPath,
        info: ContactEditInformation,
        firstResponder: Bool
    ) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ContactEditConstants.contactEditCellInfoCell,
            for: indexPath
        ) as? ContactEditInformationCell
        cell?.selectionStyle = .none
        cell?.configCell(
            obj: info,
            callback: self,
            becomeFirstResponder: firstResponder
        )
        return cell
    }

    // swiftlint:disable:next function_body_length
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismissKeyboard()
        tableView.deselectRow(at: indexPath, animated: true)

        let sections = viewModel.getSections()
        let section = indexPath.section
        let row = indexPath.row
        let sectionType = sections[section]

        switch sectionType {
        case .email_header, .display_name, .encrypted_header, .notes,
             .type2_warning, .type3_error, .type3_warning, .debuginfo:
            break
        // assert(false, "Code should not be here")
        case .emails:
            let emailCount = viewModel.getEmails().count
            if row == emailCount {
                _ = viewModel.newEmail()
                newIndexPath = indexPath
                customView.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .cellphone:
            let cellCount = viewModel.getCells().count
            if row == cellCount {
                _ = viewModel.newPhone()
                newIndexPath = indexPath
                customView.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .home_address:
            let addrCount = viewModel.getAddresses().count
            if row == addrCount {
                _ = viewModel.newAddress()
                newIndexPath = indexPath
                customView.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .url:
            let urlCount = viewModel.getUrls().count
            if row == urlCount {
                _ = viewModel.newUrl()
                newIndexPath = indexPath
                customView.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .custom_field:
            let fieldCount = viewModel.getFields().count
            if row == fieldCount {
                _ = viewModel.newField()
                newIndexPath = indexPath
                customView.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .delete:
            let sender = tableView.cellForRow(at: indexPath)
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(
                UIAlertAction(
                    title: LocalString._general_cancel_button,
                    style: .cancel,
                    handler: nil
                )
            )
            alertController.addAction(
                UIAlertAction(title: LocalString._delete_contact, style: .destructive, handler: { _ in
                    let viewToShowSpinner: UIView = self.navigationController?.view ?? self.view
                    MBProgressHUD.showAdded(to: viewToShowSpinner, animated: true)
                    self.viewModel.delete(complete: { [weak self] error in
                        MBProgressHUD.hide(for: viewToShowSpinner, animated: true)
                        if let err = error {
                            err.alertToast()
                            return
                        }
                        self?.delegate?.deleted()
                        let isOnline = self?.isOnline ?? false
                        self?.navigationController?.dismiss(animated: false, completion: {
                            if !isOnline {
                                LocalString._contacts_deleted_offline_hint.alertToastBottom()
                            }
                        })
                    })
                })
            )

            alertController.popoverPresentationController?.sourceView = tableView
            let rect = sender == nil ? self.view.frame : (sender?.frame ?? .zero)
            alertController.popoverPresentationController?.sourceRect = rect
            present(alertController, animated: true, completion: nil)
        case .birthday:
            if viewModel.birthday == nil {
                viewModel.birthday = .init(type: .birthday, value: "", isNew: true)
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        case .share:
            break
        case .organization:
            break
        case .nickName:
            break
        case .title:
            break
        case .gender, .anniversary:
            break
        case .addNewField:
            let sender = tableView.cellForRow(at: indexPath)
            showAddNewFieldAlert(sender: sender)
        }
    }
}

extension ContactEditViewController {
    private func dismissKeyboard() {
        guard let active = activeTextComponent else {
            return
        }
        active.resignFirstResponder()
        activeTextComponent = nil
    }
    
    private func resetNameFieldsIfNeeded() {
        if customView.displayNameField.text?.trim().isEmpty == true {
            customView.displayNameField.text = .empty
            viewModel.getProfile().newDisplayName = .empty
        }
        if customView.firstNameField.text?.trim().isEmpty == true {
            customView.firstNameField.text = .empty
            viewModel.setFirstName(.empty)
        }
        if customView.lastNameField.text?.trim().isEmpty == true {
            customView.lastNameField.text = .empty
            viewModel.setLastName(.empty)
        }
    }

    private func showAddNewFieldAlert(sender: UIView?) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(
                title: LocalString._general_cancel_button,
                style: .cancel,
                handler: nil
            )
        )

        let infoTypes = viewModel.getItemsForAddingNewField()
        for infoType in infoTypes {
            alertController.addAction(
                UIAlertAction(
                    title: infoType.desc,
                    style: .default,
                    handler: { [weak self] _ in
                        guard let tuple = self?.viewModel.addNewItem(of: infoType),
                              let targetIndexPath = tuple.0 else {
                            return
                        }
                        self?.newIndexPath = targetIndexPath
                        if tuple.1 {
                            self?.customView.tableView.insertSections(
                                .init(integer: targetIndexPath.section), with: .automatic
                            )
                        }

                        self?.customView.tableView.reloadSections(
                            .init(integer: targetIndexPath.section),
                            with: .automatic
                        )
                    }
                )
            )
        }
        alertController.popoverPresentationController?.sourceView = sender ?? self.view
        let rect = (sender == nil ? self.view.frame : (sender?.bounds ?? .zero))
        alertController.popoverPresentationController?.sourceRect = rect
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - ContactEditCellDelegate

extension ContactEditViewController: ContactEditCellDelegate {
    func pick(typeInterface: ContactEditTypeInterface) {
        presentContactTypeView(type: typeInterface)
    }

    func toSelectContactGroups(sender: ContactEditEmailCell) {
        let refreshHandler = sender.refreshHandler
        let groupCountInformation = viewModel.getAllContactGroupCounts()
        let selectedGroupIDs = sender.getCurrentlySelectedContactGroupsID()

        let contactGroupView = dependencies.contactViewsFactory.makeGroupMutiSelectView(
            groupCountInformation: groupCountInformation,
            selectedGroupIDs: selectedGroupIDs,
            refreshHandler: refreshHandler
        )
        let contactGroupNav = UINavigationController(rootViewController: contactGroupView)
        show(contactGroupNav, sender: nil)
    }

    func beginEditing(textField: UITextField) {
        activeTextComponent = textField
    }

    private func presentContactTypeView(type: ContactEditTypeInterface) {
        let newView = dependencies.contactViewsFactory.makeTypeView(type: type)
        newView.delegate = self
        self.show(newView, sender: nil)
    }
}

// MARK: - ContactEditTextViewCellDelegate

extension ContactEditViewController: ContactEditTextViewCellDelegate {
    func beginEditing(textView: UITextView) {
        activeTextComponent = textView
    }

    func didChanged() {
        UIView.setAnimationsEnabled(false)
        customView.tableView.beginUpdates()
        customView.tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }
}

// MARK: - Actions

extension ContactEditViewController {
    @objc
    private func doneAction() {
        dismissKeyboard()
        let viewToShowSpinner: UIView = navigationController?.view ?? view
        MBProgressHUD.showAdded(to: viewToShowSpinner, animated: true)

        viewModel.done { [weak self] error in
            guard let self = self else { return }
            MBProgressHUD.hide(for: viewToShowSpinner, animated: true)
            if let error = error {
                self.showErrorBanner(
                    message: error.localizedFailureReason ?? error.localizedDescription
                )
                if error.code == ContactEditViewModel.Constants.emptyDisplayNameError {
                    self.resetNameFieldsIfNeeded()
                }
                return
            }
            self.delegate?.updated()
            self.dismiss(animated: true) { [weak self] in
                if self?.isOnline == false {
                    self?.showErrorBanner(message: LocalString._contacts_saved_offline_hint)
                }
            }
        }
    }

    @objc
    private func cancelAction() {
        dismissKeyboard()
        if viewModel.needsUpdate() {
            let alertController = UIAlertController(
                title: LocalString._warning,
                message: LocalString._changes_will_discarded,
                preferredStyle: .alert
            )
            alertController.addAction(
                UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
            )
            alertController.addAction(
                UIAlertAction(title: LocalString._general_discard, style: .destructive, handler: { _ in
                    self.dismiss(animated: true, completion: nil)
                })
            )
            present(alertController, animated: true, completion: nil)
        } else {
            dismiss(animated: true)
        }
    }

    @objc
    private func selectPhotoAction() {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    private func showErrorBanner(message: String) {
        let banner = PMBanner(
            message: message,
            style: PMBannerNewStyle.error
        )
        banner.show(at: .bottom, on: self)
    }
    
    @objc
    func resetCellButtonColor() {
        // workaround, the add button icon color will be reset when back from background
        customView.tableView.visibleCells
            .compactMap { $0 as? ContactEditAddCell }
            .forEach { $0.setEditing(true, animated: false) }
    }
}

// MARK: - UITableViewDelegate

extension ContactEditViewController: UITableViewDelegate {
    // swiftlint:disable:next function_body_length
    func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        let sectionNumber = indexPath.section
        let row = indexPath.row

        let sections = self.viewModel.getSections()
        let sectionType = sections[sectionNumber]
        switch sectionType {
        case .email_header, .display_name, .encrypted_header:
            assertionFailure("Code should not be here")
        case .emails:
            let emailCount = viewModel.getEmails().count
            if row == emailCount {
                return .insert
            } else {
                return .delete
            }
        case .cellphone:
            let cellCount = viewModel.getCells().count
            if row == cellCount {
                return .insert
            } else {
                return .delete
            }
        case .home_address:
            let addrCount = viewModel.getAddresses().count
            if row == addrCount {
                return .insert
            } else {
                return .delete
            }
        case .url:
            let urlCount = viewModel.getUrls().count
            if row == urlCount {
                return .insert
            } else {
                return .delete
            }
        case .custom_field:
            let fieldCount = viewModel.getFields().count
            if row == fieldCount {
                return .insert
            } else {
                return .delete
            }
        case .birthday:
            if viewModel.birthday == nil {
                return .insert
            } else {
                return .delete
            }
        case .notes, .delete, .share,
             .type3_warning, .type3_error, .type2_warning, .debuginfo:
            return .none
        case .organization:
            return .delete
        case .nickName:
            return .delete
        case .title:
            return .delete
        case .gender:
            return .delete
        case .anniversary:
            return .delete
        case .addNewField:
            return .insert
        }
        return .none
    }

    // swiftlint:disable:next function_body_length
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        dismissKeyboard()

        let section = indexPath.section
        let row = indexPath.row
        let sections = self.viewModel.getSections()
        let sectionType = sections[section]

        if editingStyle == .insert {
            switch sectionType {
            case .emails:
                _ = viewModel.newEmail()
                newIndexPath = indexPath
                customView.tableView.insertRows(at: [indexPath], with: .automatic)
            case .cellphone:
                _ = viewModel.newPhone()
                newIndexPath = indexPath
                customView.tableView.insertRows(at: [indexPath], with: .automatic)
            case .home_address:
                _ = viewModel.newAddress()
                newIndexPath = indexPath
                customView.tableView.insertRows(at: [indexPath], with: .automatic)
            case .addNewField:
                let sender = tableView.cellForRow(at: indexPath)
                showAddNewFieldAlert(sender: sender)
            case .custom_field:
                _ = viewModel.newField()
                newIndexPath = indexPath
                customView.tableView.insertRows(at: [indexPath], with: .automatic)
            case .url:
                _ = viewModel.newUrl()
                newIndexPath = indexPath
                customView.tableView.insertRows(at: [indexPath], with: .automatic)
            case .birthday:
                viewModel.birthday = .init(type: .birthday, value: "", isNew: true)
                tableView.reloadRows(at: [indexPath], with: .automatic)
            default:
                break
            }
            // To update add icon color
            let originalIndexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            customView.tableView.reloadRows(at: [originalIndexPath], with: .none)
        } else if editingStyle == .delete {
            switch sectionType {
            case .emails:
                viewModel.deleteEmail(at: row)
                customView.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .cellphone:
                viewModel.deletePhone(at: row)
                customView.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .home_address:
                viewModel.deleteAddress(at: row)
                customView.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .custom_field:
                viewModel.deleteField(at: row)
                customView.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .url:
                viewModel.deleteUrl(at: row)
                customView.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .gender:
                viewModel.gender = nil
                customView.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .anniversary:
                viewModel.anniversary = nil
                customView.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .organization:
                viewModel.deleteOrganization(at: row)
                customView.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .nickName:
                viewModel.deleteNickName(at: row)
                customView.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .title:
                viewModel.deleteTitle(at: row)
                customView.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .birthday:
                viewModel.birthday = nil
                tableView.reloadRows(at: [indexPath], with: .automatic)
            default:
                break
            }
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: ContactEditConstants.contactDetailsHeaderID
        ) as? ContactSectionHeadView else {
            return nil
        }
        cell.contentView.backgroundColor = ColorProvider.BackgroundNorm
        let sections = viewModel.getSections()
        let sectionType = sections[section]
        if sectionType == .encrypted_header {
            cell.configHeader(title: LocalString._contacts_encrypted_contact_details_title)
        } else if sectionType == .delete || sectionType == .notes {
            cell.configHeader(title: "")
            return cell
        } else if sectionType == .emails {
            cell.configHeader(title: LocalString._contacts_email_addresses_title)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sections = viewModel.getSections()
        let sectionType = sections[section]
        switch sectionType {
        case .encrypted_header, .delete, .emails:
            return UITableView.automaticDimension
        default:
            return 0.0
        }    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sections = viewModel.getSections()
        let sectionType = sections[section]
        switch sectionType {
        case .delete:
            return 0.0
        case .notes:
            if viewModel.isNew() {
                return 0.0
            } else {
                return 0.0
            }
        default:
            return 0.0
        }
    }

    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: - ContactTypeViewControllerDelegate

extension ContactEditViewController: ContactTypeViewControllerDelegate {
    func done(sectionType: ContactEditSectionType) {
        let sections = viewModel.getSections()
        if let sectionIndex = sections.firstIndex(of: sectionType) {
            customView.tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
        } else {
            customView.tableView.reloadData()
        }
    }
}

// MARK: - UI setup

extension ContactEditViewController {
    private func setupUI() {
        doneButton = .init(
            title: LocalString._general_save_action,
            style: .plain,
            target: self,
            action: #selector(self.doneAction)
        )
        let attributes = FontManager.DefaultStrong.foregroundColor(ColorProvider.InteractionNorm)
        doneButton?.setTitleTextAttributes(attributes, for: .normal)
        navigationItem.rightBarButtonItem = doneButton

        cancelButton = IconProvider.cross.toUIBarButtonItem(
            target: self,
            action: #selector(self.cancelAction),
            tintColor: ColorProvider.IconNorm
        )
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.assignNavItemIndentifiers()

        if !viewModel.isNew() {
            title = LocalString._edit_contact
        }
        view.backgroundColor = ColorProvider.BackgroundNorm

        customView.displayNameField.text = viewModel.getProfile().newDisplayName
        customView.displayNameField.delegate = self

        customView.firstNameField.text = viewModel.structuredName?.firstName
        customView.firstNameField.delegate = self

        customView.lastNameField.text = viewModel.structuredName?.lastName
        customView.lastNameField.delegate = self

        let profilePicture = viewModel.getProfilePicture()
        customView.profileImageView.image = profilePicture
        if profilePicture == nil {
            customView.photoButton.setTitle(L10n.ContactEdit.addPhoto, for: .normal)
        } else {
            customView.photoButton.setTitle(L10n.ContactEdit.editPhoto, for: .normal)
        }


        emptyBackButtonTitleForNextView()
        generateAccessibilityIdentifiers()
    }

    // swiftlint:disable:next function_body_length
    private func setupTableView() {
        customView.tableView.delegate = self
        customView.tableView.dataSource = self

        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactDetailsHeaderView, bundle: nil),
            forHeaderFooterViewReuseIdentifier: ContactEditConstants.contactDetailsHeaderID
        )
        customView.tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: ContactEditConstants.contactEditDateCell
        )
        customView.tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: ContactEditConstants.instructions
        )
        customView.tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: ContactEditConstants.recipeType
        )
        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactAddEmailCell, bundle: nil),
            forCellReuseIdentifier: ContactEditConstants.contactAddEmailCell
        )
        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactEditAddCell, bundle: nil),
            forCellReuseIdentifier: ContactEditConstants.contactEditAddCell
        )
        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactEditAddressCell, bundle: nil),
            forCellReuseIdentifier: ContactEditConstants.contactEditAddressCell
        )
        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactEditAddCell, bundle: nil),
            forCellReuseIdentifier: ContactEditConstants.contactEditDeleteCell
        )
        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactEditEmailCell, bundle: nil),
            forCellReuseIdentifier: ContactEditConstants.contactEditEmailCell
        )
        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactEditCellphoneCell, bundle: nil),
            forCellReuseIdentifier: ContactEditConstants.contactEditCellphoneCell
        )
        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactEditCellInfoCell, bundle: nil),
            forCellReuseIdentifier: ContactEditConstants.contactEditCellInfoCell
        )
        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactEditFieldCell, bundle: nil),
            forCellReuseIdentifier: ContactEditConstants.contactEditFieldCell
        )
        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactEditTextViewCell, bundle: nil),
            forCellReuseIdentifier: ContactEditConstants.contactEditTextViewCell
        )
        customView.tableView.register(
            .init(nibName: ContactEditConstants.contactEditUrlCell, bundle: nil),
            forCellReuseIdentifier: ContactEditConstants.contactEditUrlCell
        )

        customView.tableView.estimatedRowHeight = 70
        customView.tableView.rowHeight = UITableView.automaticDimension
        customView.tableView.isEditing = true
        customView.tableView.noSeparatorsBelowFooter()
    }

    private func setupPhotoButton() {
        customView.photoButton.addTarget(self, action: #selector(self.selectPhotoAction), for: .touchUpInside)
    }
}

extension ContactEditViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        customView.tableView.contentInset.bottom = 0
        UIView.animate(
            withDuration: keyboardInfo.duration,
            delay: 0,
            options: keyboardInfo.animationOption,
            animations: { () in
                self.view.layoutIfNeeded()
            }, completion: nil
        )
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            customView.tableView.contentInset.bottom = 0
            return
        }
        let keyboardHeight = customView.tableView.superview?
            .convert(keyboardFrame.cgRectValue, from: nil).size.height ?? 0
        customView.tableView.contentInset.bottom = keyboardHeight
        view.setNeedsUpdateConstraints()
        view.setNeedsLayout()
        UIView.animate(
            withDuration: keyboardInfo.duration,
            delay: 0,
            options: keyboardInfo.animationOption,
            animations: { () in
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ContactEditViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        let itemProviders = results.map(\.itemProvider)
        guard let itemProvider = itemProviders.first,
              itemProvider.canLoadObject(ofClass: UIImage.self) else {
            return
        }

        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
            if let image = image as? UIImage {
                DispatchQueue.main.async {
                    self?.setProfilePhoto(image: image)
                }
            }
        }
    }

    private func setProfilePhoto(image: UIImage) {
        viewModel.setProfilePicture(image: image)
        if viewModel.getProfilePicture() != nil {
            customView.photoButton.setTitle(L10n.ContactEdit.editPhoto, for: .normal)
        } else {
            customView.photoButton.setTitle(L10n.ContactEdit.addPhoto, for: .normal)
        }

        customView.profileImageView.backgroundColor = .clear
        customView.profileImageView.image = image
    }
}

// MARK: - UITextFieldDelegate

extension ContactEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextComponent = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == customView.displayNameField {
            let profile = viewModel.getProfile()
            profile.newDisplayName = textField.text ?? .empty
        } else if textField == customView.firstNameField {
            viewModel.setFirstName(textField.text ?? .empty)
        } else if textField == customView.lastNameField {
            viewModel.setLastName(textField.text ?? .empty)
        }
    }
}

extension ContactEditViewController {
    enum ContactEditConstants {
        static let contactDetailsHeaderView = "ContactSectionHeadView"
        static let contactDetailsHeaderID = "contact_section_head_view"
        static let contactEditAddCell = "ContactEditAddCell"
        static let contactEditDeleteCell = "ContactEditDeleteCell"
        static let contactEditEmailCell = "ContactEditEmailCell"
        static let contactAddEmailCell = "ContactAddEmailCell"
        static let contactEditCellphoneCell = "ContactEditPhoneCell"
        static let contactEditAddressCell = "ContactEditAddressCell"
        static let contactEditCellInfoCell = "ContactEditInformationCell"
        static let contactEditFieldCell = "ContactEditFieldCell"
        static let contactEditTextViewCell = "ContactEditTextViewCell"
        static let contactEditUrlCell = "ContactEditUrlCell"
        static let contactEditDateCell = "ContactEditDateCell"
        static let instructions = "Instructions"
        static let recipeType = "RecipeType"
    }
}

extension ContactEditViewController: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}

extension UITableView {
    func sizeHeaderToFit() {
        guard let headerView = tableHeaderView else { return }

        let newHeight = headerView.systemLayoutSizeFitting(
            CGSize(
                width: frame.width,
                height: .greatestFiniteMagnitude
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )
        var frame = headerView.frame

        if newHeight.height != frame.height {
            frame.size.height = newHeight.height
            frame.size.width = self.frame.width
            headerView.frame = frame
            tableHeaderView = headerView
        }
    }
}
