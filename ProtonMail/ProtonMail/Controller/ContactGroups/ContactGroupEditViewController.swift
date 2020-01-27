//
//  ContactGroupEditViewController.swift
//  ProtonMail
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


import UIKit
import PromiseKit
import MBProgressHUD

/**
 The design for now is no auto-saving
 */
class ContactGroupEditViewController: ProtonMailViewController, ViewModelProtocol {

    typealias viewModelType = ContactGroupEditViewModel

    let kToContactGroupSelectColorSegue = "toContactGroupSelectColorSegue"
    let kToContactGroupSelectEmailSegue = "toContactGroupSelectEmailSegue"
    let kContactGroupEditCellIdentifier = "ContactGroupEditCell"
    
    @IBOutlet weak var contactGroupNameInstructionLabel: UILabel!
    @IBOutlet weak var contactGroupNameLabel: UITextField!
    @IBOutlet weak var contactGroupImage: UIImageView!
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var navigationBarItem: UINavigationItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: ContactGroupEditViewModel!
    var activeText: UIResponder? = nil
    
    func set(viewModel: ContactGroupEditViewModel) {
        self.viewModel = viewModel
    }
    
    func inactiveViewModel() {}
    
    @IBAction func cancelItem(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        
        if viewModel.hasUnsavedChanges() {
            let alertController = UIAlertController(title: LocalString._do_you_want_to_save_the_unsaved_changes,
                                                    message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._general_save_action,
                                                    style: .default,
                                                    handler: { (action) -> Void in
                                                        //save and dismiss
                                                        self.save()
            }))
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                    style: .cancel,
                                                    handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._discard_changes,
                                                    style: .destructive,
                                                    handler: { (action) -> Void in
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
    
    @IBAction func changeColorTapped(_ sender: UIButton) {
        self.performSegue(withIdentifier: kToContactGroupSelectColorSegue, sender: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        dismissKeyboard()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ContactGroupEditViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupEditCellIdentifier)
        
        viewModel.delegate = self
        contactGroupNameLabel.delegate = self
        
        loadDataIntoView()
        tableView.noSeparatorsBelowFooter()
        
        prepareContactGroupImage()
        
        contactGroupNameInstructionLabel.text = LocalString._contact_groups_group_name_instruction_label
        saveButton.title = LocalString._general_save_action
        cancelButton.title = LocalString._general_cancel_button
        
        contactGroupNameLabel.addBottomBorder()
    }
    
    func prepareContactGroupImage() {
        contactGroupImage.image = UIImage.init(named: "contact_groups_icon")
        contactGroupImage.setupImage(tintColor: UIColor.white,
                                     backgroundColor: UIColor.init(hexString: viewModel.getColor(),
                                                                   alpha: 1))
    }
    
    func loadDataIntoView() {
        navigationBarItem.title = viewModel.getViewTitle()
        contactGroupNameLabel.text = viewModel.getName()
        contactGroupImage.backgroundColor = UIColor(hexString: viewModel.getColor(),
                                                    alpha: 1.0)
        
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func dismissKeyboard() {
        if let t = activeText {
            t.resignFirstResponder()
            activeText = nil
        }
    }
    
    private func dismiss() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true, completion: nil)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func save() {
        firstly { () -> Promise<Void> in
            MBProgressHUD.showAdded(to: self.view, animated: true)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            return viewModel.saveDetail()
        }.done {
            self.dismiss()
        }.ensure {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            MBProgressHUD.hide(for: self.view, animated: true)
        }.catch {
            error in
            error.alert(at: self.view)
        }
    }
    
    @IBAction func saveAction(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        save()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToContactGroupSelectColorSegue {
            let contactGroupSelectColorViewController = segue.destination as! ContactGroupSelectColorViewController
            
            let refreshHandler = {
                (newColor: String) -> Void in
                self.viewModel.setColor(newColor: newColor)
            }
            sharedVMService.contactGroupSelectColorViewModel(contactGroupSelectColorViewController,
                                                             currentColor: viewModel.getColor(),
                                                             refreshHandler: refreshHandler)
        } else if segue.identifier == kToContactGroupSelectEmailSegue {
            let refreshHandler = {
                (emailIDs: Set<Email>) -> Void in
                
                self.viewModel.setEmails(emails: emailIDs)
            }
            
            let contactGroupSelectEmailViewController = segue.destination as! ContactGroupSelectEmailViewController
            let data = sender as! ContactGroupEditViewController
            sharedVMService.contactGroupSelectEmailViewModel(contactGroupSelectEmailViewController,
                                                             user: self.viewModel.user,
                                                             selectedEmails: data.viewModel.getEmails(),
                                                             refreshHandler: refreshHandler)
        } else {
            PMLog.D("FatalError: No such segue")
        }
    }
}

extension ContactGroupEditViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getTotalSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTotalRows(for: section)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.getSectionTitle(for: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.getCellType(at: indexPath) {
        case .manageContact:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupManageCell", for: indexPath)
            cell.textLabel?.text = LocalString._contact_groups_manage_addresses
            return cell
        case .email:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactGroupEditCellIdentifier,
                                                     for: indexPath) as! ContactGroupEditViewCell
            
            let (emailID, name, email) = viewModel.getEmail(at: indexPath)
            cell.config(emailID: emailID,
                        name: name,
                        email: email,
                        queryString: "",
                        state: .editView,
                        viewModel: viewModel)
            return cell
        case .deleteGroup, .error: // TODO: fix this .error state
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupDeleteCell", for: indexPath) as UITableViewCell
            cell.textLabel?.text = LocalString._contact_groups_delete
            return cell
        }
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        switch viewModel.getCellType(at: indexPath) {
//        case .selectColor:
//            // display color
//            cell.detailTextLabel?.backgroundColor = UIColor(hexString: viewModel.getColor(),
//                                                            alpha: 1.0)
//        case .error:
//            fatalError("This is a bug")
//        default:
//            return
//        }
//    }
}

extension ContactGroupEditViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch viewModel.getCellType(at: indexPath) {
        case .manageContact:
            self.performSegue(withIdentifier: kToContactGroupSelectEmailSegue, sender: self)
        case .email:
            PMLog.D("email actions")
        case .deleteGroup:
            let deleteActionHandler = {
                (action: UIAlertAction) -> Void in
                
                firstly {
                    () -> Promise<Void> in
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                    return self.viewModel.deleteContactGroup()
                    }.done {
                        self.dismiss()
                    }.ensure {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }.catch {
                        (error) in
                        error.alert(at: self.view)
                }
            }
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                    style: .cancel,
                                                    handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._contact_groups_delete,
                                                    style: .destructive,
                                                    handler: deleteActionHandler))
            let sender = tableView.cellForRow(at: indexPath)
            alertController.popoverPresentationController?.sourceView = self.tableView
            alertController.popoverPresentationController?.sourceRect = (sender == nil ? self.view.frame : sender!.frame)

            self.present(alertController, animated: true, completion: nil)
        case .error:
            PMLog.D("FatalError: This is a bug")
        }
    }
}

extension ContactGroupEditViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeText = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        contactGroupNameLabel.text = textField.text
        viewModel.setName(name: textField.text ?? "")
        
        activeText = nil
    }
}

extension ContactGroupEditViewController: ContactGroupEditViewControllerDelegate
{
    func update() {
        loadDataIntoView()
    }
}
