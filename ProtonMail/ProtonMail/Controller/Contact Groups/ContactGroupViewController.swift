//
//  ContactGroupViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/17.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit
import CoreData
import PromiseKit

/**
 When the core data that provides data to this controller has data changes,
 the update will be performed immediately and automatically by core data
 */
class ContactGroupsViewController: ContactsAndGroupsSharedCode, ViewModelProtocol
{
    private var viewModel: ContactGroupsViewModel!
    
    // long press related vars
    private var isEditingState: Bool = false
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds
    private var trashcanBarButtonItem: UIBarButtonItem? = nil
    private var cancelBarButtonItem: UIBarButtonItem? = nil
    private var totalSelectedContactGroups: Int! {
        didSet {
            if isEditingState, let total = totalSelectedContactGroups {
                title = "\(total) Selected"
            }
        }
    }
    
    private let kContactGroupCellIdentifier = "ContactGroupCustomCell"
    private let kToContactGroupDetailSegue = "toContactGroupDetailSegue"
    
    private var fetchedContactGroupResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil
    private var refreshControl: UIRefreshControl!
    private var searchController: UISearchController!
    
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupsViewModel
    }
    
    func inactiveViewModel() {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        
        self.prepareTable()
        
        self.prepareFetchedResultsController()
        
        self.prepareRefreshController()
        
        self.prepareSearchBar()
        
        self.prepareLongPressGesture()
        prepareNavigationItemRightDefault()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func prepareFetchedResultsController() {
        fetchedContactGroupResultsController = sharedLabelsDataService.fetchedResultsController(.contactGroup)
        fetchedContactGroupResultsController?.delegate = self
        if let fetchController = fetchedContactGroupResultsController {
            do {
                try fetchController.performFetch()
            } catch let error as NSError {
                PMLog.D("fetchedContactGroupResultsController Error: \(error.userInfo)")
            }
        }
    }
    
    private func prepareRefreshController() {
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        refreshControl.addTarget(self,
                                 action: #selector(fireFetch),
                                 for: UIControlEvents.valueChanged)
        tableView.addSubview(self.refreshControl)
        refreshControl.tintColor = UIColor.gray
        refreshControl.tintColorDidChange()
    }
    
    private func prepareTable() {
        tableView.register(UINib(nibName: "ContactGroupsViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupCellIdentifier)
        
        tableView.noSeparatorsBelowFooter()
    }
    
    private func prepareLongPressGesture() {
        totalSelectedContactGroups = 0
        
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc private func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        // mark the location that it is on
        markLongPressLocation(longPressGestureRecognizer)
    }
    
    private func markLongPressLocation(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let pressingLocation = longPressGestureRecognizer.location(in: tableView)
        let pressedIndexPath = tableView.indexPathForRow(at: pressingLocation)
        
        if let pressedIndexPath = pressedIndexPath {
            if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
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
                            if let cell = tableView.cellForRow(at: pressedIndexPath) as? ContactGroupsViewCell {
                                cell.selectionStyle = .none
                                tableView.selectRow(at: pressedIndexPath,
                                                    animated: true,
                                                    scrollPosition: .none)
                                totalSelectedContactGroups = totalSelectedContactGroups + 1
                            } else {
                                PMLog.D("Error: can't get the cell of pressed index path ")
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
    
    @objc private func cancelBarButtonTapped() {
        // reset state
        isEditingState = false
        tableView.allowsMultipleSelection = false
        
        // reset navigation bar
        updateNavigationBar()
        
        // unselect all
        totalSelectedContactGroups = 0
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            for selectedIndexPath in selectedIndexPaths {
                tableView.deselectRow(at: selectedIndexPath,
                                      animated: true)
            }
        }
    }
    
    private func prepareNavigationItemTitle() {
        if isEditingState {
            // TODO: selected count
            self.title = "\(0) Selected"
        } else {
            self.title = "Groups"
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
    
    @objc private func trashcanBarButtonTapped() {
        firstly {
            () -> Promise<Void> in
            // attempt to delete selected groups
            var groupIDs: [String] = []
            if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
                for selectedIndexPath in selectedIndexPaths {
                    if let cell = tableView.cellForRow(at: selectedIndexPath) as? ContactGroupsViewCell {
                        groupIDs.append(cell.labelID)
                    }
                }
            }
            
            return viewModel.deleteGroups(groupIDs: groupIDs)
            }.done {
                // reset state
                self.isEditingState = false
                self.tableView.allowsMultipleSelection = false
                self.totalSelectedContactGroups = 0
                
                // reset navigation bar
                self.updateNavigationBar()
            }.catch {
                error in
                let alert = UIAlertController(title: "Error deleting groups",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                alert.addOKAction()
                
                self.present(alert,
                             animated: true,
                             completion: nil)
        }
    }
    
    private func prepareSearchBar() {
        viewModel.setFetchResultController(fetchedResultsController: &fetchedContactGroupResultsController)
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = LocalString._general_search_placeholder
        searchController.searchBar.setValue(LocalString._general_cancel_button,
                                            forKey:"_cancelButtonText")
        
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.automaticallyAdjustsScrollViewInsets = true
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.keyboardType = .default
        self.searchController.searchBar.autocapitalizationType = .none
        self.searchController.searchBar.isTranslucent = false
        self.searchController.searchBar.tintColor = .white
        self.searchController.searchBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background
        self.searchController.searchBar.backgroundColor = .clear
        
        if #available(iOS 11.0, *) {
            self.searchViewConstraint.constant = 0.0
            self.searchView.isHidden = true
            self.navigationItem.largeTitleDisplayMode = .never
            self.navigationItem.hidesSearchBarWhenScrolling = false
            self.navigationItem.searchController = self.searchController
        } else {
            self.searchViewConstraint.constant = self.searchController.searchBar.frame.height
            self.searchView.backgroundColor = UIColor.ProtonMail.Nav_Bar_Background
            self.searchView.addSubview(self.searchController.searchBar)
            self.searchController.searchBar.contactSearchSetup(textfieldBG: UIColor.init(hexColorCode: "#82829C"),
                                                               placeholderColor: UIColor.init(hexColorCode: "#BBBBC9"), textColor: .white)
        }
    }
    
    // TODO: fix me
    @objc func fireFetch() {
        self.viewModel.fetchAllContactGroup()
        self.refreshControl.endRefreshing() // this is fake
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToContactGroupDetailSegue {
            let contactGroupDetailViewController = segue.destination as! ContactGroupDetailViewController
            let contactGroup = sender as! Label
            sharedVMService.contactGroupDetailViewModel(contactGroupDetailViewController,
                                                        groupID: contactGroup.labelID,
                                                        name: contactGroup.name,
                                                        color: contactGroup.color,
                                                        emailIDs: contactGroup.emails)
        } else if (segue.identifier == kAddContactSugue) {
            let addContactViewController = segue.destination.childViewControllers[0] as! ContactEditViewController
            sharedVMService.contactAddViewModel(addContactViewController)
        } else if (segue.identifier == kAddContactGroupSugue) {
            let addContactGroupViewController = segue.destination.childViewControllers[0] as! ContactGroupEditViewController
            sharedVMService.contactGroupEditViewModel(addContactGroupViewController, state: .create)
        } else if segue.identifier == kSegueToImportView {
            let popup = segue.destination as! ContactImportViewController
            self.setPresentationStyleForSelfController(self,
                                                       presentingController: popup,
                                                       style: .overFullScreen)
        }
    }
}

extension ContactGroupsViewController: UISearchBarDelegate, UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(text: searchController.searchBar.text)
        tableView.reloadData()
    }
}

extension ContactGroupsViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetchedController = fetchedContactGroupResultsController {
            return fetchedController.fetchedObjects?.count ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: kContactGroupCellIdentifier, for: indexPath)
        
        if let cell = cell as? ContactGroupsViewCell {
            if let fetchedController = fetchedContactGroupResultsController {
                if let label = fetchedController.object(at: indexPath) as? Label {
                    cell.config(labelID: label.labelID,
                                name: label.name,
                                count: label.emails.count,
                                color: label.color)
                } else {
                    // TODO; better error handling
                    cell.config(labelID: "",
                                name: "Error in retrieving contact group name in core data",
                                count: 0,
                                color: nil)
                }
            }
        }
        
        return cell
    }
}

extension ContactGroupsViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditingState {
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.selectionStyle = .none
                tableView.selectRow(at: indexPath,
                                    animated: true,
                                    scrollPosition: .none)
                totalSelectedContactGroups = totalSelectedContactGroups + 1
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            
            if let fetchedController = fetchedContactGroupResultsController {
                self.performSegue(withIdentifier: kToContactGroupDetailSegue,
                                  sender: fetchedController.object(at: indexPath))
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditingState {
            tableView.deselectRow(at: indexPath, animated: true)
            totalSelectedContactGroups = totalSelectedContactGroups - 1
        }
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
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? ContactGroupsViewCell {
                if let fetchedController = fetchedContactGroupResultsController {
                    if let label = fetchedController.object(at: indexPath!) as? Label {
                        cell.config(labelID: label.labelID,
                                    name: label.name,
                                    count: label.emails.count,
                                    color: label.color)
                    } else {
                        // TODO; better error handling
                        cell.config(labelID: "",
                                    name: "Error in retrieving contact group name in core data",
                                    count: 0,
                                    color: nil)
                    }
                }
            }
        case .move:
            //            tableView.deleteRows(at: [indexPath!], with: .automatic)
            //            tableView.insertRows(at: [newIndexPath!], with: .automatic)
            return
        }
    }
}
