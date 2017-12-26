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
import Contacts

class ContactsViewController: ProtonMailViewController, ViewModelProtocol {
    
    fileprivate let kContactCellIdentifier: String = "ContactCell"
    fileprivate let kProtonMailImage: UIImage      = UIImage(named: "encrypted_main")!
    //
    fileprivate let kContactDetailsSugue : String  = "toContactDetailsSegue";
    fileprivate let kAddContactSugue : String      = "toAddContact"
    
    fileprivate var searchString : String = ""
 
    // Mark: - view model
    fileprivate var viewModel : ContactsViewModel!
    
    // MARK: - View Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    // MARK: - Private attributes
    fileprivate var refreshControl: UIRefreshControl!
    fileprivate var searchController : UISearchController!
    
    
    fileprivate var addBarButtonItem : UIBarButtonItem!
    fileprivate var moreBarButtonItem : UIBarButtonItem!
    
    func inactiveViewModel() {
    }
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactsViewModel
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("CONTACTS", comment: "Title")
        tableView.register(UINib(nibName: "ContactsTableViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactCellIdentifier)
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = NSLocalizedString("Search", comment: "Placeholder")
        searchController.searchBar.setValue(NSLocalizedString("Cancel", comment: "Action"),
                                            forKey:"_cancelButtonText")
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.automaticallyAdjustsScrollViewInsets = true
        self.searchController.searchBar.tintColor = UIColor.ProtonMail.Blue_475F77
        self.searchController.searchBar.backgroundColor = UIColor.clear
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.keyboardType = .default
        self.searchController.searchBar.autocapitalizationType = .none
        
        self.tableView.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = true;
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.noSeparatorsBelowFooter()
        self.tableView.sectionIndexColor = UIColor.ProtonMail.Blue_85B1DE
        
        let back = UIBarButtonItem(title: NSLocalizedString("Back", comment: "Action"),
                                   style: UIBarButtonItemStyle.plain,
                                   target: nil,
                                   action: nil)
        self.navigationItem.backBarButtonItem = back
        
        

        
        if self.addBarButtonItem == nil {
            self.addBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add,
                                                         target: self,
                                                         action: #selector(self.addContactTapped))
        }
        var rightButtons: [UIBarButtonItem] = [self.addBarButtonItem]
        
        if #available(iOS 9.0, *) {
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_more"),
                                                         style: UIBarButtonItemStyle.plain,
                                                         target: self,
                                                         action: #selector(self.moreButtonTapped))
            }
            rightButtons.append(self.moreBarButtonItem)
        }

        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
        
        
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        refreshControl.addTarget(self,
                                 action: #selector(fireFetch),
                                 for: UIControlEvents.valueChanged)
        
        tableView.addSubview(self.refreshControl)
        tableView.dataSource = self
        tableView.delegate = self
        
        refreshControl.tintColor = UIColor.gray
        refreshControl.tintColorDidChange()
        
        //get all contacts
        self.viewModel.setupFetchedResults(delaget: self)
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.setEditing(false, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.setupTimer(true)
        NotificationCenter.default.addKeyboardObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.stopTimer()
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
            //let composeViewController = segue.destinationViewController.childViewControllers[0] as! ComposeEmailViewController
            //sharedVMService.newDraftViewModelWithContact(composeViewController, contact: self.selectedContact)
        }
    }
    
    // MARK: - Private methods
    fileprivate func showContactBelongsToAddressBookError() {
        let description = NSLocalizedString("This contact belongs to your Address Book.", comment: "")
        let message = NSLocalizedString("Please, manage it in your phone.", comment: "Title")
        let alertController = UIAlertController(title: description, message: message, preferredStyle: .alert)
        alertController.addOKAction()
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc internal func fireFetch() {
        self.viewModel.fetchContacts { (contacts: [Contact]?, error: NSError?) in
            if let error = error as NSError? {
                PMLog.D(" error: \(error)")
                let alertController = error.alertController()
                alertController.addOKAction()
                self.present(alertController, animated: true, completion: nil)
            }
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    @objc internal func addContactTapped() {
        self.performSegue(withIdentifier: kAddContactSugue, sender: self)
    }
    
    @available(iOS 9.0, *)
    @objc internal func moreButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel",  comment: "Action"), style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Upload Contacts",  comment: "Action"), style: .default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
            
            let alertController = UIAlertController(title: NSLocalizedString("Contacts", comment: "Action"),
                                                    message: NSLocalizedString("Upload iOS contacts to protonmail?", comment: "Description"),
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Confirm", comment: "Action"), style: .default, handler: { (action) -> Void in
                self.getContacts()
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action"), style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }))
    
    
        alertController.popoverPresentationController?.barButtonItem = moreBarButtonItem
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    @available(iOS 9.0, *)
    internal func getContacts() {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined:
            store.requestAccess(for: .contacts, completionHandler: { (authorized, error) in
                if authorized {
                    self.retrieveContactsWithStore(store: store)
                } else {
                   "Contacts access is not authorized".alertToast()
                }
            })
        case .authorized:
             self.retrieveContactsWithStore(store: store)
        case .denied:
            "Contacts access denied, please allow access from settings".alertToast()
        case .restricted:
            "The application is not authorized to access contact data".alertToast()
        }
    }
    
    @available(iOS 9.0, *)
    lazy var contacts: [CNContact] = {
        let contactStore = CNContactStore()
        let keysToFetch : [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactVCardSerialization.descriptorForRequiredKeys()]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch)
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        
        return results
    }()
    
    @available(iOS 9.0, *)
    internal func retrieveContactsWithStore(store: CNContactStore) {
        let nview = self.navigationController?.view
        let hud : MBProgressHUD = MBProgressHUD.showAdded(to: nview, animated: true)
        hud.labelText = NSLocalizedString("Reading device contacts data...", comment: "Title")
        hud.mode = MBProgressHUDMode.indeterminate
        hud.removeFromSuperViewOnHide = true
       
        var pre_contacts : [[CardData]] = []
        
        var found: Int = 0
        //build boday first
        do {
            let contacts = self.contacts
            
            for contact in contacts {
                //check is uuid in the exsiting contacts
                let identifier = contact.identifier
                
                if !self.viewModel.isExsit(uuid: identifier) {
                    found += 1
                    hud.labelText = "Encrypting contacts...\(found)" //NSLocalizedString("Done", comment: "Title")
                    
                    let rawData = try CNContactVCardSerialization.data(with: [contact])
                    let vcardStr = String(data: rawData, encoding: .utf8)!
                    
                    if let vcard3 = PMNIEzvcard.parseFirst(vcardStr) {
                        
                        let uuid = PMNIUid.createInstance(identifier)
                        guard let vcard2 = PMNIVCard.createInstance() else {
                            continue //with error
                        }
                        
                        if let fn = vcard3.getFormattedName() {
                            vcard2.setFormattedName(fn)
                            vcard3.clearFormattedName()
                        }
                        let emails = vcard3.getEmails()
                        var i : Int = 1
                        for e in emails {
                            let ng = "EItem\(i)"
                            let group = e.getGroup()
                            if group.isEmpty {
                                e.setGroup(ng)
                                i += 1
                            }
                        }
                        
                        vcard2.setEmails(emails)
                        vcard3.clearEmails()
                        vcard2.setUid(uuid)
                        
                        // add others later
                        let vcard2Str = PMNIEzvcard.write(vcard2)
                        guard let userkey = sharedUserDataService.userInfo?.firstUserKey() else {
                            continue //with error
                        }
                        PMLog.D(vcard2Str);
                        let signed_vcard2 = sharedOpenPGP.signDetached(userkey.private_key,
                                                                       plainText: vcard2Str,
                                                                       passphras: sharedUserDataService.mailboxPassword!)
                        
                        //card 2 object
                        let card2 = CardData(t: .SignedOnly, d: vcard2Str, s: signed_vcard2)
                        
                        vcard3.setUid(uuid)
                        vcard3.setVersion(PMNIVCardVersion.vCard40())
                        let vcard3Str = PMNIEzvcard.write(vcard3)
                        PMLog.D(vcard3Str);
                        let encrypted_vcard3 = sharedOpenPGP.encryptMessageSingleKey(userkey.public_key, plainText: vcard3Str)
                        PMLog.D(encrypted_vcard3);
                        let signed_vcard3 = sharedOpenPGP.signDetached(userkey.private_key,
                                                                       plainText: vcard3Str,
                                                                       passphras: sharedUserDataService.mailboxPassword!)
                        //card 3 object
                        let card3 = CardData(t: .SignAndEncrypt, d: encrypted_vcard3, s: signed_vcard3)
                        
                        let cards : [CardData] = [card2, card3]
                        
                        pre_contacts.append(cards)
                    }
                }
            }
        } catch let error as NSError {
            error.alertToast()
        }
        
        if !pre_contacts.isEmpty {
            sharedContactDataService.add(cards: pre_contacts, completion:  { (contacts : [Contact]?, error : NSError?) in
                if error == nil {
                    let count = contacts?.count ?? 0
                    hud.labelText = "You have imported \(count) of \(found) contacts!" // NSLocalizedString("You have imported \(count) of \(pre_contacts.count) contacts!", comment: "Title")
                    hud.hide(true, afterDelay: 2)
                   // "You have imported \(count) of \(pre_contacts.count) contacts!".alertToast()
                } else {
                    hud.hide(true)
                    error?.alertToast()
                }
            })
        } else {
            hud.labelText = NSLocalizedString("All contacts are imported", comment: "Title")
            hud.hide(true, afterDelay: 1)
        }
    }
}




//Search part
extension ContactsViewController: UISearchBarDelegate, UISearchResultsUpdating {
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        self.searchString = searchController.searchBar.text ?? "";
        self.viewModel.search(text: self.searchString)
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        refreshControl.endRefreshing()
        refreshControl.removeFromSuperview()
        self.viewModel.set(searching: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        tableView.addSubview(refreshControl)
        self.viewModel.set(searching: false)
    }
}


// MARK: - UITableViewDataSource
extension ContactsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sectionCount()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.rowCount(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ContactsTableViewCell = tableView.dequeueReusableCell(withIdentifier: kContactCellIdentifier,
                                                                        for: indexPath) as! ContactsTableViewCell
        if let contact = self.viewModel.item(index: indexPath) {
            cell.config(name: contact.name,
                        email: contact.getDisplayEmails(),
                        highlight: self.searchString)
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
            
            if let contact = self.viewModel.item(index: indexPath) {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action-Contacts"), style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: NSLocalizedString("Delete Contact", comment: "Title-Contacts"), style: .destructive, handler: { (action) -> Void in
                    ActivityIndicatorHelper.showActivityIndicator(at: self.view)
                    self.viewModel.delete(contactID: contact.contactID, complete: { (error) in
                        ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
                        if let err = error {
                            err.alert(at : self.view)
                        }
                    })
                }))
                
                alertController.popoverPresentationController?.sourceView = self.view
                alertController.popoverPresentationController?.sourceRect = self.view.frame
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
//        let editClosure = { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
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
//        }
        
        let deleteAction = UITableViewRowAction(style: .default, title: NSLocalizedString("Delete", comment: "Action"), handler: deleteClosure)
//        let editAction = UITableViewRowAction(style: .normal, title: NSLocalizedString("Edit", comment: "Action"), handler: editClosure)
        return [deleteAction] // [deleteAction, editAction]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let contact = self.viewModel.item(index: indexPath) {
            self.performSegue(withIdentifier: kContactDetailsSugue, sender: contact)
        }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.viewModel.sectionForSectionIndexTitle(title: title, atIndex: index)
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.viewModel.sectionIndexTitle()
    }
    
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension ContactsViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        UIView.animate(withDuration: keyboardInfo.duration,
                       delay: 0,
                       options: keyboardInfo.animationOption, animations: { () -> Void in
            self.tableViewBottomConstraint.constant = 0
        }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: keyboardInfo.duration,
                           delay: 0,
                           options: keyboardInfo.animationOption, animations: { () -> Void in
                self.tableViewBottomConstraint.constant = keyboardSize.height
            }, completion: nil)
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
                    if let contact = self.viewModel.item(index: indexPath) {
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


