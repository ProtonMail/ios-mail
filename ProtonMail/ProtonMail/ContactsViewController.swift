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
    
    fileprivate let kContactCellIdentifier: String = "ContactCell"
    fileprivate let kProtonMailImage: UIImage = UIImage(named: "encrypted_main")!
    
    // MARK: - View Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    
    // MARK: - Private attributes
    
    fileprivate var contacts: [ContactVO] = [ContactVO]()
    fileprivate var searchResults: [ContactVO] = [ContactVO]()
    fileprivate var selectedContact: ContactVO!
    fileprivate var refreshControl: UIRefreshControl!
    
    fileprivate var searchController : UISearchController!
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UINib(nibName: "ContactsTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: kContactCellIdentifier)
        
        self.title = NSLocalizedString("CONTACTS", comment: "Title")
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "Placeholder")
        searchController.searchBar.setValue(NSLocalizedString("Cancel", comment: "Action"), forKey:"_cancelButtonText")
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = true
        
        self.searchController.searchBar.tintColor = UIColor.black
        self.searchController.searchBar.backgroundColor = UIColor.clear
        
        self.tableView.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = true;
        self.extendedLayoutIncludesOpaqueBars = true
        self.searchController.searchBar.sizeToFit()
        self.automaticallyAdjustsScrollViewInsets = false
        
        
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        refreshControl.addTarget(self, action: #selector(ContactsViewController.retrieveAllContacts), for: UIControlEvents.valueChanged)
        
        tableView.addSubview(self.refreshControl)
        tableView.dataSource = self
        tableView.delegate = self
        
        refreshControl.tintColor = UIColor.gray
        refreshControl.tintColorDidChange()
        
        contacts = sharedContactDataService.allContactVOs()
        tableView.reloadData()
        retrieveAllContacts()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.setEditing(false, animated: true)
        
        retrieveAllContacts()
    }
    
    
    // MARK: - Private methods
    @objc internal func retrieveAllContacts() {
        sharedContactDataService.getContactVOs { (contacts, error) -> Void in
            if let error = error as NSError? {
                PMLog.D(" error: \(error)")
                
                let alertController = error.alertController()
                alertController.addOKAction()
                
                self.present(alertController, animated: true, completion: nil)
            }
            
            self.contacts = contacts
            
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
}


//Search part
extension ContactsViewController: UISearchBarDelegate, UISearchResultsUpdating {
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchString = searchController.searchBar.text ?? "";
        
        filterContentForSearchText(searchString)
        
        self.tableView.reloadData()
    }
    
    func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            searchResults = contacts
        } else {
            searchResults = contacts.filter({ (contact: ContactVO) -> Bool in
                let contactNameContainsFilteredText = contact.name.lowercased().range(of: searchText.lowercased()) != nil
                let contactEmailContainsFilteredText = contact.email.lowercased().range(of: searchText.lowercased()) != nil
                return contactNameContainsFilteredText || contactEmailContainsFilteredText
            })
        }
    }
    
}


// MARK: - UITableViewDataSource

extension ContactsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (self.searchController.isActive) {
            return searchResults.count
        }
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ContactsTableViewCell = tableView.dequeueReusableCell(withIdentifier: kContactCellIdentifier, for: indexPath) as! ContactsTableViewCell
        
        var contact: ContactVO
        
        if (self.searchController.isActive) {
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
            cell.contactSourceImageView.isHidden = true
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ContactsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteClosure = { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
            var contact: ContactVO
            if (self.searchController.isActive) {
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
            
            if (self.searchController.isActive) {
                self.searchResults.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            } else {
                self.contacts.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            }
        }
        
        let editClosure = { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
            var contact: ContactVO
            if (self.searchController.isActive) {
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
            self.performSegue(withIdentifier: "toEditContact", sender: self)
        }
        
        let deleteAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Delete", comment: "Action"), handler: deleteClosure)
        let editAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("Edit", comment: "Action"), handler: editClosure)
        return [deleteAction, editAction]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toEditContact") {
            let editContactViewController: EditContactViewController = segue.destination.childViewControllers[0] as! EditContactViewController
            editContactViewController.contact = self.selectedContact
            
            PMLog.D("tableView.indexPathForSelectedRow() = \(String(describing: tableView.indexPathForSelectedRow))")
        }
        
        if (segue.identifier == "toCompose") {
            let composeViewController = segue.destination.childViewControllers[0] as! ComposeEmailViewController
            sharedVMService.newDraftViewModelWithContact(composeViewController, contact: self.selectedContact)
        }
    }
    
    fileprivate func showContactBelongsToAddressBookError() {
        let description = NSLocalizedString("This contact belongs to your Address Book.", comment: "")
        let message = NSLocalizedString("Please, manage it in your phone.", comment: "Title")
        let alertController = UIAlertController(title: description, message: message, preferredStyle: .alert)
        alertController.addOKAction()
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (self.searchController.isActive) {
            self.selectedContact = self.searchResults[indexPath.row]
        } else {
            self.selectedContact = self.contacts[indexPath.row]
        }
        self.performSegue(withIdentifier: "toCompose", sender: self)
    }
}

