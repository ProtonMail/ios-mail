//
//  ContactEditViewController.swift
//  ProtonMail - Created on 3/6/17.
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


import Foundation
import Photos
import MBProgressHUD

protocol ContactEditViewControllerDelegate {
    func deleted()
    func updated()
}

class ContactEditViewController: ProtonMailViewController, ViewModelProtocol {
    typealias viewModelType = ContactEditViewModel
    
    fileprivate var viewModel : ContactEditViewModel!
    
    //
    private let kInvalidEmailShakeTimes: Float        = 3.0
    private let kInvalidEmailShakeOffset: CGFloat     = 10.0
    fileprivate var origFrameHeight : CGFloat         = 0.0
    
    fileprivate let kContactDetailsHeaderView : String      = "ContactSectionHeadView"
    fileprivate let kContactDetailsHeaderID : String        = "contact_section_head_view"
    
    //const cell identifier
    fileprivate let kContactEditAddCell: String       = "ContactEditAddCell"
    fileprivate let kContactEditDeleteCell: String    = "ContactEditDeleteCell"
    fileprivate let kContactEditEmailCell: String     = "ContactEditEmailCell"
    fileprivate let kContactAddEmailCell: String      = "ContactAddEmailCell"
    fileprivate let kContactEditCellphoneCell: String = "ContactEditCellphoneCell"
    fileprivate let kContactEditAddressCell: String   = "ContactEditAddressCell"
    fileprivate let kContactEditCellInfoCell: String  = "ContactEditInformationCell"
    fileprivate let kContactEditFieldCell: String     = "ContactEditFieldCell"
    fileprivate let kContactEditTextViewCell: String  = "ContactEditTextViewCell"
    fileprivate let kContactEditUpgradeCell: String   = "ContactEditUpgradeCell"
    fileprivate let kContactEditUrlCell: String       = "ContactEditUrlCell"
    
    //const segue
    fileprivate let kToContactTypeSegue : String      = "toContactTypeSegue"
    fileprivate let kToSelectContactGroupSegue: String = "toSelectContactGroupSegue"
    fileprivate let kToUpgradeAlertSegue : String     = "toUpgradeAlertSegue"
    
    private var imagePicker: UIImagePickerController? = nil
    
    //
    fileprivate var doneItem: UIBarButtonItem!
    @IBOutlet weak var cancelItem: UIBarButtonItem!
    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomOffset: NSLayoutConstraint!
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var selectProfilePictureLabel: UILabel!
    @IBAction func tappedSelectProfilePictureButton(_ sender: UIButton) {
        func checkPermission() {
            let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
            switch photoAuthorizationStatus {
            case .authorized:
                print("Access is granted by user")
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({
                    (newStatus) in
                    print("status is \(newStatus)")
                    if newStatus == PHAuthorizationStatus.authorized {
                        
                    }
                })
            case .restricted:
                print("User do not have access to photo album.")
            case .denied:
                print("User has denied the permission.")
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
    
    var delegate : ContactEditViewControllerDelegate?
    
    var activeText : UIResponder? = nil
    
    var newIndexPath : IndexPath? = nil
    
    fileprivate var showingUpgrade : Bool = false
    
    func set(viewModel: ContactEditViewModel) {
        self.viewModel = viewModel
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.doneItem = UIBarButtonItem(title: LocalString._general_done_button,
                                        style: UIBarButtonItem.Style.plain,
                                        target: self, action: #selector(ContactEditViewController.doneAction))
        self.navigationItem.rightBarButtonItem = doneItem
        
        if viewModel.isNew() {
            self.title = LocalString._contacts_add_contact
        } else {
            self.title = LocalString._update_contact
        }
        doneItem.title = LocalString._general_save_action
        
        UITextField.appearance().tintColor = UIColor.ProtonMail.Gray_999DA1
        self.displayNameField.text = viewModel.getProfile().newDisplayName
        self.displayNameField.delegate = self
        
        let nib = UINib(nibName: kContactDetailsHeaderView, bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: kContactDetailsHeaderID)
        self.tableView.estimatedRowHeight = 70
        self.tableView.rowHeight = UITableView.automaticDimension
        
        self.tableView.isEditing = true
        self.tableView.noSeparatorsBelowFooter()
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToContactTypeSegue {
            let contactTypeViewController = segue.destination as! ContactTypeViewController
            contactTypeViewController.deleget = self
            let type = sender as! ContactEditTypeInterface
            sharedVMService.contactTypeViewModel(contactTypeViewController, type: type)
        } else if segue.identifier == kToUpgradeAlertSegue {
            let popup = segue.destination as! UpgradeAlertViewController
            sharedVMService.upgradeAlert(contacts: popup)
            popup.delegate = self
            self.setPresentationStyleForSelfController(self, presentingController: popup, style: .overFullScreen)
        } else if segue.identifier == kToSelectContactGroupSegue {
            let destination = segue.destination as! ContactGroupsViewController
            let refreshHandler = (sender as! ContactEditEmailCell).refreshHandler
            let groupCountInformation = viewModel.getAllContactGroupCounts()
            let selectedGroupIDs = (sender as! ContactEditEmailCell).getCurrentlySelectedContactGroupsID()
            sharedVMService.contactSelectContactGroupsViewModel(destination,
                                                                user: self.viewModel.user,
                                                                groupCountInformation: groupCountInformation,
                                                                selectedGroupIDs: selectedGroupIDs,
                                                                refreshHandler: refreshHandler)
        }
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        
        //show confirmation first if anything changed
        if self.viewModel.needsUpdate() {
            let alertController = UIAlertController(title: LocalString._do_you_want_to_save_the_unsaved_changes,
                                                    message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._general_save_action, style: .default, handler: { (action) -> Void in
                //save and dismiss
                self.doneAction(self.doneItem)
            }))
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._discard_changes, style: .destructive, handler: { (action) -> Void in
                //discard and dismiss
                self.dismiss(animated: true, completion: nil)
            }))
            alertController.popoverPresentationController?.barButtonItem = sender
            alertController.popoverPresentationController?.sourceRect = self.view.frame
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
        
        let v : UIView = self.navigationController?.view ?? self.view
        MBProgressHUD.showAdded(to: v, animated: true)
        
        viewModel.done { (error : NSError?) in
            MBProgressHUD.hide(for: v, animated: true)
            if error == nil {
                self.delegate?.updated()
                self.dismiss(animated: true, completion: nil)
            } else {
                error!.alertToast()
            }
        }
    }
    
    func dismissKeyboard() {
        if let t = self.activeText {
            t.resignFirstResponder()
            self.activeText = nil
        }
    }
    
    func shouldShowSideMenu() -> Bool {
        return false
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
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        let profile = viewModel.getProfile()
        profile.newDisplayName = textField.text!
    }
}


//type picker
extension ContactEditViewController: ContactEditCellDelegate, ContactEditTextViewCellDelegate {
    
    func pick(typeInterface: ContactEditTypeInterface, sender: UITableViewCell) {
        dismissKeyboard()
        self.performSegue(withIdentifier: kToContactTypeSegue, sender: typeInterface)
    }
    
    func toSelectContactGroups(sender: ContactEditEmailCell) {
        self.performSegue(withIdentifier: kToSelectContactGroupSegue,
                          sender: sender)
    }
    
    //reuseable
    func beginEditing(textField: UITextField) {
        self.activeText = textField
    }
    
    func beginEditing(textView: UITextView) {
        self.activeText = textView
    }
    
    func featureBlocked() {
        self.dismissKeyboard()
        self.upgrade()
    }
    
    func featureBlocked(textView: UITextView) {
        dismissKeyboard()
        self.upgrade()
    }
    
    func didChanged(textView: UITextView) {
        if #available(iOS 11.0, *) {
            UIView.setAnimationsEnabled(false)
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        } else {
            synced(self, closure: {
                UIView.setAnimationsEnabled(false)
                if let active = self.activeText, active == textView {
                    if let cell = textView.superview?.superview as? UITableViewCell, let _ = self.tableView.indexPath(for: cell) {
                        self.tableView.beginUpdates()
                        self.tableView.endUpdates()
                    }
                }
                UIView.setAnimationsEnabled(true)
            })
        }
    }
    
    func synced(_ lock: Any, closure: () -> ()) {
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

extension ContactEditViewController : ContactUpgradeCellDelegate {
    func upgrade() {
        if !showingUpgrade {
            self.showingUpgrade = true
            self.performSegue(withIdentifier: kToUpgradeAlertSegue, sender: self)
        }
    }
}

extension ContactEditViewController : UpgradeAlertVCDelegate {
    func postToPlan() {
        NotificationCenter.default.post(name: .switchView,
                                        object: DeepLink(MenuCoordinatorNew.Destination.plan.rawValue))
    }
    func goPlans() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true) {
                self.postToPlan()
            }
        } else {
            self.postToPlan()
        }
    }
    
    func learnMore() {
        UIApplication.shared.openURL(.paidPlans)
    }
    
    func cancel() {
        self.showingUpgrade = false
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
        var outCell : UITableViewCell?
        let section = indexPath.section
        let row = indexPath.row
        let s = sections[section]
        
        var firstResponder : Bool = false
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
                cell.configCell(obj: viewModel.getCells()[row], paid: viewModel.paidUser(), callback: self, becomeFirstResponder: firstResponder)
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
                cell.configCell(obj: viewModel.getAddresses()[row], paid: viewModel.paidUser(), callback: self, becomeFirstResponder: firstResponder)
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
                cell.configCell(obj: viewModel.getUrls()[row], paid: viewModel.paidUser(), callback: self, becomeFirstResponder: firstResponder)
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
                cell.configCell(obj: viewModel.getInformations()[row], paid: viewModel.paidUser(), callback: self, becomeFirstResponder: firstResponder)
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
                cell.configCell(obj: viewModel.getFields()[row], paid: viewModel.paidUser(), callback: self, becomeFirstResponder: firstResponder)
                outCell = cell
            }
        case .notes:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditTextViewCell, for: indexPath) as! ContactEditTextViewCell
            cell.configCell(obj: viewModel.getNotes(), paid: self.viewModel.paidUser(), callback: self)
            cell.selectionStyle = .none
            outCell = cell
        case .delete:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditDeleteCell, for: indexPath) as! ContactEditAddCell
            cell.configCell(value: LocalString._delete_contact)
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
        
        if outCell == nil { //default
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
        
        switch s {
        case .emails:
            break
        default:
            guard self.viewModel.paidUser() else {
                self.upgrade()
                return
            }
        }
        
        if editingStyle == . insert {
            switch s {
            case .emails:
                let _ = self.viewModel.newEmail()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            case .cellphone:
                let _ = self.viewModel.newPhone()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            case .home_address:
                let _ = self.viewModel.newAddress()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            case .information:
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                //get left info types
                let infoTypes = viewModel.getLeftInfoTypes()
                for t in infoTypes {
                    alertController.addAction(UIAlertAction(title: t.desc, style: .default, handler: { (action) -> Void in
                        let _ = self.viewModel.newInformation(type: t)
                        self.newIndexPath = indexPath
                        self.tableView.insertRows(at: [indexPath], with: .automatic)
                    }))
                }
                
                let sender = tableView.cellForRow(at: indexPath)
                alertController.popoverPresentationController?.sourceView = sender ?? self.view
                alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.bounds)
                present(alertController, animated: true, completion: nil)
            case .custom_field:
                let _ = self.viewModel.newField()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            case .url:
                let _ = viewModel.newUrl()
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
        let sections = viewModel.getSections()
        let sc = sections[section]
        if sc == .encrypted_header {
            cell.ConfigHeader(title: LocalString._contacts_encrypted_contact_details_title, signed: false)
        } else if sc == .delete || sc == .notes {
            return nil
        } else if sc == .emails {
            cell.ConfigHeader(title: LocalString._contacts_email_addresses_title, signed: false)
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
        case .upgrade, .share,
             .email_header, .display_name, .encrypted_header, .notes,
             .type2_warning, .type3_error, .type3_warning, .debuginfo,
             .emails, .delete:
            break
            
        default:
            guard self.viewModel.paidUser() else {
                self.upgrade()
                return
            }
        }
        
        switch s {
        case .email_header, .display_name, .encrypted_header, .notes,
             .type2_warning, .type3_error, .type3_warning, .debuginfo:
            break
        //assert(false, "Code should not be here")
        case .emails:
            let emailCount = viewModel.getEmails().count
            if row == emailCount {
                let _ = viewModel.newEmail()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .cellphone:
            let cellCount = viewModel.getCells().count
            if row == cellCount {
                let _ = viewModel.newPhone()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .home_address:
            let addrCount = viewModel.getAddresses().count
            if row == addrCount {
                let _ = viewModel.newAddress()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .url:
            let urlCount = viewModel.getUrls().count
            if row == urlCount {
                let _ = viewModel.newUrl()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .information:
            let orgCount = viewModel.getInformations().count
            if row == orgCount {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                //get left info types
                let infoTypes = viewModel.getLeftInfoTypes()
                for t in infoTypes {
                    alertController.addAction(UIAlertAction(title: t.desc, style: .default, handler: { (action) -> Void in
                        let _ = self.viewModel.newInformation(type: t)
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
                let _ = viewModel.newField()
                self.newIndexPath = indexPath
                self.tableView.insertRows(at: [indexPath], with: .automatic)
            }
        case .delete:
            
            let sender = tableView.cellForRow(at: indexPath)
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._delete_contact, style: .destructive, handler: { (action) -> Void in
                let v : UIView = self.navigationController?.view ?? self.view
                MBProgressHUD.showAdded(to: v, animated: true)
                self.viewModel.delete(complete: { (error) in
                    MBProgressHUD.hide(for: v, animated: true)
                    if let err = error {
                        err.alertToast()
                    } else {
                        self.navigationController?.dismiss(animated: false, completion: {
                            self.delegate?.deleted()
                        })
                    }
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

extension ContactEditViewController: UINavigationControllerDelegate
{
    
}

extension ContactEditViewController: UIImagePickerControllerDelegate
{
    @objc func imagePickerController(_ picker: UIImagePickerController,
                                     didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
