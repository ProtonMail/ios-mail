//
//  ContactEditViewController.swift
//  Proton Mail - Created on 3/6/17.
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

import Foundation
import Photos
import MBProgressHUD
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import ProtonCore_PaymentsUI

protocol ContactEditViewControllerDelegate: AnyObject {
    func deleted()
    func updated()
}

final class ContactEditViewController: UIViewController, AccessibleView {
    let viewModel: ContactEditViewModel

    fileprivate let kContactDetailsHeaderView: String      = "ContactSectionHeadView"
    fileprivate let kContactDetailsHeaderID: String        = "contact_section_head_view"

    // const cell identifier
    fileprivate let kContactEditAddCell: String       = "ContactEditAddCell"
    fileprivate let kContactEditDeleteCell: String    = "ContactEditDeleteCell"
    fileprivate let kContactEditEmailCell: String     = "ContactEditEmailCell"
    fileprivate let kContactAddEmailCell: String      = "ContactAddEmailCell"
    fileprivate let kContactEditCellphoneCell: String = "ContactEditPhoneCell"
    fileprivate let kContactEditAddressCell: String   = "ContactEditAddressCell"
    fileprivate let kContactEditCellInfoCell: String  = "ContactEditInformationCell"
    fileprivate let kContactEditFieldCell: String     = "ContactEditFieldCell"
    fileprivate let kContactEditTextViewCell: String  = "ContactEditTextViewCell"
    fileprivate let kContactEditUpgradeCell: String   = "ContactEditUpgradeCell"
    fileprivate let kContactEditUrlCell: String       = "ContactEditUrlCell"

    private var imagePicker: UIImagePickerController?
    private var paymentsUI: PaymentsUI?

    fileprivate var doneItem: UIBarButtonItem!
    private var cancelItem: UIBarButtonItem!
    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomOffset: NSLayoutConstraint!

    @IBOutlet weak var topContainerView: UIView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var selectProfilePictureLabel: UILabel!
    @IBOutlet weak var editPhotoButton: UIButton!

    @IBAction func tappedSelectProfilePictureButton(_ sender: UIButton) {
        func checkPermission() {
            let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
            switch photoAuthorizationStatus {
            case .authorized, .restricted, .denied:
                break
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization { _ in }
            default: break
            }
        }
        checkPermission()

        if let imagePicker = self.imagePicker {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
    }

    weak var delegate: ContactEditViewControllerDelegate?

    var activeText: UIResponder?

    var newIndexPath: IndexPath?

    fileprivate var showingUpgrade: Bool = false

    init(viewModel: ContactEditViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ContactEditViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.doneItem = UIBarButtonItem(title: LocalString._general_save_action,
                                        style: UIBarButtonItem.Style.plain,
                                        target: self, action: #selector(ContactEditViewController.doneAction))
        self.cancelItem = IconProvider.cross
            .toUIBarButtonItem(target: self,
                               action: #selector(self.cancelAction(_:)),
                               tintColor: ColorProvider.IconNorm)

        let attributes = FontManager.DefaultStrong.foregroundColor(ColorProvider.InteractionNorm)
        self.doneItem.setTitleTextAttributes(attributes, for: .normal)
        self.navigationItem.rightBarButtonItem = doneItem
        self.navigationItem.leftBarButtonItem = cancelItem
        self.navigationItem.assignNavItemIndentifiers()

        if !viewModel.isNew() {
            self.title = LocalString._edit_contact
        }

        self.editPhotoButton.setTitleColor(ColorProvider.InteractionNorm, for: .normal)

        UITextField.appearance().tintColor = ColorProvider.TextHint
        self.displayNameField.text = viewModel.getProfile().newDisplayName
        self.displayNameField.delegate = self

        self.view.backgroundColor = ColorProvider.BackgroundNorm
        self.topContainerView.backgroundColor = ColorProvider.BackgroundNorm

        configureTableView()

        // profile image picker
        self.imagePicker = UIImagePickerController()
        self.imagePicker?.delegate = self
        self.profilePictureImageView.layer.cornerRadius = self.profilePictureImageView.frame.size.height / 2
        self.profilePictureImageView.layer.masksToBounds = true
        self.profilePictureImageView.backgroundColor = UIColor.lightGray

        self.profilePictureImageView.image = viewModel.getProfilePicture()
        if viewModel.getProfilePicture() != nil {
            selectProfilePictureLabel.text = LocalString._contacts_edit_profile_picture
        } else {
            selectProfilePictureLabel.text = LocalString._contacts_add_profile_picture
        }

        // name textfield bottom border
        displayNameField.addBottomBorder()
        emptyBackButtonTitleForNextView()
        generateAccessibilityIdentifiers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
        dismissKeyboard()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
        var insets = self.tableView.contentInset
        insets.bottom = 100
        self.tableView.contentInset = insets
    }

    private func configureTableView() {
        let nib = UINib(nibName: kContactDetailsHeaderView, bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: kContactDetailsHeaderID)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactEditDateCell")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Instructions")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecipeType")
        self.tableView.register(UINib(nibName: kContactAddEmailCell, bundle: nil), forCellReuseIdentifier: kContactAddEmailCell)
        self.tableView.register(UINib(nibName: kContactEditAddCell, bundle: nil), forCellReuseIdentifier: kContactEditAddCell)
        self.tableView.register(UINib(nibName: kContactEditAddressCell, bundle: nil), forCellReuseIdentifier: kContactEditAddressCell)
        self.tableView.register(UINib(nibName: kContactEditAddCell, bundle: nil), forCellReuseIdentifier: kContactEditDeleteCell)
        self.tableView.register(UINib(nibName: kContactEditEmailCell, bundle: nil), forCellReuseIdentifier: kContactEditEmailCell)
        self.tableView.register(UINib(nibName: kContactEditCellphoneCell, bundle: nil), forCellReuseIdentifier: kContactEditCellphoneCell)
        self.tableView.register(UINib(nibName: kContactEditCellInfoCell, bundle: nil), forCellReuseIdentifier: kContactEditCellInfoCell)
        self.tableView.register(UINib(nibName: kContactEditFieldCell, bundle: nil), forCellReuseIdentifier: kContactEditFieldCell)
        self.tableView.register(UINib(nibName: kContactEditTextViewCell, bundle: nil), forCellReuseIdentifier: kContactEditTextViewCell)
        self.tableView.register(UINib(nibName: kContactEditUpgradeCell, bundle: nil), forCellReuseIdentifier: kContactEditUpgradeCell)
        self.tableView.register(UINib(nibName: kContactEditUrlCell, bundle: nil), forCellReuseIdentifier: kContactEditUrlCell)

        self.tableView.estimatedRowHeight = 70
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.backgroundColor = ColorProvider.BackgroundNorm

        self.tableView.isEditing = true
        self.tableView.noSeparatorsBelowFooter()
    }

    private func presentContactTypeView(type: ContactEditTypeInterface) {
        let viewModel = ContactTypeViewModelImpl(t: type)
        let newView = ContactTypeViewController(viewModel: viewModel)
        newView.delegate = self
        self.show(newView, sender: nil)
    }

    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismissKeyboard()

        if self.viewModel.needsUpdate() {
            let alertController = UIAlertController(title: LocalString._warning,
                                                    message: LocalString._changes_will_discarded,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._general_discard, style: .destructive, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
            present(alertController, animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        dismissKeyboard()

        let v: UIView = self.navigationController?.view ?? self.view
        MBProgressHUD.showAdded(to: v, animated: true)

        viewModel.done { [weak self] (error: NSError?) in
            guard let self = self else { return }
            MBProgressHUD.hide(for: v, animated: true)
            if let error = error {
                error.alertToast()
                return
            }
            self.delegate?.updated()
            let isOnline = self.isOnline
            self.dismiss(animated: true) {
                if !isOnline {
                    LocalString._contacts_saved_offline_hint.alertToastBottom()
                }
            }
        }
    }

    func dismissKeyboard() {
        if let t = self.activeText {
            t.resignFirstResponder()
            self.activeText = nil
        }
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension ContactEditViewController: NSNotificationCenterKeyboardObserverProtocol {

    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        tableViewBottomOffset.constant = 0.0
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            tableViewBottomOffset.constant = keyboardSize.height
        }
        self.view.setNeedsUpdateConstraints()
        self.view.setNeedsLayout()
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

extension ContactEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeText = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        let profile = viewModel.getProfile()
        profile.newDisplayName = textField.text!
    }
}

// type picker
extension ContactEditViewController: ContactEditCellDelegate, ContactEditTextViewCellDelegate {

    func pick(typeInterface: ContactEditTypeInterface, sender: UITableViewCell) {
        dismissKeyboard()
        presentContactTypeView(type: typeInterface)
    }

    func toSelectContactGroups(sender: ContactEditEmailCell) {
        dismissKeyboard()
        let refreshHandler = sender.refreshHandler
        let groupCountInformation = viewModel.getAllContactGroupCounts()
        let selectedGroupIDs = sender.getCurrentlySelectedContactGroupsID()

        let contactGroupViewModel = ContactGroupMutiSelectViewModelImpl(user: viewModel.user,
                                                                        groupCountInformation: groupCountInformation,
                                                                        selectedGroupIDs: selectedGroupIDs,
                                                                        refreshHandler: refreshHandler)
        let contactGroupView = ContactGroupsViewController(viewModel: contactGroupViewModel)
        let contactGroupNav = UINavigationController(rootViewController: contactGroupView)
        self.show(contactGroupNav, sender: nil)
    }

    func beginEditing(textField: UITextField) {
        self.activeText = textField
    }

    func beginEditing(textView: UITextView) {
        self.activeText = textView
    }

    func featureBlocked(textView: UITextView) {
        dismissKeyboard()
        self.upgrade()
    }

    func didChanged(textView: UITextView) {
        UIView.setAnimationsEnabled(false)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }

    func synced(_ lock: Any, closure: () -> Void) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }

}

//
extension ContactEditViewController: ContactTypeViewControllerDelegate {
    func done(sectionType: ContactEditSectionType) {
        let sections = self.viewModel.getSections()
        if let sectionIndex = sections.firstIndex(of: sectionType) {
            tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
        } else {
            tableView.reloadData()
        }
    }
}

extension ContactEditViewController: ContactUpgradeCellDelegate {
    func upgrade() {
        if !showingUpgrade {
            self.showingUpgrade = true
            presentPlanUpgrade()
        }
    }

    private func presentPlanUpgrade() {
        self.paymentsUI = PaymentsUI(payments: self.viewModel.user.payments, clientApp: .mail, shownPlanNames: Constants.shownPlanNames)
        self.paymentsUI?.showUpgradePlan(presentationType: .modal,
                                         backendFetch: true) { _ in }
    }
}

// MARK: - UITableViewDataSource
extension ContactEditViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionCount()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sections = self.viewModel.getSections()
        let s = sections[section]
        switch s {
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
            return 1 + viewModel.getUrls().count
        case .information:
            return 1 + viewModel.getInformations().count
        case .custom_field:
            return 1 + viewModel.getFields().count
        case .notes:
            return 1
        case .delete:
            return 1
        case .upgrade:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sections = self.viewModel.getSections()
        var outCell: UITableViewCell?
        let section = indexPath.section
        let row = indexPath.row
        let s = sections[section]

        var firstResponder: Bool = false
        if let index = newIndexPath, index == indexPath {
            firstResponder = true
            newIndexPath = nil
        }

        switch s {
        case .display_name, .encrypted_header:
            assert(false, "Code should not be here")
        case .emails:
            let emailCount = viewModel.getEmails().count
            if row == emailCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: LocalString._contacts_add_new_email)
                cell.selectionStyle = .default
                outCell = cell
            } else {
                if viewModel.isNew() {
                    let cell = tableView.dequeueReusableCell(withIdentifier: kContactAddEmailCell, for: indexPath) as! ContactAddEmailCell
                    cell.selectionStyle = .none
                    cell.configCell(obj: viewModel.getEmails()[row], callback: self, becomeFirstResponder: firstResponder)
                    outCell = cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditEmailCell, for: indexPath) as! ContactEditEmailCell
                    cell.selectionStyle = .none
                    cell.configCell(obj: viewModel.getEmails()[row], callback: self, becomeFirstResponder: firstResponder)
                    outCell = cell
                }
            }
        case .cellphone:
            let cellCount = viewModel.getCells().count
            if row == cellCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: LocalString._contacts_add_new_phone)
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditCellphoneCell, for: indexPath) as! ContactEditPhoneCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getCells()[row], callback: self, becomeFirstResponder: firstResponder)
                outCell = cell
            }
        case .home_address:
            let addrCount = viewModel.getAddresses().count
            if row == addrCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: LocalString._contacts_add_new_address)
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddressCell, for: indexPath) as! ContactEditAddressCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getAddresses()[row], callback: self, becomeFirstResponder: firstResponder)
                outCell = cell
            }
        case .url:
            let urlCount = viewModel.getUrls().count
            if row == urlCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: LocalString._add_new_url)
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditUrlCell, for: indexPath) as! ContactEditUrlCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getUrls()[row], callback: self, becomeFirstResponder: firstResponder)
                outCell = cell
            }
        case .information:
            let orgCount = viewModel.getInformations().count
            if row == orgCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: LocalString._contacts_add_new_field)
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditCellInfoCell, for: indexPath) as! ContactEditInformationCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getInformations()[row], callback: self, becomeFirstResponder: firstResponder)
                outCell = cell
            }
        case .custom_field:
            let fieldCount = viewModel.getFields().count
            if row == fieldCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: LocalString._contacts_add_new_custom_field)
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditFieldCell, for: indexPath) as! ContactEditFieldCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getFields()[row], callback: self, becomeFirstResponder: firstResponder)
                outCell = cell
            }
        case .notes:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditTextViewCell, for: indexPath) as! ContactEditTextViewCell
            cell.configCell(obj: viewModel.getNotes(), paid: true, callback: self)
            cell.selectionStyle = .none
            outCell = cell
        case .delete:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditDeleteCell, for: indexPath) as! ContactEditAddCell
            cell.configCell(value: LocalString._delete_contact,
                            color: ColorProvider.NotificationError)
            cell.selectionStyle = .default
            outCell = cell
        case .upgrade:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditUpgradeCell, for: indexPath) as! ContactEditUpgradeCell
            cell.configCell(delegate: self)
            cell.selectionStyle = .none
            outCell = cell
        default:
            break
        }

        if outCell == nil { // default
            outCell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath)
            outCell?.selectionStyle = .none
        }
        return outCell!
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let section = indexPath.section
        let row = indexPath.row

        let sections = self.viewModel.getSections()
        let s = sections[section]
        switch s {
        case .email_header, .display_name, .encrypted_header:
            assert(false, "Code should not be here")
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
        case .information:
            let orgCount = viewModel.getInformations().count
            if row == orgCount {
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
        case .notes, .delete, .upgrade, .share,
             .type3_warning, .type3_error, .type2_warning, .debuginfo:
            return .none
        }
        return .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        let section = indexPath.section
        let sections = self.viewModel.getSections()
        let s = sections[section]
        switch s {
        case .upgrade:
            return false
        default:
            return true
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        dismissKeyboard()

        let section = indexPath.section
        let row = indexPath.row
        let sections = self.viewModel.getSections()
        let s = sections[section]

        if editingStyle == . insert {
            switch s {
            case .emails:
                _ = self.viewModel.newEmail()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            case .cellphone:
                _ = self.viewModel.newPhone()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            case .home_address:
                _ = self.viewModel.newAddress()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            case .information:
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                // get left info types
                let infoTypes = viewModel.getLeftInfoTypes()
                for t in infoTypes {
                    alertController.addAction(UIAlertAction(title: t.desc, style: .default, handler: { (action) -> Void in
                        _ = self.viewModel.newInformation(type: t)
                        self.newIndexPath = indexPath
                        self.tableView.insertRows(at: [indexPath], with: .automatic)
                    }))
                }

                let sender = tableView.cellForRow(at: indexPath)
                alertController.popoverPresentationController?.sourceView = sender ?? self.view
                alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.bounds)
                present(alertController, animated: true, completion: nil)
            case .custom_field:
                _ = self.viewModel.newField()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            case .url:
                _ = viewModel.newUrl()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            default:
                break
            }
        } else if editingStyle == .delete {
            switch s {
            case .emails:
                self.viewModel.deleteEmail(at: row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .cellphone:
                self.viewModel.deletePhone(at: row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .home_address:
                self.viewModel.deleteAddress(at: row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .information:
                self.viewModel.deleteInformation(at: row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .custom_field:
                self.viewModel.deleteField(at: row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            case .url:
                self.viewModel.deleteUrl(at: row)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            default:
                break
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension ContactEditViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: kContactDetailsHeaderID) as? ContactSectionHeadView else {
            return nil
        }
        cell.contentView.backgroundColor = ColorProvider.BackgroundNorm
        let sections = viewModel.getSections()
        let sc = sections[section]
        if sc == .encrypted_header {
            cell.configHeader(title: LocalString._contacts_encrypted_contact_details_title, signed: false)
        } else if sc == .delete || sc == .notes {
            cell.configHeader(title: "", signed: false)
            return cell
        } else if sc == .emails {
            cell.configHeader(title: LocalString._contacts_email_addresses_title, signed: false)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sections = viewModel.getSections()
        let s = sections[section]
        switch s {
        case .encrypted_header, .delete, .emails:
            return 38.0
        default:
            return 0.0
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sections = viewModel.getSections()
        let s = sections[section]
        switch s {
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

    // TODO: use autolayout
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sections = viewModel.getSections()
        if sections[indexPath.section] == .notes {
            return UITableView.automaticDimension
        }

        if sections[indexPath.section] == .home_address {
            let count = viewModel.getAddresses().count
            if indexPath.row != count {
                return 180.0
            }
        }

        if sections[indexPath.section] == .upgrade {
            return 200 //  280.0
        }

        if sections[indexPath.section] == .emails {
            let emailCount = viewModel.getEmails().count

            if viewModel.isNew() || indexPath.row == emailCount {
                return 48.0
            } else {
                return 48.0 * 2
            }
        }

        return 48.0
    }

    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismissKeyboard()
        tableView.deselectRow(at: indexPath, animated: true)

        let sections = viewModel.getSections()
        let section = indexPath.section
        let row = indexPath.row
        let s = sections[section]

        switch s {
        case .email_header, .display_name, .encrypted_header, .notes,
             .type2_warning, .type3_error, .type3_warning, .debuginfo:
            break
        // assert(false, "Code should not be here")
        case .emails:
            let emailCount = viewModel.getEmails().count
            if row == emailCount {
                _ = viewModel.newEmail()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .cellphone:
            let cellCount = viewModel.getCells().count
            if row == cellCount {
                _ = viewModel.newPhone()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .home_address:
            let addrCount = viewModel.getAddresses().count
            if row == addrCount {
                _ = viewModel.newAddress()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .url:
            let urlCount = viewModel.getUrls().count
            if row == urlCount {
                _ = viewModel.newUrl()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .information:
            let orgCount = viewModel.getInformations().count
            if row == orgCount {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                // get left info types
                let infoTypes = viewModel.getLeftInfoTypes()
                for t in infoTypes {
                    alertController.addAction(UIAlertAction(title: t.desc, style: .default, handler: { (action) -> Void in
                        _ = self.viewModel.newInformation(type: t)
                        self.newIndexPath = indexPath
                        self.tableView.insertRows(at: [indexPath], with: .automatic)
                    }))
                }
                let sender = tableView.cellForRow(at: indexPath)
                alertController.popoverPresentationController?.sourceView = sender ?? self.view
                alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.bounds)
                present(alertController, animated: true, completion: nil)
            }
        case .custom_field:
            let fieldCount = viewModel.getFields().count
            if row == fieldCount {
                _ = viewModel.newField()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .delete:

            let sender = tableView.cellForRow(at: indexPath)
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._delete_contact, style: .destructive, handler: { (action) -> Void in
                let v: UIView = self.navigationController?.view ?? self.view
                MBProgressHUD.showAdded(to: v, animated: true)
                self.viewModel.delete(complete: { [weak self] (error) in
                    MBProgressHUD.hide(for: v, animated: true)
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
            }))

            alertController.popoverPresentationController?.sourceView = tableView
            alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.frame)
            present(alertController, animated: true, completion: nil)
        case .upgrade, .share:
            break
        }

    }

}

extension ContactEditViewController: UINavigationControllerDelegate {

}

extension ContactEditViewController: UIImagePickerControllerDelegate {
    @objc func imagePickerController(_ picker: UIImagePickerController,
                                     didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var newImage: UIImage?

        if let possibleImage = info[.editedImage] as? UIImage {
            newImage = possibleImage
        } else if let possibleImage = info[.originalImage] as? UIImage {
            newImage = possibleImage
        } else {
            newImage = nil
        }

        viewModel.setProfilePicture(image: newImage)
        if viewModel.getProfilePicture() != nil {
            selectProfilePictureLabel.text = LocalString._contacts_edit_profile_picture
        } else {
            selectProfilePictureLabel.text = LocalString._contacts_add_profile_picture
        }

        if let image = newImage {
            self.profilePictureImageView.backgroundColor = UIColor.clear
            self.profilePictureImageView.image = image
        } else {
            self.profilePictureImageView.backgroundColor = UIColor.lightGray
            self.profilePictureImageView.image = nil
        }

        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
