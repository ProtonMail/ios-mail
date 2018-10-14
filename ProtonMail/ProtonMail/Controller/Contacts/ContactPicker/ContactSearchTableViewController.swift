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
        let fallbackCell = tableView.dequeueReusableCell(withIdentifier: ContactPickerDefined.ContactsTableViewCellIdentifier, for: indexPath) as! ContactsTableViewCell
        if (indexPath.row < self.filteredContacts.count) {
            if let model = self.filteredContacts[indexPath.row] as? ContactVO {
                let cell = tableView.dequeueReusableCell(withIdentifier: ContactPickerDefined.ContactsTableViewCellIdentifier, for: indexPath) as! ContactsTableViewCell
                cell.config(name: model.contactTitle,
                            email: model.contactSubtitle ?? "",
                            highlight: "")
                return cell
            } else if let model = self.filteredContacts[indexPath.row] as? ContactGroupVO {
                let cell = tableView.dequeueReusableCell(withIdentifier: ContactPickerDefined.ContactGroupTableViewCellIdentifier, for: indexPath) as! ContactGroupsViewCell
                let info = model.getContactGroupInfo()
                cell.config(labelID: model.ID,
                            name: model.contactTitle,
                            count: info.total,
                            color: info.color,
                            wasSelected: false)
                return cell
            } else {
                return fallbackCell
            }
        } else {
            return fallbackCell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.filteredContacts[indexPath.row]
        self.onSelection?(model)
    }
    
    override var canBecomeFirstResponder: Bool {
        return false
    }
}
