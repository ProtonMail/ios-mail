//
//  ContactGroupViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/17.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit
import CoreData

/**
 When the core data that provides data to this controller has data changes,
 the update will be performed immediately and automatically by core data
 */
class ContactGroupsViewController: ProtonMailViewController, ViewModelProtocol
{
    var viewModel: ContactGroupsViewModel!
    
    let kContactGroupCellIdentifier = "ContactGroupCustomCell"
    let kToContactGroupDetailSegue = "toContactGroupDetailSegue"
    
    var fetchedContactGroupResultsController: NSFetchedResultsController<NSFetchRequestResult>? = nil
    var refreshControl: UIRefreshControl!
    var searchController: UISearchController!
    
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
        tableView.register(UINib(nibName: "ContactGroupsViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupCellIdentifier)
        
        tableView.noSeparatorsBelowFooter()
        
        // fetch controller
        fetchedContactGroupResultsController = sharedLabelsDataService.fetchedResultsController(.contactGroup)
        fetchedContactGroupResultsController?.delegate = self
        if let fetchController = fetchedContactGroupResultsController {
            do {
                try fetchController.performFetch()
            } catch let error as NSError {
                PMLog.D("fetchedContactGroupResultsController Error: \(error.userInfo)")
            }
        }
        
        // refresh control
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        refreshControl.addTarget(self,
                                 action: #selector(fireFetch),
                                 for: UIControlEvents.valueChanged)
        tableView.addSubview(self.refreshControl)
        refreshControl.tintColor = UIColor.gray
        refreshControl.tintColorDidChange()
        
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.prepareSearchBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Groups"
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func prepareSearchBar() {
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
        }
    }
}

extension ContactGroupsViewController: UISearchBarDelegate, UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController) {
        //viewModel.search(text: searchController.searchBar.text)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
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
                    cell.config(name: label.name,
                                count: label.emails.count,
                                color: label.color)
                } else {
                    // TODO; better error handling
                    cell.config(name: "Error in retrieving contact group name in core data",
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
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let fetchedController = fetchedContactGroupResultsController {
            self.performSegue(withIdentifier: kToContactGroupDetailSegue,
                              sender: fetchedController.object(at: indexPath))
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
                        cell.config(name: label.name,
                                    count: label.emails.count,
                                    color: label.color)
                    } else {
                        // TODO; better error handling
                        cell.config(name: "Error in retrieving contact group name in core data",
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
