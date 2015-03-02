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
    
    
    // MARK: - View Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    
    // MARK: - Private attributes
    
    private var contacts: [ContactVO] = [ContactVO]()
    private var searchResults: [ContactVO] = [ContactVO]()
    private var hasAccessToAddressBook: Bool = false
    private var contactsQueue = dispatch_queue_create("com.protonmail.contacts", nil)
    private var selectedContact: ContactVO!
    
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
        
        self.tableView.setEditing(false, animated: true)
        self.searchDisplayController?.searchResultsTableView.setEditing(false, animated: true)
        self.searchDisplayController?.setActive(false, animated: true)
        
        retrieveAllContacts()
    }
    
    func filterContentForSearchText(searchText: String) {
        searchResults = contacts.filter({ (contact: ContactVO) -> Bool in
            let contactNameContainsFilteredText = contact.name.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
            let contactEmailContainsFilteredText = contact.email.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
            return contactNameContainsFilteredText || contactEmailContainsFilteredText
        })
    }
    
    
    // MARK: - Private methods
    
    private func retrieveAllContacts() {
        ActivityIndicatorHelper.showActivityIndicatorAtView(self.view)
        
        dispatch_async(contactsQueue, { () -> Void in
            self.contacts.removeAll(keepCapacity: true)
            self.retrieveAddressBook()
            self.retrieveServerContactList({ () -> Void in
                self.contacts.sort { $0.name.lowercaseString < $1.name.lowercaseString }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                    ActivityIndicatorHelper.hideActivityIndicatorAtView(self.view)
                })
            })
        })
    }
    
    private func retrieveAddressBook() {
        
        if (sharedAddressBookService.hasAccessToAddressBook()) {
            self.hasAccessToAddressBook = true
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
            })
        }
        
        if (self.hasAccessToAddressBook) {
            let addressBookContacts = sharedAddressBookService.contacts()
            for contact: RHPerson in addressBookContacts as [RHPerson] {
                var name: String? = contact.name
                let emails: RHMultiStringValue = contact.emails
                
                for (var emailIndex: UInt = 0; Int(emailIndex) < Int(emails.count()); emailIndex++) {
                    let emailAsString = emails.valueAtIndex(emailIndex) as String
                    
                    if (emailAsString.isValidEmail()) {
                        let email = emailAsString
                        
                        if (name == nil) {
                            name = email
                        }
                        
                        self.contacts.append(ContactVO(name: name, email: email, isProtonMailContact: false))
                    }
                }
            }
        }
    }
    
    private func retrieveServerContactList(completion: () -> Void) {
        sharedContactDataService.fetchContacts { (contacts: [Contact]?, error: NSError?) -> Void in
            if error != nil {
                NSLog("\(error)")
                return
            }
            
            if let contacts = contacts {
                for contact in contacts {
                    self.contacts.append(ContactVO(id: contact.contactID, name: contact.name, email: contact.email, isProtonMailContact: true))
                }
            }
            
            completion()
        }
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
        
        var contact: ContactVO
        
        if (tableView == self.searchDisplayController?.searchResultsTableView) {
            contact = searchResults[indexPath.row]
        } else {
            contact = contacts[indexPath.row]
        }

        cell.contactEmailLabel.text = contact.email
        cell.contactNameLabel.text = contact.name

        
        // temporary solution to show the icon
        if (contact.isProtonMailContact) {
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
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteClosure = { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            
            var contact: ContactVO
            if (tableView == self.tableView) {
                contact = self.contacts[indexPath.row]
            } else {
                contact = self.searchResults[indexPath.row]
            }
            
            self.selectedContact = contact
            
            if (!contact.isProtonMailContact) {
                let description = NSLocalizedString("This contact belongs to your Address Book.")
                let message = NSLocalizedString("Please, remove it in your phone.")
                let alertController = UIAlertController(title: description, message: message, preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("OK"), style: .Default, handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
                return
            }
            
            if (countElements(contact.contactId) > 0) {
                dispatch_async(self.contactsQueue, { () -> Void in
                    sharedContactDataService.deleteContact(contact.contactId, completion: { (contacts, error) -> Void in
                        self.retrieveAllContacts()
                    })
                })
            }
            
            if (tableView == self.tableView) {
                self.contacts.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            } else {
                self.searchResults.removeAtIndex(indexPath.row)
                self.searchDisplayController?.searchResultsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.searchDisplayController?.searchBar.resignFirstResponder()
            }
        }
        
        let editClosure = { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            var contact: ContactVO
            if (tableView == self.tableView) {
                contact = self.contacts[indexPath.row]
            } else {
                contact = self.searchResults[indexPath.row]
            }
            
            self.selectedContact = contact
            self.performSegueWithIdentifier("toEditContact", sender: self)
        }
        
        let deleteAction = UITableViewRowAction(style: .Default, title: NSLocalizedString("Delete"), handler: deleteClosure)
        let editAction = UITableViewRowAction(style: .Normal, title: NSLocalizedString("Edit"), handler: editClosure)
        
        return [deleteAction, editAction]
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "toEditContact") {
            let editContactViewController: EditContactViewController = segue.destinationViewController.viewControllers![0] as EditContactViewController
            editContactViewController.contact = self.selectedContact
            println("tableView.indexPathForSelectedRow() = \(tableView.indexPathForSelectedRow())")
        }
    }
}


// MARK: - UISearchDisplayDelegate

extension ContactsViewController: UISearchDisplayDelegate {
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchString)
        return true
    }
}

struct ContactVO {
    let contactId: String!
    let name: String!
    let email: String!
    let isProtonMailContact: Bool = false
    
    init(id: String! = "", name: String!, email: String!, isProtonMailContact: Bool) {
        self.contactId = id
        self.name = name
        self.email = email
        self.isProtonMailContact = isProtonMailContact
    }
}