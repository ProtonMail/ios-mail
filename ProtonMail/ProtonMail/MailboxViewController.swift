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

class UndoMessage {
    var messageID : String!
    var oldLocation : MessageLocation!
    
    required init(msgID:String!, oldLocation : MessageLocation!) {
        self.messageID = msgID
        self.oldLocation = oldLocation
        
    }
    
}

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
    private let kSegueToLabelsController = "toApplyLabelsSegue"
    
    @IBOutlet weak var undoBottomDistance: NSLayoutConstraint!
    // MARK: - Private attributes
    
    internal var viewModel: MailboxViewModel!
    private var fetchedResultsController: NSFetchedResultsController?
    
    // this is for when user click the notification email
    internal var messageID: String?
    private var selectedMessages: NSMutableSet = NSMutableSet()
    private var isEditing: Bool = false
    private var timer : NSTimer!
    
    private var timerAutoDismiss : NSTimer?
    
    private var fetching : Bool = false
    private var selectedDraft : Message!
    private var indexPathForSelectedRow : NSIndexPath!
    
    private var undoMessage : UndoMessage?
    
    private var isShowUndo : Bool = false
    
    
    // MAKR : - Private views
    internal var refreshControl: UIRefreshControl!
    private var navigationTitleLabel = UILabel()
    @IBOutlet weak var undoLabel: UILabel!
    
    @IBOutlet weak var noResultLabel: UILabel!
    
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
    
    @IBAction func undoAction(sender: UIButton) {
        self.undoTheMessage();
        self.hideUndoView();
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
                PMLog.D("No selected row.")
            }
        } else if segue.identifier == kSegueToComposeShow {
            self.cancelButtonTapped()
            
            let composeViewController = segue.destinationViewController.viewControllers![0] as! ComposeEmailViewController
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = fetchedResultsController?.objectAtIndexPath(indexPathForSelectedRow) as? Message {
                    composeViewController.viewModel = ComposeViewModelImpl(msg: selectedDraft ?? message, action : ComposeMessageAction.OpenDraft)
                }
                else
                {
                    PMLog.D("No selected row.")
                }
            } else {
                PMLog.D("No selected row.")
            }
        } else if segue.identifier == kSegueToLabelsController {
            let popup = segue.destinationViewController as! LablesViewController
            popup.viewModel = LabelViewModelImpl(msg: self.getSelectedMessages())
            self.setPresentationStyleForSelfController(self, presentingController: popup)
            self.cancelButtonTapped()
        } else if segue.identifier == kSegueToCompose {
            let composeViewController = segue.destinationViewController.viewControllers![0] as! ComposeEmailViewController
            composeViewController.viewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.NewDraft)
        }
    }
    
    func setPresentationStyleForSelfController(selfController : UIViewController,  presentingController: UIViewController)
    {
        presentingController.providesPresentationContextTransitionStyle = true;
        presentingController.definesPresentationContext = true;
        presentingController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
    }
    
    // MARK: - Button Targets
    
    internal func composeButtonTapped() {
        self.performSegueWithIdentifier(kSegueToCompose, sender: self)
    }
    
    internal func searchButtonTapped() {
        self.performSegueWithIdentifier(kSegueToSearchController, sender: self)
    }
    
    internal func labelButtonTapped() {
        self.performSegueWithIdentifier(kSegueToLabelsController, sender: self)
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
    
    private func configureCell(mailboxCell: MailboxMessageCell, atIndexPath indexPath: NSIndexPath) {
        if self.fetchedResultsController?.numberOfSections() > indexPath.section {
            if self.fetchedResultsController?.numberOfRowsInSection(indexPath.section) > indexPath.row {
                if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
                    mailboxCell.configureCell(message, showLocation: viewModel.showLocation())
                    mailboxCell.setCellIsChecked(selectedMessages.containsObject(message.messageID))
                    if (self.isEditing) {
                        mailboxCell.showCheckboxOnLeftSide()
                    }
                    else {
                        mailboxCell.hideCheckboxOnLeftSide()
                    }
                    
                    mailboxCell.defaultColor = UIColor.lightGrayColor()
                    let crossView = UILabel();
                    crossView.text = self.viewModel.getSwipeEditTitle()
                    crossView.sizeToFit()
                    crossView.textColor = UIColor.whiteColor()
                    
                    let archiveVIew = UILabel();
                    archiveVIew.text = "Archive";
                    archiveVIew.sizeToFit()
                    archiveVIew.textColor = UIColor.whiteColor()
                    
                    if !self.viewModel.isArchive() {
                        mailboxCell.setSwipeGestureWithView(archiveVIew, color: UIColor.greenColor(), mode: MCSwipeTableViewCellMode.Exit, state: MCSwipeTableViewCellState.State1 ) { (cell, state, mode) -> Void in
                            if let indexp = self.tableView.indexPathForCell(cell) {
                                self.archiveMessageForIndexPath(indexp)
                                if self.viewModel.showLocation() {
                                    mailboxCell.swipeToOriginWithCompletion(nil)
                                }
                            } else {
                                self.tableView.reloadData()
                            }
                        }
                    }
                    mailboxCell.setSwipeGestureWithView(crossView, color: UIColor.redColor(), mode: MCSwipeTableViewCellMode.Exit, state: MCSwipeTableViewCellState.State3  ) { (cell, state, mode) -> Void in
                        if let indexp = self.tableView.indexPathForCell(cell) {
                            self.deleteMessageForIndexPath(indexp)
                            if self.viewModel.showLocation() {
                                mailboxCell.swipeToOriginWithCompletion(nil)
                            }
                        } else {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    private func archiveMessageForIndexPath(indexPath: NSIndexPath) {
        if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
            viewModel.archiveMessage(message)
            showUndoView("Archived")
        }
    }
    private func deleteMessageForIndexPath(indexPath: NSIndexPath) {
        if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
            viewModel.deleteMessage(message)
            showUndoView("Deleted")
        }
    }
    
    private func undoTheMessage() { //need move into viewModel
        if undoMessage != nil {
            if let context = fetchedResultsController?.managedObjectContext {
                if let message = Message.messageForMessageID(undoMessage!.messageID, inManagedObjectContext: context) {
                    message.location = undoMessage!.oldLocation
                    message.needsUpdate = true
                    if let error = context.saveUpstreamIfNeeded() {
                        NSLog("\(__FUNCTION__) error: \(error)")
                    }
                }
            }
            undoMessage = nil
        }
    }
    
    private func showUndoView(title : String!) {
        undoLabel.text = "Message \(title)"
        self.undoBottomDistance.constant = 0
        self.updateViewConstraints()
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.timerAutoDismiss = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "timerTriggered", userInfo: nil, repeats: false)
    }
    
    private func hideUndoView() {
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil

        self.undoBottomDistance.constant = -44
        self.updateViewConstraints()
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func timerTriggered() {
        self.hideUndoView()
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
                self.fetchingMessage = false
                
                if self.fetchingStopped! == true {
                    return;
                }
                
                if let error = error {
                    NSLog("error: \(error)")
                }
                
                if error == nil {
                    //self.checkEmptyMailbox()
                }
                
                delay(1.0, {
                    self.refreshControl.endRefreshing()
                    
                    if self.fetchingStopped! == true {
                        return;
                    }
                    
                    self.showNoResultLabel();
                    
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
    
    private func showNoResultLabel() {
        let count = (self.fetchedResultsController?.numberOfSections() > 0) ? (self.fetchedResultsController?.numberOfRowsInSection(0) ?? 0) : 0
        if (count > 0) {
            self.noResultLabel.hidden = true;
        } else {
            self.noResultLabel.hidden = false;
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
                sharedMessageDataService.ForcefetchDetailForMessage(message) {_, _, msg, error in
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
    
    private func getSelectedMessages() -> [Message] {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, selectedMessages)
            
            var error: NSError?
            if let messages = context.executeFetchRequest(fetchRequest, error: &error) as? [Message] {
                return messages;
            }
            
            if let error = error {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
            
        }
        
        return [Message]();
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
                rightButtons = [self.moreBarButtonItem, self.removeBarButtonItem, self.labelBarButtonItem, self.unreadBarButtonItem]
            }
        }
        
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    
    private func hideCheckOptions() {
        self.isEditing = false
        
        let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows() as? [NSIndexPath]
        
        if let indexPathsForVisibleRows = indexPathsForVisibleRows {
            for indexPath in indexPathsForVisibleRows {
                let messageCell: MailboxMessageCell = self.tableView.cellForRowAtIndexPath(indexPath) as! MailboxMessageCell
                messageCell.setCellIsChecked(false)
                messageCell.hideCheckboxOnLeftSide()
                
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    messageCell.layoutIfNeeded()
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
                        
                        let messageCell: MailboxMessageCell = self.tableView.cellForRowAtIndexPath(visibleIndexPath) as! MailboxMessageCell
                        messageCell.showCheckboxOnLeftSide()
                        
                        // set selected row to checked
                        if (indexPath.row == visibleIndexPath.row) {
                            if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
                                selectedMessages.addObject(message.messageID)
                            }
                            messageCell.setCellIsChecked(true)
                        }
                        
                        UIView.animateWithDuration(0.25, animations: { () -> Void in
                            messageCell.layoutIfNeeded()
                        })
                    }
                }
                PMLog.D("Long press on table view at row \(indexPath.row)")
            }
        } else {
            PMLog.D("Long press on table view, but not on a row.")
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


// MARK: - UITableViewDataSource

extension MailboxViewController: UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.numberOfSections() ?? 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var mailboxCell = tableView.dequeueReusableCellWithIdentifier(MailboxMessageCell.Constant.identifier, forIndexPath: indexPath) as! MailboxMessageCell
        
        configureCell(mailboxCell, atIndexPath: indexPath)
        
        return mailboxCell
    }
    
    //    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    //        if (editingStyle == .Delete) {
    //            deleteMessageForIndexPath(indexPath)
    //        }
    //    }
    //
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
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? MailboxMessageCell {
                    configureCell(cell, atIndexPath: indexPath)
                }
            }
        default:
            return
        }
        self.showNoResultLabel();
    }
}


// MARK: - UITableViewDelegate

extension MailboxViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kMailboxCellHeight
    }
    
    //    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
    //
    //        let title = viewModel.getSwipeEditTitle()
    //        let trashed: UITableViewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title) { (rowAction, indexPath) -> Void in
    //            self.deleteMessageForIndexPath(indexPath)
    //        }
    //
    //        trashed.backgroundColor = UIColor.ProtonMail.Red_D74B4B
    //
    //        return [trashed]
    //    }
    
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
                if let mailboxCell: MailboxMessageCell = tableView.cellForRowAtIndexPath(indexPath) as? MailboxMessageCell {
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
