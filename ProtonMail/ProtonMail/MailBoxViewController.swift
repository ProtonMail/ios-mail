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

class MailBoxViewController: ProtonMailViewController {
    
    
    // MARK: - View Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Private constants
    
    private let kInboxCellHeight: CGFloat = 64.0
    private let kCellIdentifier: String = "InboxCell"
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds
    private let kSegueToSearchController: String = "toSearchViewController"
    private let kSegueToThreadController: String = "toThreadViewController"
    private let kMoreOptionsViewHeight: CGFloat = 123.0
    
    
    // MARK: - Private attributes
    
    internal var messages: [EmailThread]!
    internal var refreshControl: UIRefreshControl!

    private var moreOptionsView: MoreOptionsView!
    private var navigationTitleLabel = UILabel()
    private var selectedMessages: NSMutableSet = NSMutableSet()
    private var isEditing: Bool = false
    private var isViewingMoreOptions: Bool = false
    private var isUndoButtonTapped: Bool = false
    
    
    // MARK: - Right bar buttons
    
    private var composeBarButtonItem: UIBarButtonItem!
    private var searchBarButtonItem: UIBarButtonItem!
    private var removeBarButtonItem: UIBarButtonItem!
    private var favoriteBarButtonItem: UIBarButtonItem!
    private var moreBarButtonItem: UIBarButtonItem!
    
    
    // MARK: - Left bar button
    
    private var cancelBarButtonItem: UIBarButtonItem!
    private var menuBarButtonItem: UIBarButtonItem!
    
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubViews()
        addConstraints()
        
        self.updateNavigationController(isEditing)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let selectedItem: NSIndexPath? = self.tableView.indexPathForSelectedRow() as NSIndexPath?
        
        if let selectedItem = selectedItem {
            self.tableView.reloadRowsAtIndexPaths([selectedItem], withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.deselectRowAtIndexPath(selectedItem, animated: true)
        }
    }
    
    private func addSubViews() {
        self.moreOptionsView = MoreOptionsView()
        self.view.addSubview(self.moreOptionsView)
        
        self.navigationTitleLabel.backgroundColor = UIColor.clearColor()
        self.navigationTitleLabel.font = UIFont.robotoLight(size: UIFont.Size.h2)
        self.navigationTitleLabel.textAlignment = NSTextAlignment.Center
        self.navigationTitleLabel.textColor = UIColor.whiteColor()
        self.navigationTitleLabel.text = self.title
        self.navigationTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationTitleLabel
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = UIColor.ProtonMail.Blue_475F77
        self.refreshControl.tintColor = UIColor.whiteColor()
        self.refreshControl.addTarget(self, action: "getLatestMessages", forControlEvents: UIControlEvents.ValueChanged)
        
        self.getLatestMessages()
        self.tableView.addSubview(self.refreshControl)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
        
        self.menuBarButtonItem = self.navigationItem.leftBarButtonItem
    }
    
    private func addConstraints() {
        self.moreOptionsView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
            make.height.equalTo()(self.kMoreOptionsViewHeight)
            make.bottom.equalTo()(self.view.mas_top)
            return ()
        }
    }
    
    // MARK: - Button Targets
    
    internal func composeButtonTapped() {
        
    }
    
    internal func searchButtonTapped() {
        self.performSegueWithIdentifier(kSegueToSearchController, sender: self)
    }
    
    internal func removeButtonTapped() {
        
    }
    
    internal func favoriteButtonTapped() {
        
    }
    
    internal func moreButtonTapped() {
        self.view.bringSubviewToFront(self.moreOptionsView)
        let topLayoutGuide: UIView = self.topLayoutGuide as AnyObject! as UIView
        if (self.isViewingMoreOptions) {
            self.moreOptionsView.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.view)
                make.right.equalTo()(self.view)
                make.height.equalTo()(self.kMoreOptionsViewHeight)
                make.bottom.equalTo()(topLayoutGuide.mas_top)
            })
        } else {
            self.moreOptionsView.mas_updateConstraints({ (make) -> Void in
                make.removeExisting = true
                make.left.equalTo()(self.view)
                make.right.equalTo()(self.view)
                make.height.equalTo()(self.kMoreOptionsViewHeight)
                
                make.top.equalTo()(topLayoutGuide.mas_bottom)
            })
        }
        
        self.isViewingMoreOptions = !self.isViewingMoreOptions
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    internal func cancelButtonTapped() {
        self.selectedMessages.removeAllObjects()
        self.hideCheckOptions()
        
        // dismiss more options view
        
        if (isViewingMoreOptions) {
            self.moreButtonTapped()
        }
        
        self.updateNavigationController(false)
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
        }
    }
    
    internal func handleLongPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        showCheckOptions(longPressGestureRecognizer)
        updateNavigationController(isEditing)
    }
    
    
    // MARK: - Prepare for segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == kSegueToThreadController) {
            self.cancelButtonTapped()
            let threadViewController: ThreadViewController = segue.destinationViewController as ThreadViewController
            let indexPathForSelectedRow: NSIndexPath? = self.tableView.indexPathForSelectedRow()?
            
            if let selectedRow = indexPathForSelectedRow {
                threadViewController.emailThread = messages[selectedRow.row]
            } else {
                println("No selected row.")
            }
        }
    }
    
    
    // MARK: - Private methods
    
    
    private func getLatestMessages() {
        self.messages = retrieveMessagesFromServer()
        self.refreshControl.endRefreshing()
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        })
    }
    
    private func setupLeftButtons(editingMode: Bool) {
        var leftButtons: [UIBarButtonItem]
        
        if (!editingMode) {
            leftButtons = [self.menuBarButtonItem]
        } else {
            if (self.cancelBarButtonItem == nil) {
                self.cancelBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelButtonTapped")
            }
            
            leftButtons = [self.cancelBarButtonItem]
        }
        
        self.navigationItem.setLeftBarButtonItems(leftButtons, animated: true)
    }
    
    private func setupNavigationTitle(editingMode: Bool) {
        
        // title animation
        
        let animation = CATransition()
        animation.duration = 0.25
        animation.type = kCATransitionFade
        
        self.navigationController?.navigationBar.layer.addAnimation(animation, forKey: "fadeText")
        
        if (editingMode) {
            self.navigationTitleLabel.text = ""
        } else {
            self.navigationTitleLabel.text = self.title
        }
    }
    
    private func setupRightButtons(editingMode: Bool) {
        var rightButtons: [UIBarButtonItem]
        
        if (!editingMode) {
            if (self.composeBarButtonItem == nil) {
                self.composeBarButtonItem = UIBarButtonItem(image: UIImage(named: "compose"), style: UIBarButtonItemStyle.Plain, target: self, action: "composeButtonTapped")
            }
            
            if (self.searchBarButtonItem == nil) {
                self.searchBarButtonItem = UIBarButtonItem(image: UIImage(named: "search"), style: UIBarButtonItemStyle.Plain, target: self, action: "searchButtonTapped")
            }
            
            rightButtons = [self.composeBarButtonItem, self.searchBarButtonItem]
            
        } else {
            
            if (self.removeBarButtonItem == nil) {
                self.removeBarButtonItem = UIBarButtonItem(image: UIImage(named: "trash_selected"), style: UIBarButtonItemStyle.Plain, target: self, action: "removeButtonTapped")
            }
            
            if (self.favoriteBarButtonItem == nil) {
                self.favoriteBarButtonItem = UIBarButtonItem(image: UIImage(named: "favorite"), style: UIBarButtonItemStyle.Plain, target: self, action: "favoriteButtonTapped")
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "arrow_down"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreButtonTapped")
            }
            
            rightButtons = [self.moreBarButtonItem, self.favoriteBarButtonItem, self.removeBarButtonItem]
        }
        
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    
    private func hideCheckOptions() {
        self.isEditing = false
        
        let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows() as? [NSIndexPath]
        
        if let indexPathsForVisibleRows = indexPathsForVisibleRows {
            for indexPath in indexPathsForVisibleRows {
                let inboxTableViewCell: InboxTableViewCell = self.tableView.cellForRowAtIndexPath(indexPath) as InboxTableViewCell
                inboxTableViewCell.setCellIsChecked(false)
                inboxTableViewCell.hideCheckboxOnLeftSide()
                
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    inboxTableViewCell.layoutIfNeeded()
                })
            }
        }
    }
    
    private func showCheckOptions(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let point: CGPoint = longPressGestureRecognizer.locationInView(self.tableView)
        let indexPath: NSIndexPath? = self.tableView.indexPathForRowAtPoint(point)
        
        if let indexPath = indexPath {
            if (longPressGestureRecognizer.state == UIGestureRecognizerState.Began) {
                self.isEditing = true
                
                let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows() as? [NSIndexPath]
                
                if let indexPathsForVisibleRows = indexPathsForVisibleRows {
                    for visibleIndexPath in indexPathsForVisibleRows {
                        
                        let inboxTableViewCell: InboxTableViewCell = self.tableView.cellForRowAtIndexPath(visibleIndexPath) as InboxTableViewCell
                        inboxTableViewCell.showCheckboxOnLeftSide()
                        
                        // set selected row to checked
                        
                        if (indexPath.row == visibleIndexPath.row) {
                            selectedMessages.addObject(messages[indexPath.row].id)
                            inboxTableViewCell.setCellIsChecked(true)
                        }
                        
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
    
    private func updateNavigationController(editingMode: Bool) {
        self.setupLeftButtons(editingMode)
        self.setupNavigationTitle(editingMode)
        self.setupRightButtons(editingMode)
    }
    
    // MARK: - Functions that should be overriden
    
    internal func retrieveMessagesFromServer() -> [EmailThread] {
        return [EmailThread]()
    }
}


// MARK: - UITableViewDataSource

extension MailBoxViewController: UITableViewDataSource {
    
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

extension MailBoxViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kInboxCellHeight
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let messageTrashed: UITableViewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Message Trashed") { (rowAction, indexPath) -> Void in
            
        }
        
        messageTrashed.backgroundColor = UIColor.ProtonMail.Red_D74B4B
        
        let undo: UITableViewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Undo") { (rowAction, indexPath) -> Void in
            self.isUndoButtonTapped = true
        }
        
        undo.backgroundColor = UIColor.ProtonMail.Gray_999DA1
        
        return [undo, messageTrashed]
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // just to allow tableview swipe-left
    }
    
    func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            if (!self.isUndoButtonTapped) {
                self.isUndoButtonTapped = false
                self.messages.removeAtIndex(indexPath.row)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            
            self.tableView.editing = false
        }
    }
}