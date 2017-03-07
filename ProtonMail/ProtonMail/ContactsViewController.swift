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
    
    private let kContactDetailsSugue = "toContactDetailsSegue";
    
    
    // MARK: - View Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    
    // MARK: - Private attributes
    
    private var contacts: [ContactVO] = [ContactVO]()
    private var searchResults: [ContactVO] = [ContactVO]()
    private var selectedContact: ContactVO!
    private var refreshControl: UIRefreshControl!
    
    private var searchController : UISearchController!
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "ContactsTableViewCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: kContactCellIdentifier)
        
        searchController = UISearchController(searchResultsController: nil)
        
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = true
        
        self.searchController.searchBar.tintColor = UIColor.blackColor()
        self.searchController.searchBar.backgroundColor = UIColor.clearColor()
        
        self.tableView.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = true;
        self.extendedLayoutIncludesOpaqueBars = true
        self.searchController.searchBar.sizeToFit()
        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.noSeparatorsBelowFooter()
        
        
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        refreshControl.addTarget(self, action: #selector(ContactsViewController.retrieveAllContacts), forControlEvents: UIControlEvents.ValueChanged)
        
        tableView.addSubview(self.refreshControl)
        tableView.dataSource = self
        tableView.delegate = self
        
        refreshControl.tintColor = UIColor.grayColor()
        refreshControl.tintColorDidChange()
        
        contacts = sharedContactDataService.allContactVOs()
        tableView.reloadData()
        retrieveAllContacts()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.setEditing(false, animated: true)
        
        retrieveAllContacts()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.tableView.respondsToSelector(Selector("setSeparatorInset:"))) {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if (self.tableView.respondsToSelector(Selector("setLayoutMargins:"))) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    
    // MARK: - Private methods
    internal func retrieveAllContacts() {
        sharedContactDataService.getContactVOs { (contacts, error) -> Void in
            if let error = error {
                PMLog.D(" error: \(error)")
                
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


//Search part
extension ContactsViewController: UISearchBarDelegate, UISearchResultsUpdating {
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchString = searchController.searchBar.text ?? "";
        
        filterContentForSearchText(searchString)
        
        self.tableView.reloadData()
    }
    
    func filterContentForSearchText(searchText: String) {
        if searchText.isEmpty {
            searchResults = contacts
        } else {
            searchResults = contacts.filter({ (contact: ContactVO) -> Bool in
                let contactNameContainsFilteredText = contact.name.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
                let contactEmailContainsFilteredText = contact.email.lowercaseString.rangeOfString(searchText.lowercaseString) != nil
                return contactNameContainsFilteredText || contactEmailContainsFilteredText
            })
        }
    }
    
}


// MARK: - UITableViewDataSource

extension ContactsViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (self.searchController.active) {
            return searchResults.count
        }
        return contacts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: ContactsTableViewCell = tableView.dequeueReusableCellWithIdentifier(kContactCellIdentifier, forIndexPath: indexPath) as! ContactsTableViewCell
        
        var contact: ContactVO
        
        if (self.searchController.active) {
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
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteClosure = { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            var contact: ContactVO
            if (self.searchController.active) {
                if indexPath.row < self.searchResults.count {
                    contact = self.searchResults[indexPath.row]
                } else {
                    return
                }
            } else {
                if indexPath.row < self.contacts.count {
                    contact = self.contacts[indexPath.row]
                } else {
                    return
                }
            }
            
            self.selectedContact = contact
            
            if (!contact.isProtonMailContact) {
                self.showContactBelongsToAddressBookError()
                return
            }
            
            if (contact.contactId.characters.count > 0) {
                sharedContactDataService.deleteContact(contact.contactId, completion: { (contacts, error) -> Void in
                    self.retrieveAllContacts()
                })
            }
            
            if (self.searchController.active) {
                self.searchResults.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            } else {
                self.contacts.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        }
        
        let editClosure = { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            var contact: ContactVO
            if (self.searchController.active) {
                contact = self.searchResults[indexPath.row]
            } else {
                contact = self.contacts[indexPath.row]
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
//        if (segue.identifier == "toEditContact") {
//            let editContactViewController: EditContactViewController = segue.destinationViewController.childViewControllers[0] as! EditContactViewController
//            editContactViewController.contact = self.selectedContact
//            
//            PMLog.D("tableView.indexPathForSelectedRow() = \(tableView.indexPathForSelectedRow)")
//        } else if (segue.identifier == "toContactDetails") {
//            let editContactViewController: EditContactViewController = segue.destinationViewController.childViewControllers[0] as! EditContactViewController
//            editContactViewController.contact = self.selectedContact
//            
//            PMLog.D("tableView.indexPathForSelectedRow() = \(tableView.indexPathForSelectedRow)")
//        } else if (segue.identifier == "toCompose") {
//            let composeViewController = segue.destinationViewController.childViewControllers[0] as! ComposeEmailViewController
//            sharedVMService.newDraftViewModelWithContact(composeViewController, contact: self.selectedContact)
//        }
    }
    
    private func showContactBelongsToAddressBookError() {
        let description = NSLocalizedString("This contact belongs to your Address Book.")
        let message = NSLocalizedString("Please, manage it in your phone.")
        let alertController = UIAlertController(title: description, message: message, preferredStyle: .Alert)
        alertController.addOKAction()
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (self.searchController.active) {
            self.selectedContact = self.searchResults[indexPath.row]
        } else {
            self.selectedContact = self.contacts[indexPath.row]
        }
        //self.performSegueWithIdentifier("toCompose", sender: self)
        self.performSegueWithIdentifier(kContactDetailsSugue, sender: self)
    }
}

