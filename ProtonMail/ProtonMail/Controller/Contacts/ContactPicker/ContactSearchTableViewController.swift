//
//  ContactSearchTableViewController.swift
//  ProtonMail - Created on 19/07/2018.
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


import UIKit

class ContactSearchTableViewController: UITableViewController {
    internal var queryString = ""
    internal var onSelection: ((ContactPickerModelProtocol)->Void) = { _ in }
    internal var filteredContacts: [ContactPickerModelProtocol] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredContacts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let outCell = tableView.dequeueReusableCell(withIdentifier: ContactPickerDefined.ContactsTableViewCellIdentifier,
                                                         for: indexPath)
        if indexPath.row < self.filteredContacts.count, let cell = outCell as? ContactsTableViewCell {
            let model = self.filteredContacts[indexPath.row]
            cell.config(name: model.contactTitle,
                        email: model.contactSubtitle ?? "",
                        highlight: queryString,
                        color: model.color)
        }
        return outCell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.filteredContacts[indexPath.row]
        self.onSelection(model)
    }
    
    override var canBecomeFirstResponder: Bool {
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return UIDevice.current.orientation == .landscapeLeft ||
                UIDevice.current.orientation == .landscapeRight
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
