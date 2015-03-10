//
//  DraftViewController.swift
//  ProtonMail
//
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

import Foundation

class DraftViewController: UITableViewController {
    
    private let cellIdentifier = "DraftTableViewCell"
    private let estimatedCellHeight: CGFloat = 94.0
    private let viewControllerWidth: CGFloat = 100.0
    
    private var fetchedResultsController: NSFetchedResultsController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = estimatedCellHeight

        revealViewController().rightViewRevealWidth = viewControllerWidth
        revealViewController().rightViewRevealOverdraw = 0
        
        setupRefreshControl()
        
        setupFetchedResultsController()
    }
    
    // MARK: - Private methods
    
    private func configureCell(cell: DraftTableViewCell, atIndexPath indexPath: NSIndexPath) {
        if let draft = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
            cell.subject = draft.title
        }
    }
    
    func configureNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.barTintColor = UIColor.ProtonMail.Blue_475F77
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: navigationBarTitleFont
        ]
    }
    
    private func setupFetchedResultsController() {
        fetchedResultsController = sharedMessageDataService.fetchedResultsControllerForLocation(.draft)
        fetchedResultsController?.delegate = self
        
        if let fetchedResultsController = fetchedResultsController {
            var error: NSError?
            if !fetchedResultsController.performFetch(&error) {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
    }
    
    private func setupRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl!.backgroundColor = UIColor.ProtonMail.Blue_475F77
        refreshControl!.tintColor = UIColor.whiteColor()
        refreshControl!.addTarget(self, action: "getLatestMessages", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    // MARK: Actions
    
    func getLatestMessages() {
        if !refreshControl!.refreshing {
            refreshControl!.beginRefreshing()
        }
        
        sharedMessageDataService.fetchLatestMessagesForLocation(.draft) { _, messages, error in
            if let error = error {
                NSLog("error: \(error)")
            }
            
            self.refreshControl!.endRefreshing()
        }
        
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension DraftViewController: NSFetchedResultsControllerDelegate {
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
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? DraftTableViewCell {
                    configureCell(cell, atIndexPath: indexPath)
                }
            }
        default:
            return
        }
    }
}


// MARK: - UITableViewDataSource

extension DraftViewController: UITableViewDataSource {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.numberOfSections() ?? 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as DraftTableViewCell
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.numberOfRowsInSection(section) ?? 0
    }
}


// MARK: - UITableViewDelegate

extension DraftViewController: UITableViewDelegate {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        NSLog("\(__FUNCTION__) \(indexPath)")
        
        // TODO: load composition view controller for this draft in the front view controller
    }
}
