//
//  ContactGroupViewController.swift
//  ProtonMail
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
import CoreData
import PromiseKit
import MBProgressHUD

/**
 When the core data that provides data to this controller has data changes,
 the update will be performed immediately and automatically by core data
 */
class ContactGroupsViewController: ContactsAndGroupsSharedCode, ViewModelProtocol {
    typealias viewModelType = ContactGroupsViewModel
    
    private var viewModel: ContactGroupsViewModel!
    private var queryString = ""
    
    // long press related vars
    private var isEditingState: Bool = false
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds
    private var trashcanBarButtonItem: UIBarButtonItem? = nil
    private var cancelBarButtonItem: UIBarButtonItem? = nil
    private var totalSelectedContactGroups: Int = 0 {
        didSet {
            if isEditingState {
                title = String.init(format: LocalString._contact_groups_selected_group_count_description,
                                    totalSelectedContactGroups)
            }
        }
    }
    
    private let kContactGroupCellIdentifier = "ContactGroupCustomCell"
    private let kToContactGroupDetailSegue = "toContactGroupDetailSegue"
    private let kToComposerSegue = "toComposer"
    
    private var refreshControl: UIRefreshControl!
    private var searchController: UISearchController!
    
    
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    func set(viewModel: ContactGroupsViewModel) {
        self.viewModel = viewModel
    }
    
    
    func inactiveViewModel() {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        
        prepareTable()
        prepareFetchedResultsController()
        prepareSearchBar()
        
        if self.viewModel.initEditing() {
            isEditingState = true
            tableView.allowsMultipleSelection = true
            prepareNavigationItemTitle()
            self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem
        } else {
            prepareRefreshController()
            prepareLongPressGesture()
            prepareNavigationItemRightDefault(self.viewModel.user)
            updateNavigationBar()
        }
        generateAccessibilityIdentifiers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.timerStart(true)
        self.isOnMainView = true
        NotificationCenter.default.addKeyboardObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.timerStop()
        viewModel.save()
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    private func prepareFetchedResultsController() {
        let _ = self.viewModel.setFetchResultController(delegate: self)
    }
    
    private func prepareRefreshController() {
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        refreshControl.addTarget(self,
                                 action: #selector(fireFetch),
                                 for: UIControl.Event.valueChanged)
        tableView.addSubview(self.refreshControl)
        refreshControl.tintColor = UIColor.gray
        refreshControl.tintColorDidChange()
    }
    
    private func prepareTable() {
        tableView.register(UINib(nibName: "ContactGroupsViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupCellIdentifier)
        
        tableView.noSeparatorsBelowFooter()
        tableView.estimatedRowHeight = 60.0
    }
    
    private func prepareLongPressGesture() {
        totalSelectedContactGroups = 0
        
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc private func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        // blocks contact group view from editing
        if viewModel.user.isPaid == false {
            self.performSegue(withIdentifier: kToUpgradeAlertSegue,
                              sender: self)
            return
        }
        
        // mark the location that it is on
        markLongPressLocation(longPressGestureRecognizer)
    }
    
    private func markLongPressLocation(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let pressingLocation = longPressGestureRecognizer.location(in: tableView)
        let pressedIndexPath = tableView.indexPathForRow(at: pressingLocation)
        
        if let pressedIndexPath = pressedIndexPath {
            if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
                // set state
                isEditingState = true
                tableView.allowsMultipleSelection = true
                
                // prepare the navigationItems
                updateNavigationBar()
                
                // set cell
                if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
                    for visibleIndexPath in visibleIndexPaths {
                        if visibleIndexPath == pressedIndexPath {
                            // mark this indexPath as selected
                            if let cell = tableView.cellForRow(at: visibleIndexPath) as? ContactGroupsViewCell {
                                self.selectRow(at: visibleIndexPath, groupID: cell.getLabelID())
                            } else {
                                PMLog.D("FatalError: Conversion failed")
                            }
                        }
                    }
                } else {
                    PMLog.D("No visible index path")
                }
            }
        } else {
            PMLog.D("Not long pressed on the cell")
        }
    }
    
    private func updateNavigationBar() {
        prepareNavigationItemLeft()
        prepareNavigationItemTitle()
        prepareNavigationItemRight()
    }
    
    private func prepareNavigationItemLeft() {
        if isEditingState {
            // make cancel button and selector
            if cancelBarButtonItem == nil {
                cancelBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(self.cancelBarButtonTapped))
            }
            
            navigationItem.leftBarButtonItems = [cancelBarButtonItem!]
        } else {
            // restore the left bar
            navigationItem.leftBarButtonItems = navigationItemLeftNotEditing
        }
    }
    
    // end long press event
    @objc private func cancelBarButtonTapped() {
        // reset state
        isEditingState = false
        tableView.allowsMultipleSelection = false
        
        // reset navigation bar
        updateNavigationBar()
        
        // unselect all
        totalSelectedContactGroups = 0
        viewModel.removeAllSelectedGroups()
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            for selectedIndexPath in selectedIndexPaths {
                tableView.deselectRow(at: selectedIndexPath,
                                      animated: true)
            }
        }
    }
    
    private func prepareNavigationItemTitle() {
        if isEditingState {
            self.title = String.init(format: LocalString._contact_groups_selected_group_count_description,
                                     0)
        } else {
            self.title = LocalString._menu_contact_group_title
        }
    }
    
    private func prepareNavigationItemRight() {
        if isEditingState {
            // make trash can and selector
            if trashcanBarButtonItem == nil {
                trashcanBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .trash,
                                                             target: self,
                                                             action: #selector(self.trashcanBarButtonTapped))
            }
            
            navigationItem.rightBarButtonItems = [trashcanBarButtonItem!]
        } else {
            // restore the right bar
            navigationItem.rightBarButtonItems = navigationItemRightNotEditing
        }
    }
    
    private func resetStateFromMultiSelect()
    {
        // reset state
        self.isEditingState = false
        self.tableView.allowsMultipleSelection = false
        self.totalSelectedContactGroups = 0
        
        // reset navigation bar
        self.updateNavigationBar()
    }
    
    @objc private func trashcanBarButtonTapped() {
        let deleteHandler = {
            (action: UIAlertAction) -> Void in
            firstly {
                () -> Promise<Void> in
                // attempt to delete selected groups
                MBProgressHUD.showAdded(to: self.view, animated: true)
                return self.viewModel.deleteGroups()
                }.done {
                    self.resetStateFromMultiSelect()
                }.ensure {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }.catch {
                    error in
                    error.alert(at: self.view)
            }
        }
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: LocalString._contact_groups_delete,
                                                style: .destructive,
                                                handler: deleteHandler))
        
        alertController.popoverPresentationController?.barButtonItem = trashcanBarButtonItem
        self.present(alertController, animated: true, completion: nil)
    }
    
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
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.automaticallyAdjustsScrollViewInsets = true
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.keyboardType = .default
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
    }
    
    @objc func fireFetch() {
        firstly {
            return self.viewModel.fetchLatestContactGroup()
            }.done {
                self.refreshControl.endRefreshing()
            }.catch { error in
                error.alert(at: self.view)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.isOnMainView = false // hide the tab bar
        let viewController = segue.destination
        
        if segue.identifier == kToContactGroupDetailSegue {
            let contactGroupDetailViewController = segue.destination as! ContactGroupDetailViewController
            let contactGroup = sender as! Label
            sharedVMService.contactGroupDetailViewModel(contactGroupDetailViewController,
                                                        user: self.viewModel.user,
                                                        groupID: contactGroup.labelID,
                                                        name: contactGroup.name,
                                                        color: contactGroup.color,
                                                        emailIDs: (contactGroup.emails as? Set<Email>) ?? Set<Email>())
        } else if (segue.identifier == kAddContactSugue) {
            let addContactViewController = segue.destination.children[0] as! ContactEditViewController
            sharedVMService.contactAddViewModel(addContactViewController, user: self.viewModel.user)
        } else if (segue.identifier == kAddContactGroupSugue) {
            let addContactGroupViewController = segue.destination.children[0] as! ContactGroupEditViewController
            sharedVMService.contactGroupEditViewModel(addContactGroupViewController, user: self.viewModel.user, state: .create)
        } else if segue.identifier == kSegueToImportView {
            self.isOnMainView = true
            let popup = segue.destination as! ContactImportViewController
            // TODO: inject it via ViewModel when ContactImportViewController will have one
            popup.user = self.viewModel.user
            self.setPresentationStyleForSelfController(self,
                                                       presentingController: popup,
                                                       style: .overFullScreen)
        } else if segue.identifier == kToComposerSegue {
            guard let nav = segue.destination as? UINavigationController,
                let next = nav.viewControllers.first as? ComposeContainerViewController else
            {
                return
            }
            let user = self.viewModel.user
            let viewModel = ContainableComposeViewModel(msg: nil, action: .newDraft, msgService: user.messageService, user: user, coreDataService: self.viewModel.coreDataService)
            if let result = sender as? (String, String) {
                let contactGroupVO = ContactGroupVO.init(ID: result.0, name: result.1)
                contactGroupVO.selectAllEmailFromGroup()
                viewModel.addToContacts(contactGroupVO)
            }
            next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel))
            next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
            
        } else if segue.identifier == kToUpgradeAlertSegue {
            let popup = segue.destination as! UpgradeAlertViewController
            popup.delegate = self
            sharedVMService.upgradeAlert(contacts: popup)
            self.setPresentationStyleForSelfController(self,
                                                       presentingController: popup,
                                                       style: .overFullScreen)
        }
        
        if #available(iOS 13, *) { // detect view dismiss above iOS 13
            if let nav = viewController as? UINavigationController {
                nav.children[0].presentationController?.delegate = self
            }
            segue.destination.presentationController?.delegate = self
        }
    }
    
    func selectRow(at indexPath: IndexPath, groupID: String) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        viewModel.addSelectedGroup(ID: groupID, indexPath: indexPath)
        totalSelectedContactGroups = viewModel.getSelectedCount()
    }
    
    func deselectRow(at indexPath: IndexPath, groupID: String) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.removeSelectedGroup(ID: groupID, indexPath: indexPath)
        totalSelectedContactGroups = viewModel.getSelectedCount()
    }
}

extension ContactGroupsViewController: UISearchBarDelegate, UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(text: searchController.searchBar.text, searchActive: searchController.isActive)
        queryString = searchController.searchBar.text ?? ""
        tableView.reloadData()
    }
}

extension ContactGroupsViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.count()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: kContactGroupCellIdentifier, for: indexPath)
        if let cell = cell as? ContactGroupsViewCell {
            let data = self.viewModel.dateForRow(at: indexPath)
            cell.config(labelID: data.ID,
                        name: data.name,
                        queryString: self.queryString,
                        count: data.count,
                        color: data.color,
                        wasSelected: viewModel.isSelected(groupID: data.ID),
                        showSendEmailIcon: data.showEmailIcon,
                        delegate: self)
            if viewModel.isSelected(groupID: data.ID) {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? ContactGroupsViewCell else {
            return
        }
        if viewModel.initEditing() {
            if viewModel.isSelected(groupID: cell.getLabelID()) {
                self.selectRow(at: indexPath, groupID: cell.getLabelID())
            }
        }
    }
}

extension ContactGroupsViewController: ContactGroupsViewCellDelegate
{
    func isMultiSelect() -> Bool {
        return isEditingState || viewModel.initEditing()
    }
    
    func sendEmailToGroup(ID: String, name: String) {
        if viewModel.user.isPaid {
            self.performSegue(withIdentifier: kToComposerSegue, sender: (ID: ID, name: name))
        } else {
            self.performSegue(withIdentifier: kToUpgradeAlertSegue, sender: self)
        }
    }
}

extension ContactGroupsViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        self.resetStateFromMultiSelect()
        
        let deleteHandler = {
            (action: UITableViewRowAction, indexPath: IndexPath) -> Void in
            
            let deleteActionHandler = {
                (action: UIAlertAction) -> Void in
                
                firstly {
                    () -> Promise<Void> in
                    // attempt to delete selected groups
                    MBProgressHUD.showAdded(to: self.view, animated: true)
                    if let cell = self.tableView.cellForRow(at: indexPath) as? ContactGroupsViewCell {
                        self.viewModel.addSelectedGroup(ID: cell.getLabelID(),
                                                        indexPath: indexPath)
                    }
                    return self.viewModel.deleteGroups()
                    }.ensure {
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }.catch {
                        error in
                        error.alert(at: self.view)
                }
            }
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button,
                                                    style: .cancel,
                                                    handler: nil))
            alertController.addAction(UIAlertAction(title: LocalString._contact_groups_delete,
                                                    style: .destructive,
                                                    handler: deleteActionHandler))
            
            alertController.popoverPresentationController?.sourceView = self.tableView
            alertController.popoverPresentationController?.sourceRect = CGRect(x: self.tableView.bounds.midX, y: self.tableView.bounds.maxY - 100, width: 0, height: 0)
            
            self.present(alertController, animated: true, completion: nil)
        }
        
        let deleteAction = UITableViewRowAction.init(style: .destructive,
                                                     title: LocalString._general_delete_action,
                                                     handler: deleteHandler)
        return [deleteAction]
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditingState {
            // blocks contact email cell contact group editing
            if viewModel.user.isPaid == false {
                tableView.deselectRow(at: indexPath, animated: true)
                self.performSegue(withIdentifier: kToUpgradeAlertSegue, sender: self)
                return
            }
            if let cell = tableView.cellForRow(at: indexPath) as? ContactGroupsViewCell {
                self.selectRow(at: indexPath, groupID: cell.getLabelID())
                if viewModel.initEditing() {
                    cell.setCount(viewModel.dateForRow(at: indexPath).count)
                }
            } else {
                PMLog.D("FatalError: Conversion failed")
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            if let label = self.viewModel.labelForRow(at: indexPath) {
                self.performSegue(withIdentifier: kToContactGroupDetailSegue, sender: label)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditingState {
            // blocks contact email cell contact group editing
            if viewModel.user.isPaid == false {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                self.performSegue(withIdentifier: kToUpgradeAlertSegue, sender: self)
                return
            }
            
            if let cell = tableView.cellForRow(at: indexPath) as? ContactGroupsViewCell {
                self.deselectRow(at: indexPath, groupID: cell.getLabelID())
                if viewModel.initEditing() {
                    cell.setCount(viewModel.dateForRow(at: indexPath).count)
                }
            } else {
                PMLog.D("FatalError: Conversion failed")
            }
        }
    }
}

extension ContactGroupsViewController: UpgradeAlertVCDelegate {
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

extension ContactGroupsViewController: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        if self.viewModel.searchingActive() {
            return
        }
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: UITableView.RowAnimation.fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            }
        case .update:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                guard let cell = tableView.cellForRow(at: indexPath) as? ContactGroupsViewCell else {
                    return
                }
                let data = self.viewModel.dateForRow(at: newIndexPath)
                cell.config(labelID: data.ID,
                            name: data.name,
                            queryString: self.queryString,
                            count: data.count,
                            color: data.color,
                            wasSelected: viewModel.isSelected(groupID: data.ID),
                            showSendEmailIcon: data.showEmailIcon,
                            delegate: self)
            }
        case .move: // group order might change! (renaming)
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            return
        @unknown default:
            return
        }
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension ContactGroupsViewController: NSNotificationCenterKeyboardObserverProtocol {
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


// detect view dismiss above iOS 13
@available (iOS 13, *)
extension ContactGroupsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        self.isOnMainView = true
    }
}
