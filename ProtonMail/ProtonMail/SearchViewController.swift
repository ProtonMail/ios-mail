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

import CoreData
import UIKit

class SearchViewController: ProtonMailViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var noResultLabel: UILabel!
    
    // MARK: - Private Constants
    
    private let kAnimationDuration: NSTimeInterval = 0.3
    private let kSearchCellHeight: CGFloat = 64.0
    private let kCellIdentifier: String = "SearchedCell"
    private let kSegueToMessageDetailController: String = "toMessageDetailViewController"

    // MARK: - Private attributes
    
    private var fetchedResultsController: NSFetchedResultsController?
    private var managedObjectContext: NSManagedObjectContext?
    
    private var currentPage = 0;
    private var stop : Bool = false;

    private var query: String = "" {
        didSet {
            handleFromLocal(query)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.noSeparatorsBelowFooter()
        
        searchTextField.autocapitalizationType = UITextAutocapitalizationType.None
        searchTextField.returnKeyType = .Search
        searchTextField.delegate = self
        searchTextField.font = UIFont.robotoRegular(size: UIFont.Size.h4)
        searchTextField.textColor = UIColor.whiteColor()
        searchTextField.tintColor = UIColor.whiteColor()
        searchTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Search"), attributes:
            [
                NSForegroundColorAttributeName: UIColor.whiteColor(),
                NSFontAttributeName: UIFont.robotoLight(size: UIFont.Size.h3)
            ])
        
        managedObjectContext = sharedCoreDataService.newMainManagedObjectContext()
        
        if let context = managedObjectContext {
            fetchedResultsController = fetchedResultsControllerForSearch(managedObjectContext: context)
            fetchedResultsController?.delegate = self
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.tableView.respondsToSelector("setSeparatorInset:")) {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if (self.tableView.respondsToSelector("setLayoutMargins:")) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        searchTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        searchTextField.resignFirstResponder()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func configureNavigationBar() {
        super.configureNavigationBar()
        self.searchDisplayController?.displaysSearchBarInNavigationBar = true
        //self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Blue_5C7A99
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;//.Blue_475F77
    }
    
    func fetchedResultsControllerForSearch(managedObjectContext context: NSManagedObjectContext) -> NSFetchedResultsController? {
        let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func handleFromLocal(query: String) {
        if let context = managedObjectContext {
            if let fetchedResultsController = fetchedResultsController {
                fetchedResultsController.fetchRequest.predicate = predicateForSearch(query)
                fetchedResultsController.delegate = nil
                
                var error: NSError?
                if !fetchedResultsController.performFetch(&error) {
                    NSLog("\(__FUNCTION__) performFetch error: \(error!)")
                }
                
                tableView.reloadData()
                showHideNoresult()
                fetchedResultsController.delegate = self
            }
            
            if query.isEmpty {
                return
            }
        }
    }
    
    func showHideNoresult(){
        noResultLabel.hidden = false
        if let count = fetchedResultsController?.numberOfRowsInSection(0) {
            if count > 0 {
                noResultLabel.hidden = true
            }
        }
    }
    
    func handleQuery(query: String) {
        let context = sharedCoreDataService.newMainManagedObjectContext()
//        if let fetchedResultsController = fetchedResultsController {
//            fetchedResultsController.fetchRequest.predicate = predicateForSearch(query)
//            fetchedResultsController.delegate = nil
//            
//            var error: NSError?
//            if !fetchedResultsController.performFetch(&error) {
//                NSLog("\(__FUNCTION__) performFetch error: \(error!)")
//            }
//            
//            tableView.reloadData()
//            
//            fetchedResultsController.delegate = self
//        }
        if query.isEmpty || stop {
            return
        }
        noResultLabel.hidden = true
        tableView.showLoadingFooter()
        
        
        sharedMessageDataService.search(query: query, page: currentPage, completion: { (messages, error) -> Void in
            self.tableView.hideLoadingFooter()
            
            if messages?.count > 0 {
                self.currentPage += 1
                if error != nil {
                    NSLog("\(__FUNCTION__) search error: \(error)")
                } else {
                    
                }
            } else {
                self.stop = true
            }
            
            self.handleFromLocal(query)
        })
    }
    
    func predicateForSearch(query: String) -> NSPredicate? {
        return NSPredicate(format: "(%K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@) AND (%K != -1) AND (%K != 1)", Message.Attributes.title, query, Message.Attributes.senderName, query, Message.Attributes.recipientList, query, Message.Attributes.locationNumber, Message.Attributes.locationNumber)
    }
    
    func fetchMessagesIfNeededForIndexPath(indexPath: NSIndexPath) {
        if let fetchedResultsController = fetchedResultsController {
            if let last = fetchedResultsController.fetchedObjects?.last as? Message {
                if let current = fetchedResultsController.objectAtIndexPath(indexPath) as? Message {
                    if last == current {
                        handleQuery(query)
                    }
                }
            }
        }
    }

    // MARK: - Button Actions
    
    @IBAction func cancelButtonTapped(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Prepare for segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == kSegueToMessageDetailController) {
            let messageDetailViewController = segue.destinationViewController as! MessageViewController
            let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = fetchedResultsController?.objectAtIndexPath(indexPathForSelectedRow) as? Message {
                    messageDetailViewController.message = message
                }
            } else {
                println("No selected row.")
            }
        }
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension SearchViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch(type) {
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch(type) {
        case .Delete:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        case .Insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
        case .Update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MailboxTableViewCell {
                    if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
                        cell.configureCell(message)
                    }
                }
            }
        default:
            return
        }
    }
}


// MARK: - UITableViewDataSource

extension SearchViewController: UITableViewDataSource {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.numberOfSections() ?? 0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.numberOfRowsInSection(section) ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier, forIndexPath: indexPath) as! MailboxTableViewCell
        if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
            cell.configureCell(message)
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if (cell.respondsToSelector("setSeparatorInset:")) {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if (cell.respondsToSelector("setLayoutMargins:")) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        
        fetchMessagesIfNeededForIndexPath(indexPath)
    }
}


// MARK: - UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        NSLog("\(__FUNCTION__) \(indexPath)")
        
        if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
            self.performSegueWithIdentifier(kSegueToMessageDetailController, sender: self)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kSearchCellHeight
    }
}


// MARK: - UITextFieldDelegate

extension SearchViewController: UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        query = (textField.text as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        self.stop = false
        handleQuery(query)
        
        return true
    }
}
