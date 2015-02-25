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
    private let kProtonMailImage: UIImage = UIImage(named: "encrypted_main")!
    private let kAddressBookImage: UIImage = UIImage(named: "addressbook_icon")!
    
    // temporary class, just to populate the tableview
    
    class Contact: NSObject {
        var name: String!
        var email: String!
        var isAddressBookContact: Bool = true
        
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
    private var hasAccessToAddressBook: Bool = false
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "ContactsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: kContactCellIdentifier)
        
        self.searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "ContactsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: kContactCellIdentifier)
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (!isContactsLoaded()) {
            ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
            retrieveAddressBook()
            retrieveServerContactList()
            
            self.contacts.sort { $0.name.lowercaseString < $1.name.lowercaseString }
            ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
        }
        
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    func filterContentForSearchText(searchText: String) {
        searchResults = contacts.filter({ (contact: Contact) -> Bool in
            let contactNameContainsFilteredText = contact.name.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
            let contactEmailContainsFilteredText = contact.email.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
            return contactNameContainsFilteredText || contactEmailContainsFilteredText
        })
    }
    
    
    // MARK: - Private methods
    
    private func isContactsLoaded() -> Bool {
        return self.contacts.count > 0
    }
    
    private func retrieveAddressBook() {
        var addressBookGroupQueue = dispatch_group_create()

        dispatch_group_enter(addressBookGroupQueue)
        
        if (sharedAddressBookService.hasAccessToAddressBook()) {
            self.hasAccessToAddressBook = true
            dispatch_group_leave(addressBookGroupQueue)
        } else {
            sharedAddressBookService.requestAuthorizationWithCompletion({ (granted: Bool, error: NSError?) -> Void in
                if (granted) {
                    self.hasAccessToAddressBook = true
                }
                
                if let error = error {
                    let alertController = error.alertController()
                    alertController.addAction(UIAlertAction(title: NSLocalizedString("OK"), style: .Default, handler: nil))
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                    println("Error trying to access Address Book = \(error.localizedDescription).")
                }
                
                dispatch_group_leave(addressBookGroupQueue)
            })
        }
        
        dispatch_group_wait(addressBookGroupQueue, DISPATCH_TIME_FOREVER)
        
        if (self.hasAccessToAddressBook) {
            let addressBookContacts = sharedAddressBookService.contacts()
            for contact in addressBookContacts {
                var name = contact.name?
                let emails: RHMultiStringValue = contact.emails
                
                for (var emailIndex: UInt = 0; Int(emailIndex) < Int(emails.count()); emailIndex++) {
                    let emailAsString = emails.valueAtIndex(emailIndex) as String
                    
                    if (emailAsString.isValidEmail()) {
                        let email = emailAsString
                        
                        if (name == nil) {
                            name = email
                        }
                        
                        self.contacts.append(Contact(name: name, email: email))
                    }
                }
            }
        }
    }
    
    private func retrieveServerContactList() {
        var contacts: [Contact]
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
        var cell: ContactsTableViewCell = tableView.dequeueReusableCellWithIdentifier(kContactCellIdentifier, forIndexPath: indexPath) as ContactsTableViewCell
        
        var name: String
        var email: String
        
        if (tableView == self.searchDisplayController?.searchResultsTableView) {
            name = searchResults[indexPath.row].name
            email = searchResults[indexPath.row].email
        } else {
            name = contacts[indexPath.row].name
            email = contacts[indexPath.row].email
        }
        
        cell.contactEmailLabel.text = email
        cell.contactNameLabel.text = name

        
        // temporary solution to show the icon
        if (indexPath.row % 2 == 0) {
            cell.contactSourceImageView.image = kProtonMailImage
        } else {
            cell.contactSourceImageView.hidden = true
        }
        
        return cell
    }
}


// MARK: - UITableViewDelegate

extension ContactsViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
}


// MARK: - UISearchDisplayDelegate

extension ContactsViewController: UISearchDisplayDelegate {
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchString)
        return true
    }
}