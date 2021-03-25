//
//  ContactsViewController.swift
//  ProtonMail - Created on 3/6/17.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import Contacts
import CoreData
import MBProgressHUD

class ContactsViewController: ContactsAndGroupsSharedCode, ViewModelProtocol {
    typealias viewModelType = ContactsViewModel
    
    // Mark: - view model
    private var viewModel : ContactsViewModel!
    func set(viewModel: ContactsViewModel) {
        self.viewModel = viewModel
    }
    
    private let kProtonMailImage: UIImage      = UIImage(named: "encrypted_main")!
    private let kContactDetailsSugue : String  = "toContactDetailsSegue"
    private var searchString : String = ""
    
    // MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    // MARK: - Private attributes
    fileprivate var refreshControl: UIRefreshControl!
    fileprivate var searchController : UISearchController!
    
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchViewConstraint: NSLayoutConstraint!

    
    deinit {
        self.viewModel?.resetFetchedController()
    }
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(ContactsTableViewCell.nib,
                           forCellReuseIdentifier: ContactsTableViewCell.cellID)
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        refreshControl.addTarget(self,
                                 action: #selector(fireFetch),
                                 for: UIControl.Event.valueChanged)
        
        tableView.estimatedRowHeight = 60.0
        tableView.addSubview(self.refreshControl)
        tableView.dataSource = self
        tableView.delegate = self
        
        refreshControl.tintColor = UIColor.gray
        refreshControl.tintColorDidChange()

        self.navigationController?.navigationBar.prefersLargeTitles = false
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.noSeparatorsBelowFooter()
        self.tableView.sectionIndexColor = UIColor.ProtonMail.Blue_85B1DE
        
        //get all contacts
        self.viewModel.setupFetchedResults(delegate: self)
        self.prepareSearchBar()
        
        prepareNavigationItemRightDefault(self.viewModel.user)
        generateAccessibilityIdentifiers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.setEditing(false, animated: true)
        self.title = LocalString._contacts_title

        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.setupTimer(true)
        NotificationCenter.default.addKeyboardObserver(self)
        
        self.isOnMainView = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.stopTimer()
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    //run once
    private func prepareSearchBar() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = LocalString._general_search_placeholder
        
        if #available(iOS 13.0, *) {
            // Terminating app due to uncaught exception 'NSGenericException', reason: 'Access to UISearchBar's set_cancelButtonText: ivar is prohibited. This is an application bug'
        } else {
            searchController.searchBar.setValue(LocalString._general_done_button,
                                                forKey:"_cancelButtonText")
        }
        
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.automaticallyAdjustsScrollViewInsets = true
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.keyboardType = .default
        self.searchController.searchBar.keyboardAppearance = .light
        self.searchController.searchBar.autocapitalizationType = .none
        self.searchController.searchBar.isTranslucent = false
        self.searchController.searchBar.tintColor = .white
        self.searchController.searchBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background
        self.searchController.searchBar.backgroundColor = .clear

        self.searchViewConstraint.constant = 0.0
        self.searchView.isHidden = true
        self.navigationItem.largeTitleDisplayMode = .never
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.navigationItem.searchController = self.searchController
        self.navigationItem.assignNavItemIndentifiers()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.isOnMainView = false // hide the tab bar
        let viewController = segue.destination
        
        switch segue.identifier {
        case kContactDetailsSugue:
            let contactDetailsViewController = viewController as! ContactDetailViewController
            
            let contact = sender as? Contact
            sharedVMService.contactDetailsViewModel(contactDetailsViewController, user: self.viewModel.user, contact: contact!)
            
        case "toCompose", kAddContactSugue:
            let addContactViewController = segue.destination.children[0] as! ContactEditViewController
            sharedVMService.contactAddViewModel(addContactViewController, user: self.viewModel.user)
            
        case kAddContactGroupSugue:
            let addContactGroupViewController = segue.destination.children[0] as! ContactGroupEditViewController
            sharedVMService.contactGroupEditViewModel(addContactGroupViewController, user: self.viewModel.user, state: .create)
            
        case kSegueToImportView:
            self.isOnMainView = true
            let popup = segue.destination as! ContactImportViewController
            // TODO: inject it via ViewModel when ContactImportViewController will have one
            popup.user = self.viewModel.user
            self.setPresentationStyleForSelfController(self,
                                                       presentingController: popup,
                                                       style: .overFullScreen)
            
        case kToUpgradeAlertSegue:
            let popup = viewController as! UpgradeAlertViewController
            popup.delegate = self
            sharedVMService.upgradeAlert(contacts: popup)
            
        default:
            break
        }
        
        if #available(iOS 13, *) { // detect view dismiss above iOS 13
            if let nav = viewController as? UINavigationController {
                nav.children[0].presentationController?.delegate = self
            }
            segue.destination.presentationController?.delegate = self
        }
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
        }
    }
}

extension ContactsViewController: UpgradeAlertVCDelegate {
    func postToPlan() {
        NotificationCenter.default.post(name: .switchView,
                                        object: DeepLink(MenuCoordinatorNew.Destination.plan.rawValue))
    }
    func goPlans() {
        if self.presentingViewController != nil {
            self.dismiss(animated: true) {
                self.postToPlan()
            }
        } else {
            self.postToPlan()
        }
    }
    
    func learnMore() {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(.paidPlans, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(.paidPlans)
        }
    }
    
    func cancel() {
        
    }
}

//Search part
extension ContactsViewController: UISearchBarDelegate, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        self.searchString = searchController.searchBar.text ?? ""
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
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactsTableViewCell.cellID,
                                                 for: indexPath)
        if let contactCell = cell as? ContactsTableViewCell {
            if let contact = self.viewModel.item(index: indexPath) {
                contactCell.config(name: contact.name,
                                   email: contact.getDisplayEmails(),
                                   highlight: self.searchString)
            }
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ContactsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteClosure = { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
            if let contact = self.viewModel.item(index: indexPath) {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: LocalString._delete_contact,
                                                        style: .destructive, handler: { (action) -> Void in
                                                            MBProgressHUD.showAdded(to: self.view, animated: true)
                                                            self.viewModel.delete(contactID: contact.contactID, complete: { (error) in
                                                                MBProgressHUD.hide(for: self.view, animated: true)
                                                                if let err = error {
                                                                    err.alert(at : self.view)
                                                                }
                                                            })
                }))
                
                alertController.popoverPresentationController?.sourceView = self.tableView
                alertController.popoverPresentationController?.sourceRect = CGRect(x: self.tableView.bounds.midX, y: self.tableView.bounds.maxY - 100, width: 0, height: 0)
                alertController.assignActionsAccessibilityIdentifiers()
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
        let deleteAction = UITableViewRowAction(style: .default,
                                                title: LocalString._general_delete_action,
                                                handler: deleteClosure)
        return [deleteAction]
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
        //TODO:: add this later the full size index
        //        - (void)viewDidLoad
        //            {
        //                [super viewDidLoad];
        //                self.indexArray = @[@"{search}", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J",@"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
        //            }
        //
        //            - (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
        //        {
        //            NSString *letter = [self.indexArray objectAtIndex:index];
        //            NSUInteger sectionIndex = [[self.fetchedResultsController sectionIndexTitles] indexOfObject:letter];
        //            while (sectionIndex > [self.indexArray count]) {
        //                if (index <= 0) {
        //                    sectionIndex = 0;
        //                    break;
        //                }
        //                sectionIndex = [self tableView:tableView sectionForSectionIndexTitle:title atIndex:index - 1];
        //            }
        //
        //            return sectionIndex;
        //            }
        //
        //            - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
        //        {
        //            return self.indexArray;
        //        }
        return self.viewModel.sectionForSectionIndexTitle(title: title, atIndex: index)
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.viewModel.sectionIndexTitle()
    }
    
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension ContactsViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        self.tableViewBottomConstraint.constant = 0
        let keyboardInfo = notification.keyboardInfo
        UIView.animate(withDuration: keyboardInfo.duration,
                       delay: 0,
                       options: keyboardInfo.animationOption,
                       animations: { () -> Void in
                        self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.tableViewBottomConstraint.constant = keyboardSize.height
            
            UIView.animate(withDuration: keyboardInfo.duration,
                           delay: 0,
                           options: keyboardInfo.animationOption,
                           animations: { () -> Void in
                            self.view.layoutIfNeeded()
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
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            }
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: UITableView.RowAnimation.fade)
            }
        case .update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRow(at: indexPath) as? ContactsTableViewCell {
                    if let contact = self.viewModel.item(index: indexPath) {
                        cell.config(name: contact.name,
                                    email: contact.getDisplayEmails(),
                                    highlight: self.searchString)
                    }
                }
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        default:
            break
        }
    }
}

// detect view dismiss above iOS 13
@available (iOS 13, *)
extension ContactsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        self.isOnMainView = true
    }
}
