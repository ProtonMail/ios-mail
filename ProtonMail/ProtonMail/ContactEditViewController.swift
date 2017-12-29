//
//  ContactEditViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/6/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

protocol ContactEditViewControllerDelegate {
    func deleted()
    func updated()
}

class ContactEditViewController: ProtonMailViewController, ViewModelProtocol {
    
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
    fileprivate let kContactEditCellphoneCell: String = "ContactEditCellphoneCell"
    fileprivate let kContactEditAddressCell: String   = "ContactEditAddressCell"
    fileprivate let kContactEditCellInfoCell: String  = "ContactEditInformationCell"
    fileprivate let kContactEditFieldCell: String     = "ContactEditFieldCell"
    fileprivate let kContactEditNotesCell: String     = "ContactEditNotesCell"
    fileprivate let kContactEditTextViewCell: String     = "ContactEditTextViewCell"
    
    //const segue
    fileprivate let ktoContactTypeSegue : String      = "toContactTypeSegue"
    
    //
    fileprivate var doneItem: UIBarButtonItem!
    @IBOutlet weak var cancelItem: UIBarButtonItem!
    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomOffset: NSLayoutConstraint!
    
    
    var delegate : ContactEditViewControllerDelegate?
    
    var activeText : UIResponder? = nil
    
    func inactiveViewModel() {
    }
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactEditViewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.doneItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: "action"),
                                        style: UIBarButtonItemStyle.plain,
                                        target: self, action: #selector(ContactEditViewController.doneAction))
        self.navigationItem.rightBarButtonItem = doneItem
       
        if viewModel.isNew() {
            self.title = NSLocalizedString("Add Contact", comment: "Contacts add new contact")
        } else {
            self.title = NSLocalizedString("Update Contact", comment: "Contacts Update contact")
        }
        doneItem.title = NSLocalizedString("Save", comment: "Action-Contacts")
        
        UITextField.appearance().tintColor = UIColor.ProtonMail.Gray_999DA1
        self.displayNameField.text = viewModel.getProfile().newDisplayName
        self.displayNameField.delegate = self
        
        let nib = UINib(nibName: kContactDetailsHeaderView, bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: kContactDetailsHeaderID)
        self.tableView.estimatedRowHeight = 70
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.tableView.isEditing = true
        self.tableView.noSeparatorsBelowFooter()
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ktoContactTypeSegue {
            let contactTypeViewController = segue.destination as! ContactTypeViewController
            contactTypeViewController.deleget = self
            let type = sender as! ContactEditTypeInterface
            sharedVMService.contactTypeViewModel(contactTypeViewController, type: type)
        }
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        let v : UIView = self.navigationController?.view ?? self.view
        ActivityIndicatorHelper.showActivityIndicator(at: v)
        viewModel.done { (error : NSError?) in
            ActivityIndicatorHelper.hideActivityIndicator(at: v)
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

    override func shouldShowSideMenu() -> Bool {
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
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            tableViewBottomOffset.constant = keyboardSize.height
        }
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
        self.performSegue(withIdentifier: ktoContactTypeSegue, sender: typeInterface)
    }
    //reuseable
    func beginEditing(textField: UITextField) {
        self.activeText = textField
    }
    
    func beginEditing(textView: UITextView) {
        self.activeText = textView
    }
    
    func didChanged(textView: UITextView) {
        UIView.setAnimationsEnabled(false)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
    }
    
}

//
extension ContactEditViewController: ContactTypeViewControllerDelegate {
    func done(sectionType: ContactEditSectionType) {
        let sections = self.viewModel.getSections()
        if let sectionIndex = sections.index(of: sectionType) {
            tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
        } else {
            tableView.reloadData()
        }
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
        case .display_name:
            return 0
        case .emails:
            return 1 + viewModel.getOrigEmails().count
        case .encrypted_header:
            return 0
        case .cellphone:
            return 1 + viewModel.getOrigCells().count
        case .home_address:
            return 1 + viewModel.getOrigAddresses().count
        case .information:
            return 1 + viewModel.getOrigInformations().count
        case .custom_field:
            return 1 + viewModel.getOrigFields().count
        case .notes:
            return 1
        case .delete:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sections = self.viewModel.getSections()
        var outCell : UITableViewCell?
        let section = indexPath.section
        let row = indexPath.row
        let s = sections[section]
        switch s {
        case .display_name:
            assert(false, "Code should not be here")
        case .emails:
            let emailCount = viewModel.getOrigEmails().count
            if row == emailCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: NSLocalizedString("Add new email", comment: "action"))
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditEmailCell, for: indexPath) as! ContactEditEmailCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getOrigEmails()[row], callback: self)
                outCell = cell
            }
        case .encrypted_header:
            assert(false, "Code should not be here")
        case .cellphone:
            let cellCount = viewModel.getOrigCells().count
            if row == cellCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: NSLocalizedString("Add new phone number", comment: "action"))
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditCellphoneCell, for: indexPath) as! ContactEditPhoneCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getOrigCells()[row], callback: self)
                outCell = cell
            }
        case .home_address:
            let addrCount = viewModel.getOrigAddresses().count
            if row == addrCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: NSLocalizedString("Add new address", comment: "action"))
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddressCell, for: indexPath) as! ContactEditAddressCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getOrigAddresses()[row], callback: self)
                outCell = cell
            }
        case .information:
            let orgCount = viewModel.getOrigInformations().count
            if row == orgCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: NSLocalizedString("Add new field", comment: "action"))
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditCellInfoCell, for: indexPath) as! ContactEditInformationCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getOrigInformations()[row], callback: self)
                outCell = cell
            }
        case .custom_field:
            let fieldCount = viewModel.getOrigFields().count
            if row == fieldCount {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
                cell.configCell(value: NSLocalizedString("Add new custom field", comment: "action"))
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditFieldCell, for: indexPath) as! ContactEditFieldCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getOrigFields()[row], callback: self)
                outCell = cell
            }
        case .notes:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditTextViewCell, for: indexPath) as! ContactEditTextViewCell
            cell.configCell(obj: viewModel.getOrigNotes(), callback: self)
            cell.selectionStyle = .none
            outCell = cell
        case .delete:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditDeleteCell, for: indexPath) as! ContactEditAddCell
            cell.configCell(value: NSLocalizedString("Delete Contact", comment: "action"))
            cell.selectionStyle = .default
            outCell = cell
        }
        
        if outCell == nil { //default
            outCell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath)
            outCell?.selectionStyle = .none
        }
        return outCell!
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        let section = indexPath.section
        let row = indexPath.row
        
        let sections = self.viewModel.getSections()
        let s = sections[section]
        switch s {
        case .display_name:
            assert(false, "Code should not be here")
        case .emails:
            let emailCount = viewModel.getOrigEmails().count
            if row == emailCount {
                return .insert
            } else {
                return .delete
            }
        case .encrypted_header:
            assert(false, "Code should not be here")
        case .cellphone:
            let cellCount = viewModel.getOrigCells().count
            if row == cellCount {
                return .insert
            } else {
                return .delete
            }
        case .home_address:
            let addrCount = viewModel.getOrigAddresses().count
            if row == addrCount {
                return .insert
            } else {
                return .delete
            }
        case .information:
            let orgCount = viewModel.getOrigInformations().count
            if row == orgCount {
                return .insert
            } else {
                return .delete
            }
        case .custom_field:
            let fieldCount = viewModel.getOrigFields().count
            if row == fieldCount {
                return .insert
            } else {
                return .delete
            }
        case .notes, .delete:
            return .none
        }
        return .none
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        let sections = self.viewModel.getSections()
        if editingStyle == . insert {
            let s = sections[section]
            switch s {
            case .emails:
                let _ = self.viewModel.newEmail()
            case .cellphone:
                let _ = self.viewModel.newPhone()
            case .home_address:
                let _ = self.viewModel.newAddress()
            case .information:
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action-Contacts"), style: .cancel, handler: nil))
                //get left info types
                let infoTypes = viewModel.getLeftInfoTypes()
                for t in infoTypes {
                    alertController.addAction(UIAlertAction(title: t.desc, style: .default, handler: { (action) -> Void in
                        let _ = self.viewModel.newInformation(type: t)
                        tableView.reloadSections([section], with: .automatic)
                        tableView.deselectRow(at: indexPath, animated: true)
                    }))
                }
                
                let sender = tableView.cellForRow(at: indexPath)
                alertController.popoverPresentationController?.sourceView = sender ?? self.view
                alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.bounds)
                present(alertController, animated: true, completion: nil)
            case .custom_field:
                let _ = self.viewModel.newField()
            default:
                break
            }
        } else if editingStyle == .delete {
            let s = sections[section]
            switch s {
            case .emails:
                self.viewModel.deleteEmail(at: row)
            case .cellphone:
                self.viewModel.deletePhone(at: row)
            case .home_address:
                self.viewModel.deleteAddress(at: row)
            case .information:
                self.viewModel.deleteInformation(at: row)
            case .custom_field:
                self.viewModel.deleteField(at: row)
            default:
                break
            }
        }
        dismissKeyboard()
        
        tableView.reloadSections([section], with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
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
            cell.ConfigHeader(title: NSLocalizedString("Encrypted Contact Details", comment: "title"), signed: false)
        } else if sc == .delete || sc == .notes {
            return nil
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sections = viewModel.getSections()
        let s = sections[section]
        switch s {
        case .encrypted_header, .delete:
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
            return 60
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
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sections = viewModel.getSections()
        if sections[indexPath.section] == .notes {
            return UITableViewAutomaticDimension
        }
        if sections[indexPath.section] == .home_address {
            let count = viewModel.getOrigAddresses().count
            if indexPath.row != count {
                return 180.0
            }
        }
        
        return 48.0
    }
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sections = viewModel.getSections()
        let section = indexPath.section
        let row = indexPath.row
        let s = sections[section]
        switch s {
        case .display_name:
            assert(false, "Code should not be here")
        case .emails:
            let emailCount = viewModel.getOrigEmails().count
            if row == emailCount {
                let _ = viewModel.newEmail()
            }
        case .encrypted_header:
            assert(false, "Code should not be here")
        case .cellphone:
            let cellCount = viewModel.getOrigCells().count
            if row == cellCount {
                let _ = viewModel.newPhone()
            }
        case .home_address:
            let addrCount = viewModel.getOrigAddresses().count
            if row == addrCount {
                let _ = viewModel.newAddress()
            }
        case .information:
            let orgCount = viewModel.getOrigInformations().count
            if row == orgCount {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action-Contacts"), style: .cancel, handler: nil))
                
                //get left info types
                let infoTypes = viewModel.getLeftInfoTypes()
                for t in infoTypes {
                    alertController.addAction(UIAlertAction(title: t.desc, style: .default, handler: { (action) -> Void in
                        let _ = self.viewModel.newInformation(type: t)
                        tableView.reloadSections([section], with: .automatic)
                        tableView.deselectRow(at: indexPath, animated: true)
                    }))
                }
                
                let sender = tableView.cellForRow(at: indexPath)
                alertController.popoverPresentationController?.sourceView = sender ?? self.view
                alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.bounds)
                present(alertController, animated: true, completion: nil)
            }
        case .custom_field:
            let fieldCount = viewModel.getOrigFields().count
            if row == fieldCount {
                let _ = viewModel.newField()
            }
        case .notes:
            assert(true, "Code should not be here")
        case .delete:
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action-Contacts"), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete Contact", comment: "Title-Contacts"), style: .destructive, handler: { (action) -> Void in
                let v : UIView = self.navigationController?.view ?? self.view
                ActivityIndicatorHelper.showActivityIndicator(at: v)
                self.viewModel.delete(complete: { (error) in
                    ActivityIndicatorHelper.hideActivityIndicator(at: v)
                    if let err = error {
                        err.alertToast()
                    } else {
                        self.navigationController?.dismiss(animated: false, completion: {
                            self.delegate?.deleted()
                        })
                    }
                })
            }))
            
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = self.view.frame
            present(alertController, animated: true, completion: nil)
        }
        
        dismissKeyboard()
        
        tableView.reloadSections([section], with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
