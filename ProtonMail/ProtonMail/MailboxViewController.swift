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

class MailboxViewController: ProtonMailViewController {
    
    // MARK: - View Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Private constants
    
    private let kMailboxCellHeight: CGFloat = 62.0
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds
    private let kMoreOptionsViewHeight: CGFloat = 123.0
    
    private let kCellIdentifier = "MailboxCell"
    
    private let kSegueToCompose = "toCompose"
    private let kSegueToComposeShow = "toComposeShow"
    private let kSegueToSearchController = "toSearchViewController"
    private let kSegueToMessageDetailController = "toMessageDetailViewController"
    
    
    // MARK: - Private attributes
    
    internal var viewModel: MailboxViewModel!
    private var fetchedResultsController: NSFetchedResultsController?
    
    // this is for when user click the notification email
    internal var messageID: String?
    private var selectedMessages: NSMutableSet = NSMutableSet()
    private var isEditing: Bool = false
    private var timer : NSTimer!
    
    private var fetching : Bool = false
    private var selectedDraft : Message!
    private var indexPathForSelectedRow : NSIndexPath!
    
    
    // MAKR : - Private views
    internal var refreshControl: UIRefreshControl!
    private var navigationTitleLabel = UILabel()
    
    
    // MARK: - Right bar buttons
    
    private var composeBarButtonItem: UIBarButtonItem!
    private var searchBarButtonItem: UIBarButtonItem!
    private var removeBarButtonItem: UIBarButtonItem!
    private var favoriteBarButtonItem: UIBarButtonItem!
    private var labelBarButtonItem: UIBarButtonItem!
    private var unreadBarButtonItem: UIBarButtonItem!
    private var moreBarButtonItem: UIBarButtonItem!
    
    
    // MARK: - Left bar button
    
    private var cancelBarButtonItem: UIBarButtonItem!
    private var menuBarButtonItem: UIBarButtonItem!
    private var fetchingMessage : Bool! = false
    private var fetchingStopped : Bool! = true
    
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNavigationTitleText(viewModel.getNavigationTitle())
        
        self.tableView!.RegisterCell(MailboxMessageCell.Constant.identifier)
        
        self.setupFetchedResultsController()
        
        self.addSubViews()
        self.addConstraints()
        
        self.updateNavigationController(isEditing)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let selectedItem: NSIndexPath? = self.tableView.indexPathForSelectedRow() as NSIndexPath?
        
        if let selectedItem = selectedItem {
            self.tableView.reloadRowsAtIndexPaths([selectedItem], withRowAnimation: UITableViewRowAnimation.Fade)
            self.tableView.deselectRowAtIndexPath(selectedItem, animated: true)
        }
        self.startAutoFetch()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopAutoFetch()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let usedStorageSpace = sharedUserDataService.usedSpace
        let maxStorageSpace = sharedUserDataService.maxSpace
        StorageLimit().checkSpace(usedSpace: usedStorageSpace, maxSpace: maxStorageSpace)
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
    
    private func addSubViews() {
        self.navigationTitleLabel.backgroundColor = UIColor.clearColor()
        self.navigationTitleLabel.font = UIFont.robotoRegular(size: UIFont.Size.h2)
        self.navigationTitleLabel.textAlignment = NSTextAlignment.Center
        self.navigationTitleLabel.textColor = UIColor.whiteColor()
        self.navigationTitleLabel.text = self.title ?? NSLocalizedString("INBOX")
        self.navigationTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationTitleLabel
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        self.refreshControl.addTarget(self, action: "getLatestMessages", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl.tintColor = UIColor.grayColor()
        self.refreshControl.tintColorDidChange()
        
        self.tableView.addSubview(self.refreshControl)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.noSeparatorsBelowFooter()
        
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
        
        self.menuBarButtonItem = self.navigationItem.leftBarButtonItem
    }
    
    private func addConstraints() {
        
    }
    
    // MARK: - Prepare for segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == kSegueToMessageDetailController) {
            self.cancelButtonTapped()
            
            let messageDetailViewController = segue.destinationViewController as! MessageViewController
            let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()
            
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = fetchedResultsController?.objectAtIndexPath(indexPathForSelectedRow) as? Message {
                    messageDetailViewController.message = message
                }
            } else {
                println("No selected row.")
            }
        } else if segue.identifier == kSegueToComposeShow {
            self.cancelButtonTapped()
            
            let composeViewController = segue.destinationViewController.viewControllers![0] as! ComposeEmailViewController
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = fetchedResultsController?.objectAtIndexPath(indexPathForSelectedRow) as? Message {
                    composeViewController.viewModel = ComposeViewModelImpl(msg: message, action : ComposeMessageAction.OpenDraft)
                }
                else
                {
                    println("No selected row.")
                }
            } else {
                println("No selected row.")
            }
        } else if segue.identifier == kSegueToCompose {
            let composeViewController = segue.destinationViewController.viewControllers![0] as! ComposeEmailViewController
            composeViewController.viewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.NewDraft)
        }
    }
    
    // MARK: - Button Targets
    
    internal func composeButtonTapped() {
        self.performSegueWithIdentifier(kSegueToCompose, sender: self)
    }
    
    internal func searchButtonTapped() {
        self.performSegueWithIdentifier(kSegueToSearchController, sender: self)
    }
    
    internal func removeButtonTapped() {
        
        if viewModel.isDelete() {
            moveMessagesToLocation(.deleted)
        } else {
            moveMessagesToLocation(.trash)
        }
        cancelButtonTapped();
    }
    
    internal func favoriteButtonTapped() {
        selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.isStarred)
        cancelButtonTapped();
    }
    
    internal func unreadButtonTapped() {
        selectedMessagesSetValue(setValue: false, forKey: Message.Attributes.isRead)
        cancelButtonTapped();
    }
    
    internal func moreButtonTapped() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: "Mark Read", style: .Default, handler: { (action) -> Void in
            self.selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.isRead)
            self.cancelButtonTapped();
            self.navigationController?.popViewControllerAnimated(true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Add Star", style: .Default, handler: { (action) -> Void in
            self.selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.isStarred)
            self.cancelButtonTapped();
            self.navigationController?.popViewControllerAnimated(true)
        }))
        
        let locations: [MessageLocation : UIAlertActionStyle] = [.inbox : .Default, .spam : .Default, .archive : .Destructive]
        for (location, style) in locations {
            if !viewModel.isCurrentLocation(location) {
                alertController.addAction(UIAlertAction(title: location.actionTitle, style: style, handler: { (action) -> Void in
                    self.moveMessagesToLocation(location)
                    self.cancelButtonTapped();
                    self.navigationController?.popViewControllerAnimated(true)
                }))
            }
        }
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    internal func cancelButtonTapped() {
        self.selectedMessages.removeAllObjects()
        self.hideCheckOptions()
        
        self.updateNavigationController(false)
    }
    
    internal func handleLongPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        self.showCheckOptions(longPressGestureRecognizer)
        updateNavigationController(isEditing)
    }
    
    
    // MARK: - Private methods
    private func startAutoFetch()
    {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "refreshPage", userInfo: nil, repeats: true)
        fetchingStopped = false
        self.timer.fire()
        
    }
    
    private func stopAutoFetch()
    {
        fetchingStopped = true
        self.timer.invalidate()
        self.timer = nil
    }
    
    func refreshPage()
    {
        if !fetchingStopped {
            getLatestMessages()
        }
    }
    
    private func configureCell(mailboxCell: MailboxTableViewCell, atIndexPath indexPath: NSIndexPath) {
        if self.fetchedResultsController?.numberOfSections() >= indexPath.section {
            if self.fetchedResultsController?.numberOfRowsInSection(indexPath.section) >= indexPath.row {
                if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
                    mailboxCell.configureCell(message)
                    mailboxCell.setCellIsChecked(selectedMessages.containsObject(message.messageID))
                    if (self.isEditing) {
                        mailboxCell.showCheckboxOnLeftSide()
                    }
                    else {
                        mailboxCell.hideCheckboxOnLeftSide()
                    }
                }
            }
        }
    }
    
    private func deleteMessageForIndexPath(indexPath: NSIndexPath) {
        if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
            viewModel.deleteMessage(message)
        }
    }
    
    private func setupFetchedResultsController() {
        self.fetchedResultsController = self.viewModel.getFetchedResultsController()
        self.fetchedResultsController?.delegate = self
    }
    
    func resetFetchedResultsController() {
        self.fetchedResultsController?.delegate = nil
    }
    
    private func fetchMessagesIfNeededForIndexPath(indexPath: NSIndexPath) {
        if let fetchedResultsController = fetchedResultsController {
            if let last = fetchedResultsController.fetchedObjects?.last as? Message {
                if let current = fetchedResultsController.objectAtIndexPath(indexPath) as? Message {
                    let updateTime = viewModel.lastUpdateTime()
                    if let currentTime = current.time {
                        let isOlderMessage = updateTime.end.compare(currentTime) != NSComparisonResult.OrderedAscending
                        let isLastMessage = last == current
                        if  (isOlderMessage || isLastMessage) && !fetching {
                            let sectionCount = fetchedResultsController.numberOfRowsInSection(0) ?? 0
                            let recordedCount = Int(updateTime.total)
                            if updateTime.isNew || recordedCount > sectionCount { //here need add a counter to check if tried too many times make one real call in case count not right
                                self.fetching = true
                                tableView.showLoadingFooter()
                                let updateTime = viewModel.lastUpdateTime()
                                
                                let unixTimt:Int = (updateTime.end == NSDate.distantPast() as! NSDate) ? 0 : Int(updateTime.end.timeIntervalSince1970)
                                viewModel.fetchMessages(last.messageID ?? "0", Time: unixTimt, foucsClean: false, completion: { (task, response, error) -> Void in
                                    self.tableView.hideLoadingFooter()
                                    self.fetching = false
                                    if error != nil {
                                        NSLog("\(__FUNCTION__) search error: \(error)")
                                    } else {
                                        
                                    }
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func checkEmptyMailbox () {
        
        if self.fetchingStopped! == true {
            return;
        }
        
        if let fetchedResultsController = fetchedResultsController {
            let secouts = fetchedResultsController.numberOfSections() ?? 0
            if secouts > 0 {
                let sectionCount = fetchedResultsController.numberOfRowsInSection(0) ?? 0
                if sectionCount == 0 {
                    let updateTime = viewModel.lastUpdateTime()
                    let recordedCount = Int(updateTime.total)
                    if updateTime.isNew || recordedCount > sectionCount {
                        self.fetching = true
                        viewModel.fetchMessages("", Time: 0, foucsClean: false, completion:
                            { (task, messages, error) -> Void in
                                self.fetching = false
                                if error != nil {
                                    NSLog("\(__FUNCTION__) search error: \(error)")
                                } else {
                                    
                                }
                        })
                    }
                }
                
            }
        }
    }
    
    internal func getLatestMessages() {
        
        if !fetchingMessage {
            fetchingMessage = true
            
            self.refreshControl.beginRefreshing()
            let updateTime = viewModel.lastUpdateTime()
            var complete : APIService.CompletionBlock = { (task, messages, error) -> Void in
                
                if self.fetchingStopped! == true {
                    return;
                }
                
                self.fetchingMessage = false
                if let error = error {
                    NSLog("error: \(error)")
                }
                
                if error == nil {
                    self.checkEmptyMailbox()
                }
                
                delay(1.0, {
                    self.refreshControl.endRefreshing()
                    
                    if self.fetchingStopped! == true {
                        return;
                    }
                    
                    self.tableView.reloadData()
                })
            }
            
            if (updateTime.isNew) {
                if lastUpdatedStore.lastEventID == "0" {
                    viewModel.fetchMessagesForLocationWithEventReset("", Time: 0, completion: complete)
                }
                else {
                    viewModel.fetchMessages("", Time: 0, foucsClean: false, completion: complete)
                }
            } else {
                //fetch
                viewModel.fetchNewMessages(Int(updateTime.start.timeIntervalSince1970),  completion: complete)
                self.checkEmptyMailbox()
            }
        }
    }
    
    
    private func moveMessagesToLocation(location: MessageLocation) {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, selectedMessages)
            
            var error: NSError?
            if let messages = context.executeFetchRequest(fetchRequest, error: &error) as? [Message] {
                for message in messages {
                    message.location = location
                    message.needsUpdate = true
                }
                error = context.saveUpstreamIfNeeded()
            }
            
            if let error = error {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
    }
    
    private func performSegueForMessage(message: Message) {
        if viewModel.isDrafts() {
            if !message.messageID.isEmpty {
                sharedMessageDataService.fetchMessageDetailForMessage(message) {_, _, msg, error in
                    if error != nil {
                        NSLog("\(__FUNCTION__) error: \(error)")
                    }
                    else
                    {
                        self.selectedDraft = msg
                        self.performSegueWithIdentifier(self.kSegueToComposeShow, sender: self)
                    }
                }
            } else {
                self.performSegueWithIdentifier(self.kSegueToComposeShow, sender: self)
            }
        } else {
            performSegueWithIdentifier(kSegueToMessageDetailController, sender: self)
        }
    }
    
    private func selectMessageIDIfNeeded() {
        if messageID != nil {
            if let messages = fetchedResultsController?.fetchedObjects as? [Message] {
                if let message = messages.filter({ $0.messageID == self.messageID }).first {
                    let indexPath = fetchedResultsController?.indexPathForObject(message)
                    tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Top)
                    performSegueForMessage(message)
                    
                    messageID = nil
                }
            }
        }
    }
    
    private func selectedMessagesSetValue(setValue value: AnyObject?, forKey key: String) {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, selectedMessages)
            
            var error: NSError?
            if let messages = context.executeFetchRequest(fetchRequest, error: &error) as? [Message] {
                NSArray(array: messages).setValue(value, forKey: key)
                NSArray(array: messages).setValue(true, forKey: "needsUpdate")
                error = context.saveUpstreamIfNeeded()
            }
            
            if let error = error {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
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
        if (editingMode) {
            setNavigationTitleText("")
        } else {
            setNavigationTitleText(self.title ?? "INBOX")
        }
    }
    
    private func setupRightButtons(editingMode: Bool) {
        var rightButtons: [UIBarButtonItem]
        
        if (!editingMode) {
            if (self.composeBarButtonItem == nil) {
                self.composeBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_compose"), style: UIBarButtonItemStyle.Plain, target: self, action: "composeButtonTapped")
            }
            
            if (self.searchBarButtonItem == nil) {
                self.searchBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_search"), style: UIBarButtonItemStyle.Plain, target: self, action: "searchButtonTapped")
            }
            
            rightButtons = [self.composeBarButtonItem, self.searchBarButtonItem]
            
        } else {
            if (self.unreadBarButtonItem == nil) {
                self.unreadBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_unread"), style: UIBarButtonItemStyle.Plain, target: self, action: "unreadButtonTapped")
            }
            
            if (self.labelBarButtonItem == nil) {
                self.labelBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_label"), style: UIBarButtonItemStyle.Plain, target: self, action: "labelButtonTapped")
            }
            
            if (self.removeBarButtonItem == nil) {
                self.removeBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_trash"), style: UIBarButtonItemStyle.Plain, target: self, action: "removeButtonTapped")
            }
            
            if (self.favoriteBarButtonItem == nil) {
                self.favoriteBarButtonItem = UIBarButtonItem(image: UIImage(named: "favorite"), style: UIBarButtonItemStyle.Plain, target: self, action: "favoriteButtonTapped")
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_more"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreButtonTapped")
            }
            
            if (viewModel.isDrafts()) {
                rightButtons = [self.removeBarButtonItem]
            } else {
                rightButtons = [self.moreBarButtonItem, self.removeBarButtonItem, self.unreadBarButtonItem] //self.labelBarButtonItem,
            }
        }
        
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    
    private func hideCheckOptions() {
        self.isEditing = false
        
        let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows() as? [NSIndexPath]
        
        if let indexPathsForVisibleRows = indexPathsForVisibleRows {
            for indexPath in indexPathsForVisibleRows {
                let mailboxTableViewCell: MailboxTableViewCell = self.tableView.cellForRowAtIndexPath(indexPath) as! MailboxTableViewCell
                mailboxTableViewCell.setCellIsChecked(false)
                mailboxTableViewCell.hideCheckboxOnLeftSide()
                
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    mailboxTableViewCell.layoutIfNeeded()
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
                        
                        let mailboxTableViewCell: MailboxTableViewCell = self.tableView.cellForRowAtIndexPath(visibleIndexPath) as! MailboxTableViewCell
                        mailboxTableViewCell.showCheckboxOnLeftSide()
                        
                        // set selected row to checked
                        
                        if (indexPath.row == visibleIndexPath.row) {
                            if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
                                selectedMessages.addObject(message.messageID)
                            }
                            mailboxTableViewCell.setCellIsChecked(true)
                        }
                        
                        UIView.animateWithDuration(0.25, animations: { () -> Void in
                            mailboxTableViewCell.layoutIfNeeded()
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
    
    
    
    // MARK: - Public methods
    
    func setNavigationTitleText(text: String?) {
        let animation = CATransition()
        animation.duration = 0.25
        animation.type = kCATransitionFade
        
        self.navigationController?.navigationBar.layer.addAnimation(animation, forKey: "fadeText")
        
        self.navigationTitleLabel.text = text
        
        if (text != nil && count(text!) > 0) {
            self.title = text
        }
    }
}


// MARK: - MailboxTableViewCellDelegate

extension MailboxViewController: MailboxTableViewCellDelegate {
    func mailboxTableViewCell(cell: MailboxTableViewCell, didChangeStarred isStarred: Bool) {
        if let indexPath = tableView.indexPathForCell(cell) {
            if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
                message.isStarred = isStarred
                message.needsUpdate = true
                if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
            }
        }
    }
    
    func mailBoxTableViewCell(cell: MailboxTableViewCell, didChangeChecked: Bool) {
        var indexPath: NSIndexPath? = tableView.indexPathForCell(cell) as NSIndexPath?
        if let indexPath = indexPath {
            if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
                if (selectedMessages.containsObject(message.messageID)) {
                    selectedMessages.removeObject(message.messageID)
                } else {
                    selectedMessages.addObject(message.messageID)
                }
            }
        }
    }
}


// MARK: - UITableViewDataSource

extension MailboxViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.numberOfSections() ?? 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var mailboxCell = tableView.dequeueReusableCellWithIdentifier(MailboxMessageCell.Constant.identifier, forIndexPath: indexPath) as! MailboxMessageCell
       // mailboxCell.delegate = self
        
        //configureCell(mailboxCell, atIndexPath: indexPath)
        
        return mailboxCell
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            deleteMessageForIndexPath(indexPath)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fetchedResultsController?.numberOfRowsInSection(section) ?? 0
        return count
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


// MARK: - NSFetchedResultsControllerDelegate

extension MailboxViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
        
        selectMessageIDIfNeeded()
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
                    configureCell(cell, atIndexPath: indexPath)
                }
            }
        default:
            return
        }
    }
}


// MARK: - UITableViewDelegate

extension MailboxViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kMailboxCellHeight
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        let title = viewModel.getSwipeEditTitle()
        let trashed: UITableViewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title) { (rowAction, indexPath) -> Void in
            self.deleteMessageForIndexPath(indexPath)
        }
        
        trashed.backgroundColor = UIColor.ProtonMail.Red_D74B4B
        
        return [trashed]
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // verify whether the user is checking messages or not
        
        if (self.isEditing) {
            if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
                let messageAlreadySelected: Bool = selectedMessages.containsObject(message.messageID)
                
                if (messageAlreadySelected) {
                    selectedMessages.removeObject(message.messageID)
                } else {
                    selectedMessages.addObject(message.messageID)
                }
                
                // update checkbox state
                if let mailboxCell: MailboxTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MailboxTableViewCell {
                    mailboxCell.setCellIsChecked(!messageAlreadySelected)
                }
            }
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        } else {
            if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
                self.indexPathForSelectedRow = indexPath
                performSegueForMessage(message)
            }
        }
    }
}
