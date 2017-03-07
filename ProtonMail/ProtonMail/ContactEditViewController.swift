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
    private let kInvalidEmailShakeTimes: Float = 3.0
    private let kInvalidEmailShakeOffset: CGFloat = 10.0
    
    fileprivate var origFrameHeight : CGFloat = 0.0
    
    //const cell identifier
    fileprivate let kContactEditAddCell: String = "ContactEditAddCell"
    fileprivate let kContactEditEmailCell: String = "ContactEditEmailCell"
    
    fileprivate let kContactEditCellphoneCell: String = "ContactEditCellphoneCell"
    fileprivate let kContactEditAddressCell: String = "ContactEditAddressCell"
    fileprivate let kContactEditCellInfoCell: String = "ContactEditInformationCell"
    fileprivate let kContactEditFieldCell: String = "ContactEditFieldCell"
    fileprivate let kContactEditNotesCell: String = "ContactEditNotesCell"
    
    //const segue
    fileprivate let ktoContactTypeSegue : String = "toContactTypeSegue"
    
    
    fileprivate var doneItem: UIBarButtonItem!
    @IBOutlet weak var cancelItem: UIBarButtonItem!
    
    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomOffset: NSLayoutConstraint!
    
    
    var delegate : ContactEditViewControllerDelegate?
    
    var activeText : UITextField? = nil
    
    func inactiveViewModel() {
    }
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactEditViewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.doneItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ContactEditViewController.doneAction))
        self.navigationItem.rightBarButtonItem = doneItem
       
        if viewModel.isNew() {
            self.title = NSLocalizedString("Add Contact", comment: "Contacts add new contact")
            doneItem.title = NSLocalizedString("Add", comment: "Action-Contacts")
        } else {
            self.title = NSLocalizedString("Update Contact", comment: "Contacts Update contact")
            doneItem.title = NSLocalizedString("Update", comment: "Action-Contacts")
        }
        
        UITextField.appearance().tintColor = UIColor.ProtonMail.Gray_999DA1
        
        self.displayNameField.delegate = self
        self.tableView.isEditing = true

        self.displayNameField.text = viewModel.getProfile().newDisplayName
        
        tableView.noSeparatorsBelowFooter()
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
        
        if (self.tableView.responds(to: #selector(setter: UITableViewCell.separatorInset))) {
            self.tableView.separatorInset = UIEdgeInsets.zero
        }
        
        if (self.tableView.responds(to: #selector(setter: UIView.layoutMargins))) {
            self.tableView.layoutMargins = UIEdgeInsets.zero
        }
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
        ActivityIndicatorHelper.showActivityIndicator(at: self.view)
        viewModel.done { (error : NSError?) in
            ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
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
extension ContactEditViewController: ContactEditCellDelegate, ContactEditNotesCellDelegate {
    func pick(typeInterface: ContactEditTypeInterface, sender: UITableViewCell) {
        self.performSegue(withIdentifier: ktoContactTypeSegue, sender: typeInterface)
    }
    //reuseable
    func beginEditing(textField: UITextField) {
        self.activeText = textField
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sections = self.viewModel.getSections()
        if sections[section] == .encrypted_header {
            return 36.0
        }
        return 10.0
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
                cell.configCell(value: "Add new email")
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
                cell.configCell(value: "Add new phone number")
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
                cell.configCell(value: "Add new address")
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
                cell.configCell(value: "Add Information")
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
                cell.configCell(value: "Add new custom field")
                cell.selectionStyle = .default
                outCell = cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditFieldCell, for: indexPath) as! ContactEditFieldCell
                cell.selectionStyle = .none
                cell.configCell(obj: viewModel.getOrigFields()[row], callback: self)
                outCell = cell
            }
        case .notes:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditNotesCell, for: indexPath) as! ContactEditNotesCell
            cell.configCell(obj: viewModel.getOrigNotes(), callback: self)
            cell.selectionStyle = .none
            outCell = cell
        case .delete:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactEditAddCell, for: indexPath) as! ContactEditAddCell
            cell.configCell(value: "Delete Contact")
            cell.selectionStyle = .default
            outCell = cell
        }
        
        if outCell == nil { //default
            outCell = tableView.dequeueReusableCell(withIdentifier: "ContactEditAddCell", for: indexPath)
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
        if editingStyle == . insert {
            //"insert".alertToast()
        } else if editingStyle == .delete {
            //            let s = sections[section]
            //            switch s {
            //            case .display_name:
            //                return 0
            //            case .emails:
            //                return 1 + viewModel.getOrigEmails().count
            //            case .encrypted_header:
            //                return 0
            //            case .cell:
            //                return 1 //+ cells
            //            case .home_address:
            //                return 1 // + addresses
            //            case .org:
            //                return 1 // + orgs
            //            case .custom_field:
            //                return 1 // + fields
            //            case .notes:
            //                return 1
            //            }
            
            "delete".alertToast()
        }
        dismissKeyboard()
    }
}

// MARK: - UITableViewDelegate
extension ContactEditViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sections = viewModel.getSections()
        if sections[section] == .encrypted_header {
            return "Encrypted Contact Details"
        }
        return "" //"Contact Details"
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sections = viewModel.getSections()
        if sections[indexPath.section] == .notes {
            //return 80.0
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
                ActivityIndicatorHelper.showActivityIndicator(at: self.view)
                self.viewModel.delete(complete: { (error) in
                    ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
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
