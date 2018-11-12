//
//  ContactSearchTableViewController.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 19/07/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

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
}
