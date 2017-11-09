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

class ContactsViewController: ProtonMailViewController, ViewModelProtocol {
    
    fileprivate let kContactCellIdentifier: String = "ContactCell"
    fileprivate let kProtonMailImage: UIImage      = UIImage(named: "encrypted_main")!
    fileprivate let kContactDetailsSugue : String  = "toContactDetailsSegue";
    fileprivate let kAddContactSugue : String = "toAddContact"
    
    // Mark: - view model
    fileprivate var viewModel : ContactsViewModel!
    
    // MARK: - View Outlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    // MARK: - fetch
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    // MARK: - Private attributes
    
    //fileprivate var contacts: [ContactVO] = [ContactVO]()
    //fileprivate var searchResults: [ContactVO] = [ContactVO]()
    //fileprivate var selectedContact: ContactVO!
    fileprivate var refreshControl: UIRefreshControl!
    
    fileprivate var searchController : UISearchController!
    
    deinit {
        self.setupFetchedResultsController()
    }
    
    func inactiveViewModel() {
        
    }
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactsViewModel
    }
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("CONTACTS", comment: "Title")
        tableView.register(UINib(nibName: "ContactsTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: kContactCellIdentifier)
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "Placeholder")
        searchController.searchBar.setValue(NSLocalizedString("Cancel", comment: "Action"), forKey:"_cancelButtonText")
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.searchBar.tintColor = UIColor.black
        self.searchController.searchBar.backgroundColor = UIColor.clear
        self.searchController.searchBar.sizeToFit()
        
        self.tableView.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = true;
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.noSeparatorsBelowFooter()
        
        let back = UIBarButtonItem(title: NSLocalizedString("Back", comment: "Action"),
                                   style: UIBarButtonItemStyle.plain,
                                   target: nil,
                                   action: nil)
        self.navigationItem.backBarButtonItem = back
        
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        refreshControl.addTarget(self, action: #selector(retrieveAllContacts), for: UIControlEvents.valueChanged)
        
        //tableView.addSubview(self.refreshControl)  //TODO::enable it later
        tableView.dataSource = self
        tableView.delegate = self
        
        refreshControl.tintColor = UIColor.gray
        refreshControl.tintColorDidChange()
        
        //get all contacts
        //contacts = sharedContactDataService.allContactVOs()
        self.setupFetchedResultsController()
        
        tableView.reloadData()
        
        retrieveAllContacts()
    }
    
    fileprivate func setupFetchedResultsController() {
        self.fetchedResultsController = self.viewModel.getFetchedResultsController()
        self.fetchedResultsController?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.setEditing(false, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    
    // MARK: - Private methods
    //this need to change for fetch event logs
    @objc internal func retrieveAllContacts() {
        sharedContactDataService.fetchContacts { (contacts, error) -> Void in
            if let error = error as NSError? {
                PMLog.D(" error: \(error)")
                
                let alertController = error.alertController()
                alertController.addOKAction()
                
                self.present(alertController, animated: true, completion: nil)
            }
            //TODO::
           // self.contacts = contacts
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
//        if searchText.isEmpty {
//            searchResults = contacts
//        } else {
//            searchResults = contacts.filter({ (contact: ContactVO) -> Bool in
//                let contactNameContainsFilteredText = contact.name.lowercased().range(of: searchText.lowercased()) != nil
//                let contactEmailContainsFilteredText = contact.email.lowercased().range(of: searchText.lowercased()) != nil
//                return contactNameContainsFilteredText || contactEmailContainsFilteredText
//            })
//        }
    }
    
}


// MARK: - UITableViewDataSource

extension ContactsViewController: UITableViewDataSource {
    
    func contactAtIndexPath(_ indexPath: IndexPath) -> Contact? {
        //        if self.fetchedResultsController?.numberOfSections() > indexPath.section {
        //            if self.fetchedResultsController?.numberOfRowsInSection(indexPath.section) > indexPath.row {
        if let contact = fetchedResultsController?.object(at: indexPath) as? Contact {
            if contact.managedObjectContext != nil {
                return contact
            }
        }
        //            }
        //        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.numberOfSections() ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.numberOfRows(in: section) ?? 0
//        if (self.searchController.isActive) {
//            return searchResults.count
//        }
//        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ContactsTableViewCell = tableView.dequeueReusableCell(withIdentifier: kContactCellIdentifier, for: indexPath) as! ContactsTableViewCell
        
        if let contact = contactAtIndexPath(indexPath) {
            cell.contactEmailLabel.text = contact.getDisplayEmails()
            cell.contactNameLabel.text = contact.name
        }
        
//        var contact: ContactVO
//        
//        if (self.searchController.isActive) {
//            contact = searchResults[indexPath.row]
//        } else {
//            contact = contacts[indexPath.row]
//        }
        
//        cell.contactEmailLabel.text = contact.email
//        cell.contactNameLabel.text = contact.name
//        
//        // temporary solution to show the icon
//        if (contact.isProtonMailContact) {
//            cell.contactSourceImageView.image = kProtonMailImage
//        } else {
//            cell.contactSourceImageView.isHidden = true
//        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ContactsViewController: UITableViewDelegate {
    
    @objc func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    @objc func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    @objc func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteClosure = { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
//            var contact: ContactVO
//            if (self.searchController.isActive) {
//                if indexPath.row < self.searchResults.count {
//                    contact = self.searchResults[indexPath.row]
//                } else {
//                    return
//                }
//            } else {
//                if indexPath.row < self.contacts.count {
//                    contact = self.contacts[indexPath.row]
//                } else {
//                    return
//                }
//            }
//            
//            self.selectedContact = contact
//            
//            if (!contact.isProtonMailContact) {
//                self.showContactBelongsToAddressBookError()
//                return
//            }
//            
//            if (contact.contactId.count > 0) {
//                //TODO:: delete contact
////                sharedContactDataService.deleteContact(contact.contactId, completion: { (contacts, error) -> Void in
////                    self.retrieveAllContacts()
////                })
//            }
//            
//            if (self.searchController.isActive) {
//                self.searchResults.remove(at: indexPath.row)
//                self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
//            } else {
//                self.contacts.remove(at: indexPath.row)
//                self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
//            }
            
            if let contact = self.contactAtIndexPath(indexPath) {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action-Contacts"), style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete Contact", comment: "Title-Contacts"), style: .destructive, handler: { (action) -> Void in
                    ActivityIndicatorHelper.showActivityIndicator(at: self.view)
                    self.viewModel.delete(contactID: contact.contactID, complete: { (error) in
                        ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
                        if let err = error {
                            err.alert(at : self.view)
                        } else {
//                            self.navigationController?.dismiss(animated: false, completion: {
//
//                            })
                        }
                    })
                }))
                
                alertController.popoverPresentationController?.sourceView = self.view
                alertController.popoverPresentationController?.sourceRect = self.view.frame
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
        let editClosure = { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
//            var contact: ContactVO
//            if (self.searchController.isActive) {
//                contact = self.searchResults[indexPath.row]
//            } else {
//                contact = self.contacts[indexPath.row]
//            }
//            
//            self.selectedContact = contact
//            
//            if (!contact.isProtonMailContact) {
//                self.showContactBelongsToAddressBookError()
//                return
//            }
//            
//            self.selectedContact = contact
//            self.performSegue(withIdentifier: "toEditContact", sender: self)
        }
        
        let deleteAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Delete", comment: "Action"), handler: deleteClosure)
//        let editAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("Edit", comment: "Action"), handler: editClosure)
        return [deleteAction] // [deleteAction, editAction]
    }
    
    @objc func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == kContactDetailsSugue) {
            let contactDetailsViewController = segue.destination as! ContactDetailViewController
            let contact = sender as? Contact
            sharedVMService.contactDetailsViewModel(contactDetailsViewController, contact: contact!)
        } else if (segue.identifier == kAddContactSugue) {
            let addContactViewController = segue.destination.childViewControllers[0] as! ContactEditViewController
            sharedVMService.contactAddViewModel(addContactViewController)
        } else if (segue.identifier == "toCompose") {
            
   
//            let composeViewController = segue.destinationViewController.childViewControllers[0] as! ComposeEmailViewController
//            sharedVMService.newDraftViewModelWithContact(composeViewController, contact: self.selectedContact)
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
        tableView.deselectRow(at: indexPath, animated: true)
        if let contact = contactAtIndexPath(indexPath) {
            self.performSegue(withIdentifier: kContactDetailsSugue, sender: contact)
        }
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension ContactsViewController : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch(type) {
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
        case .insert:
            if let newIndexPath = newIndexPath {
                PMLog.D("Section: \(newIndexPath.section) Row: \(newIndexPath.row) ")
                tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
            }
        case .update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRow(at: indexPath) as? ContactsTableViewCell {
                    if let contact = contactAtIndexPath(indexPath) {
                        cell.contactEmailLabel.text = contact.getDisplayEmails()
                        cell.contactNameLabel.text = contact.name
                    }
                }
            }
            break
        default:
            return
        }
    }
}


