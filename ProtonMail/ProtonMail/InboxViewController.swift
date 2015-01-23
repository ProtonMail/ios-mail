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

class InboxViewController: ProtonMailViewController {
    
    
    // MARK: - View Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Private constants
    
    private let kInboxCellHeight: CGFloat = 64.0
    private let kCellIdentifier: String = "InboxCell"
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds
    
    
    // MARK: - Private attributes
    
    private var messages: [EmailThread]!
    private var selectedMessages: NSMutableSet = NSMutableSet()
    private var isEditing: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messages = EmailService.retrieveMessages()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
        
        var composeBarButtonItem = UIBarButtonItem(image: UIImage(named: "compose"), style: UIBarButtonItemStyle.Plain, target: self, action: "composeButtonTapped")
        var searchBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"), style: UIBarButtonItemStyle.Plain, target: self, action: "searchButtonTapped")
        var rightButtons = [composeBarButtonItem, searchBarButtonItem]
        
        self.navigationItem.rightBarButtonItems = rightButtons
    }
    
    
    // MARK: - Button Targets
    
    internal func composeButtonTapped() {
        
    }
    
    internal func searchButtonTapped() {
        
    }
    
    @IBAction func didTapCheckMessage(sender: UIButton) {
        let point: CGPoint = sender.convertPoint(CGPointZero, toView: self.tableView)
        let indexPath: NSIndexPath? = self.tableView.indexPathForRowAtPoint(point)
        
        if let indexPath = indexPath {
            let selectedCell: InboxTableViewCell = self.tableView.cellForRowAtIndexPath(indexPath) as InboxTableViewCell
            
            if (selectedMessages.containsObject(messages[indexPath.row].id)) {
                selectedMessages.removeObject(messages[indexPath.row].id)
            } else {
                selectedMessages.addObject(messages[indexPath.row].id)
            }
            
            selectedCell.checkboxTapped()
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    internal func handleLongPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let point: CGPoint = longPressGestureRecognizer.locationInView(self.tableView)
        let indexPath: NSIndexPath? = self.tableView.indexPathForRowAtPoint(point)
    
        if let indexPath = indexPath {
            if (longPressGestureRecognizer.state == UIGestureRecognizerState.Began) {
                self.isEditing = true
                
                let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows() as? [NSIndexPath]
                
                if let indexPathsForVisibleRows = indexPathsForVisibleRows {
                    for indexPath in indexPathsForVisibleRows {
                        let inboxTableViewCell: InboxTableViewCell = self.tableView.cellForRowAtIndexPath(indexPath) as InboxTableViewCell
                        inboxTableViewCell.showCheckboxOnLeftSide()
                        
                        UIView.animateWithDuration(0.25, animations: { () -> Void in
                            inboxTableViewCell.layoutIfNeeded()
                        })
                    }
                }
                println("Long press on table view at row \(indexPath.row)")
            }
        } else {
            println("Long press on table view, but not on a row.")
        }
    }
}


// MARK: - UITableViewDataSource

extension InboxViewController: UITableViewDataSource {
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.tableView.respondsToSelector("setSeparatorInset:")) {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if (self.tableView.respondsToSelector("setLayoutMargins:")) {
            self.tableView.layoutMargins = UIEdgeInsetsZero
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let thread: EmailThread = messages[indexPath.row]
        var inboxCell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier, forIndexPath: indexPath) as InboxTableViewCell
        inboxCell.configureCell(thread)
        inboxCell.setCellIsChecked(selectedMessages.containsObject(thread.id))
                        
        if (self.isEditing) {
            inboxCell.showCheckboxOnLeftSide()
        }
        
        return inboxCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if (cell.respondsToSelector("setSeparatorInset:")) {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if (cell.respondsToSelector("setLayoutMargins:")) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
    }
}


// MARK: - UITableViewDelegate

extension InboxViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kInboxCellHeight
    }
}