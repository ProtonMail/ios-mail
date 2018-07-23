//
//  ContactSearchTableViewController.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 19/07/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactSearchTableViewController: UITableViewController {
    internal var onSelection: ((ContactPickerModelProtocol)->Void)?
    internal var filteredContacts: [ContactPickerModelProtocol] = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredContacts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactPickerDefined.ContactsTableViewCellIdentifier, for: indexPath) as! ContactsTableViewCell
        
        if (self.filteredContacts.count > indexPath.row) {
            let model = self.filteredContacts[indexPath.row]
            cell.contactEmailLabel.text = model.contactSubtitle
            cell.contactNameLabel.text = model.contactTitle
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.filteredContacts[indexPath.row]
        self.onSelection?(model)
    }
    
    override var canBecomeFirstResponder: Bool {
        return false
    }
}
