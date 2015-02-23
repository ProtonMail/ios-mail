//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit

class ContactsViewController: ProtonMailViewController {
    
    private let kContactCellIdentifier: String = "ContactCell"
    
    // temporary class, just to populate the tableview
    
    class Contact: NSObject {
        var name: String!
        var email: String!
        
        init(name: String!, email: String!) {
            self.name = name
            self.email = email
        }
    }
    
    
    // MARK: - View Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    
    // MARK: - Private attributes
    
    private var contacts: [Contact] = [Contact]()
    private var searchResults: [Contact] = [Contact]()
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contacts.append(Contact(name: "Diego Santiviago", email: "diego.santiviago@arctouch.com"))
        contacts.append(Contact(name: "Eric Chamberlain", email: "eric.chamberlain@arctouch.com"))
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func filterContentForSearchText(searchText: String) {
        searchResults = contacts.filter({ (contact: Contact) -> Bool in
            let contactNameContainsFilteredText = contact.name.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
            let contactEmailContainsFilteredText = contact.email.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
            return contactNameContainsFilteredText || contactEmailContainsFilteredText
        })
    }
}


// MARK: - UITableViewDataSource

extension ContactsViewController: UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (tableView == self.searchDisplayController?.searchResultsTableView) {
            return searchResults.count
        }
        
        return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(kContactCellIdentifier) as UITableViewCell?
        
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: kContactCellIdentifier)
        }
        
        var name: String
        var email: String
        if (tableView == self.searchDisplayController?.searchResultsTableView) {
            name = searchResults[indexPath.row].name
            email = searchResults[indexPath.row].email
        } else {
            name = contacts[indexPath.row].name
            email = contacts[indexPath.row].email
        }
        
        cell?.textLabel?.text = name
        cell?.detailTextLabel?.text = email
        
        return cell!
    }
}


// MARK: - UITableViewDelegate

extension ContactsViewController: UITableViewDelegate {
}


// MARK: - UISearchDisplayDelegate

extension ContactsViewController: UISearchDisplayDelegate {
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchString)
        return true
    }
}