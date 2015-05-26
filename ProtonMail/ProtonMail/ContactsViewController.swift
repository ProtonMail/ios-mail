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
    
    
    // MARK: - View Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    
    // MARK: - Private attributes
    
    private var contacts: [ContactVO] = [ContactVO]()
    private var searchResults: [ContactVO] = [ContactVO]()
    private var selectedContact: ContactVO!
    private var refreshControl: UIRefreshControl!

    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerNib(UINib(nibName: "ContactsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: kContactCellIdentifier)
        
        searchDisplayController?.searchResultsTableView.registerNib(UINib(nibName: "ContactsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: kContactCellIdentifier)
        
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor.ProtonMail.Blue_475F77
        refreshControl.addTarget(self, action: "retrieveAllContacts", forControlEvents: UIControlEvents.ValueChanged)
        
        tableView.addSubview(self.refreshControl)
        tableView.dataSource = self
        tableView.delegate = self
        
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.tintColorDidChange()

        contacts = sharedContactDataService.allContactVOs()
        tableView.reloadData()
        retrieveAllContacts()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.setEditing(false, animated: true)
        
        searchDisplayController?.searchResultsTableView.setEditing(false, animated: true)
        searchDisplayController?.setActive(false, animated: true)
    }
    
    func filterContentForSearchText(searchText: String) {
        searchResults = contacts.filter({ (contact: ContactVO) -> Bool in
            let contactNameContainsFilteredText = contact.name.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
            let contactEmailContainsFilteredText = contact.email.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
            return contactNameContainsFilteredText || contactEmailContainsFilteredText
        })
    }
    
    
    // MARK: - Private methods
    
    internal func retrieveAllContacts() {
        sharedContactDataService.fetchContactVOs { (contacts, error) -> Void in
            if let error = error {
                NSLog("\(__FUNCTION__) error: \(error)")
                
                let alertController = error.alertController()
                alertController.addOKAction()
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            
            self.contacts = contacts

            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
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
        var cell: ContactsTableViewCell = tableView.dequeueReusableCellWithIdentifier(kContactCellIdentifier, forIndexPath: indexPath) as! ContactsTableViewCell
        
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
                self.showContactBelongsToAddressBookError()
                return
            }
            
            if (count(contact.contactId) > 0) {
                sharedContactDataService.deleteContact(contact.contactId, completion: { (contacts, error) -> Void in
                    self.retrieveAllContacts()
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
            
            if (!contact.isProtonMailContact) {
                self.showContactBelongsToAddressBookError()
                return
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
            let editContactViewController: EditContactViewController = segue.destinationViewController.viewControllers![0] as! EditContactViewController
            editContactViewController.contact = self.selectedContact
            
            println("tableView.indexPathForSelectedRow() = \(tableView.indexPathForSelectedRow())")
        }
        
        if (segue.identifier == "toCompose") {
            let composeViewController: ComposeViewController = segue.destinationViewController.viewControllers![0] as! ComposeViewController
            composeViewController.toSelectedContacts.append(self.selectedContact)
        }
    }
    
    private func showContactBelongsToAddressBookError() {
        let description = NSLocalizedString("This contact belongs to your Address Book.")
        let message = NSLocalizedString("Please, manage it in your phone.")
        let alertController = UIAlertController(title: description, message: message, preferredStyle: .Alert)
        alertController.addOKAction()
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var contact: ContactVO
        if (tableView == self.tableView) {
            self.selectedContact = self.contacts[indexPath.row]
        } else {
            self.selectedContact = self.searchResults[indexPath.row]
        }
        
        self.performSegueWithIdentifier("toCompose", sender: self)
    }
}


// MARK: - UISearchDisplayDelegate

extension ContactsViewController: UISearchDisplayDelegate {
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchString)
        return true
    }
}