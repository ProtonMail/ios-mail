//
//  ContactTypeViewController.swift
//  ProtonMail - Created on 5/4/17.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation


protocol ContactTypeViewControllerDelegate : AnyObject {
    func done(sectionType: ContactEditSectionType)
}

class ContactTypeViewController: ProtonMailViewController, ViewModelProtocol {
    typealias viewModelType = ContactTypeViewModel
    func inactiveViewModel() {
        
    }
    func set(viewModel: ContactTypeViewModel) {
        self.viewModel = viewModel
    }
    private var viewModel : ContactTypeViewModel!
    
    
    weak var deleget: ContactTypeViewControllerDelegate?
    
    @IBOutlet weak var doneItem: UIBarButtonItem!
    @IBOutlet weak var cancelItem: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomOffset: NSLayoutConstraint!
    
    var activeText : UITextField? = nil
    var selected : IndexPath? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        UITextField.appearance().tintColor = UIColor.ProtonMail.Gray_999DA1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addKeyboardObserver(self)
        
        let type = viewModel.getPickedType()
        let types = viewModel.getDefinedTypes()
        
        if let index = types.firstIndex(where: { ( left ) -> Bool in return left.rawString == type.rawString }) {
            let indexPath = IndexPath(row: index, section: 0)
            self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            tableView(self.tableView, didSelectRowAt: indexPath)
        } else {
            let custom = viewModel.getCustomType()
            if !custom.isEmpty {
                let indexPath = IndexPath(row: 0, section: 1)
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                tableView(self.tableView, didSelectRowAt: indexPath)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        if let index = selected {
            var type : ContactFieldType = .empty
            if index.section == 0 {
                let types = viewModel.getDefinedTypes()
                type = types[index.row]
            } else if index.section == 1 {
                if let cell = self.tableView.cellForRow(at: index) {
                    if let addCell = cell as? ContactTypeAddCustomCell {
                        type = ContactFieldType.get(raw: addCell.getValue())
                    } else {
                        type = ContactFieldType.get(raw: cell.textLabel?.text ?? LocalString._contacts_custom_type)
                    }
                } else {
                    type = ContactFieldType.get(raw: LocalString._contacts_custom_type )
                }
            }
            viewModel.updateType(t: type)
            deleget?.done(sectionType: viewModel.getSectionType())
        }
        self.navigationController?.popViewController(animated: true)
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
extension ContactTypeViewController: NSNotificationCenterKeyboardObserverProtocol {
    
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
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
}

extension ContactTypeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeText = textField
    }
}

// MARK: - UITableViewDataSource
extension ContactTypeViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            let l = viewModel.getDefinedTypes()
            return l.count
        }
        let custom = viewModel.getCustomType()
        if !custom.isEmpty {
            return 1
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        if section == 0 {
            let outCell = tableView.dequeueReusableCell(withIdentifier: "ContactTypeCell", for: indexPath)
            outCell.selectionStyle = .default
            let l = viewModel.getDefinedTypes()
            outCell.textLabel?.text = l[indexPath.row].title
            return outCell
        } else {
//            if row == 0 {
//                let addCell = tableView.dequeueReusableCell(withIdentifier: "ContactTypeAddCustomCell", for: indexPath) as! ContactTypeAddCustomCell
//                addCell.configCell(v: LocalString._contacts_add_custom_label)
//                return addCell
//            } else if row == 1 {
            if row == 0 {
                let outCell = tableView.dequeueReusableCell(withIdentifier: "ContactTypeCell", for: indexPath)
                outCell.selectionStyle = .default
                let text = viewModel.getCustomType()
                outCell.textLabel?.text = text.title
                return outCell
            }
        }
        return UITableViewCell()
    }
}

// MARK: - UITableViewDelegate
extension ContactTypeViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let s = selected {
            if let cell =  self.tableView.cellForRow(at: s) {
                if let addCell = cell as? ContactTypeAddCustomCell {
                    addCell.unsetMark()
                }
                cell.accessoryType = .none
            }
        }
        
        if let cell = self.tableView.cellForRow(at: indexPath) {
            if let addCell = cell as? ContactTypeAddCustomCell {
                addCell.setMark()
            }
            cell.accessoryType = .checkmark
        }
        
        selected = indexPath
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
