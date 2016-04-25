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
import CoreData
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class SearchViewController: ProtonMailViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var noResultLabel: UILabel!
    
    // MARK: - Private Constants
    
    fileprivate let kAnimationDuration: TimeInterval = 0.3
    fileprivate let kSearchCellHeight: CGFloat = 64.0
    fileprivate let kCellIdentifier: String = "SearchedCell"
    fileprivate let kSegueToMessageDetailController: String = "toMessageDetailViewController"

    // MARK: - Private attributes
    
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    fileprivate var managedObjectContext: NSManagedObjectContext?
    
    fileprivate var currentPage = 0;
    fileprivate var stop : Bool = false;

    fileprivate var query: String = "" {
        didSet {
            handleFromLocal(query)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.noSeparatorsBelowFooter()
        self.tableView!.RegisterCell(MailboxMessageCell.Constant.identifier)
        
        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars=false;
        automaticallyAdjustsScrollViewInsets = true
        self.navigationController?.navigationBar.isTranslucent = false;
        
        searchTextField.autocapitalizationType = UITextAutocapitalizationType.none
        searchTextField.returnKeyType = .search
        searchTextField.delegate = self
        searchTextField.font = UIFont.robotoRegular(size: UIFont.Size.h4)
        searchTextField.textColor = UIColor.white
        searchTextField.tintColor = UIColor.white
        searchTextField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Search", comment: "Title"), attributes:
            [
                NSForegroundColorAttributeName: UIColor.white,
                NSFontAttributeName: UIFont.robotoLight(size: UIFont.Size.h3)
            ])
        
        managedObjectContext = sharedCoreDataService.newMainManagedObjectContext()
        
        if let context = managedObjectContext {
            fetchedResultsController = fetchedResultsControllerForSearch(managedObjectContext: context)
            fetchedResultsController?.delegate = self
        }
        
        searchTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    // my selector that was defined above
    func willEnterForeground() {
        self.dismiss(animated: false, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.tableView.responds(to: #selector(setter: UITableViewCell.separatorInset))) {
            self.tableView.separatorInset = UIEdgeInsets.zero
        }
        
        if (self.tableView.responds(to: #selector(setter: UIView.layoutMargins))) {
            self.tableView.layoutMargins = UIEdgeInsets.zero
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData();
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchTextField.resignFirstResponder()
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func configureNavigationBar() {
        super.configureNavigationBar()
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;//.Blue_475F77
    }
    
    func fetchedResultsControllerForSearch(managedObjectContext context: NSManagedObjectContext) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Message.Attributes.time, ascending: false)]
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func handleFromLocal(_ query: String) {
        if managedObjectContext != nil {
            if let fetchedResultsController = fetchedResultsController {
                fetchedResultsController.fetchRequest.predicate = predicateForSearch(query)
                fetchedResultsController.delegate = nil
                do {
                    try fetchedResultsController.performFetch()
                }catch {
                    PMLog.D(" performFetch error: \(error)")
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
        noResultLabel.isHidden = false
        if let count = fetchedResultsController?.numberOfRowsInSection(0) {
            if count > 0 {
                noResultLabel.isHidden = true
            }
        }
    }
    
    func handleQuery(_ query: String) {
        //let context = sharedCoreDataService.newMainManagedObjectContext()
//        if let fetchedResultsController = fetchedResultsController {
//            fetchedResultsController.fetchRequest.predicate = predicateForSearch(query)
//            fetchedResultsController.delegate = nil
//            
//            var error: NSError?
//            if !fetchedResultsController.performFetch(&error) {
//                PMLog.D(" performFetch error: \(error!)")
//            }
//            
//            tableView.reloadData()
//            
//            fetchedResultsController.delegate = self
//        }
        if query.isEmpty || stop {
            return
        }
        noResultLabel.isHidden = true
        tableView.showLoadingFooter()
        
        
        sharedMessageDataService.search(query, page: currentPage, completion: { (messages, error) -> Void in
            self.tableView.hideLoadingFooter()
            
            if messages?.count > 0 {
                self.currentPage += 1
                if error != nil {
                    PMLog.D(" search error: \(String(describing: error))")
                } else {
                    
                }
            } else {
                self.stop = true
            }
            
            self.handleFromLocal(query)
        })
    }
    
    func predicateForSearch(_ query: String) -> NSPredicate? {
        return NSPredicate(format: "(%K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@ OR %K CONTAINS[cd] %@) AND (%K != -1) AND (%K != 1)", Message.Attributes.title, query, Message.Attributes.senderName, query, Message.Attributes.recipientList, query, Message.Attributes.senderObject, query, Message.Attributes.locationNumber, Message.Attributes.locationNumber)
    }
    
    func fetchMessagesIfNeededForIndexPath(_ indexPath: IndexPath) {
        if let fetchedResultsController = fetchedResultsController {
            if let last = fetchedResultsController.fetchedObjects?.last as? Message {
                if let current = fetchedResultsController.object(at: indexPath) as? Message {
                    if last == current {
                        handleQuery(query)
                    }
                }
            }
        }
    }

    @IBAction func tapAction(_ sender: AnyObject) {
        searchTextField.resignFirstResponder()
    }
    // MARK: - Button Actions
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Prepare for segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == kSegueToMessageDetailController) {
            let messageDetailViewController = segue.destination as! MessageViewController
            let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = fetchedResultsController?.object(at: indexPathForSelectedRow) as? Message {
                    messageDetailViewController.message = message
                }
            } else {
                PMLog.D("No selected row.")
            }
        }
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension SearchViewController: NSFetchedResultsControllerDelegate {
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
                tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
            }
        case .update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRow(at: indexPath) as? MailboxMessageCell {
                    if let message = fetchedResultsController?.object(at: indexPath) as? Message {
                        cell.configureCell(message, showLocation: true, ignoredTitle: "")
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.numberOfSections() ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.numberOfRowsInSection(section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mailboxCell = tableView.dequeueReusableCell(withIdentifier: MailboxMessageCell.Constant.identifier, for: indexPath) as! MailboxMessageCell
        if self.fetchedResultsController?.numberOfRowsInSection(indexPath.section) > indexPath.row {
            if let message = fetchedResultsController?.object(at: indexPath) as? Message {
                mailboxCell.configureCell(message, showLocation: true, ignoredTitle: "")
            }
        }
        return mailboxCell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (cell.responds(to: #selector(setter: UITableViewCell.separatorInset))) {
            cell.separatorInset = UIEdgeInsets.zero
        }
        
        if (cell.responds(to: #selector(setter: UIView.layoutMargins))) {
            cell.layoutMargins = UIEdgeInsets.zero
        }
        
        fetchMessagesIfNeededForIndexPath(indexPath)
    }
}


// MARK: - UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.fetchedResultsController?.numberOfRowsInSection(indexPath.section) > indexPath.row {
            if let _ = fetchedResultsController?.object(at: indexPath) as? Message {
                self.performSegue(withIdentifier: kSegueToMessageDetailController, sender: self)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kSearchCellHeight
    }
}


// MARK: - UITextFieldDelegate

extension SearchViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        query = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        self.stop = false
        handleQuery(query)
        
        return true
    }
}
