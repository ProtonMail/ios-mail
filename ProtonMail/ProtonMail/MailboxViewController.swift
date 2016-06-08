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
    private let kMailboxRateReviewCellHeight: CGFloat = 125.0
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds
    private let kMoreOptionsViewHeight: CGFloat = 123.0
    
    private let kCellIdentifier = "MailboxCell"
    
    private let kSegueToCompose = "toCompose"
    private let kSegueToComposeShow = "toComposeShow"
    private let kSegueToSearchController = "toSearchViewController"
    private let kSegueToMessageDetailController = "toMessageDetailViewController"
    private let kSegueToLabelsController = "toApplyLabelsSegue"
    private let kSegueToMessageDetailFromNotification = "toMessageDetailViewControllerFromNotification"
    private let kSegueToTour = "to_onboarding_segue"
    private let kSegueToFeedback = "to_feedback_segue"
    private let kSegueToFeedbackView = "to_feedback_view_segue"
    
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
    //private var notificationMessageID : String? = nil
    
    private var ratingMessage : Message?
    
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
    private var needToShowNewMessage : Bool = false
    private var newMessageCount = 0
    
    // MARK: swipactions
    private var leftSwipeAction : MessageSwipeAction = .archive
    private var rightSwipeAction : MessageSwipeAction = .trash
    
    
    // MARK: TopMessage
    @IBOutlet weak var topMessageView: TopMessageView!
    @IBOutlet weak var topMsgTopConstraint: NSLayoutConstraint!
    
    private let kDefaultSpaceHide : CGFloat = -38.0
    private let kDefaultSpaceShow : CGFloat = 4.0
    
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setNavigationTitleText(viewModel.getNavigationTitle())
        
        self.tableView!.RegisterCell(MailboxMessageCell.Constant.identifier)
        self.tableView!.RegisterCell(MailboxRateReviewCell.Constant.identifier)
        
        self.setupFetchedResultsController()
        
        self.addSubViews()
        self.addConstraints()
        
        self.updateNavigationController(isEditing)
        
        if !userCachedStatus.isTourOk() {
            userCachedStatus.resetTourValue()
            self.performSegueWithIdentifier(self.kSegueToTour, sender: self)
        }
        
        if userCachedStatus.isTouchIDEnabled {
            userCachedStatus.touchIDEmail = sharedUserDataService.username ?? ""
        }
        self.topMessageView.delegate = self
        cleanRateReviewCell()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.hideTopMessage()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MailboxViewController.reachabilityChanged(_:)), name: kReachabilityChangedNotification, object: nil)
        leftSwipeAction = sharedUserDataService.swiftLeft
        rightSwipeAction = sharedUserDataService.swiftRight
        
        self.refreshControl.endRefreshing()
        
        let selectedItem: NSIndexPath? = self.tableView.indexPathForSelectedRow as NSIndexPath?
        if let selectedItem = selectedItem {
            self.tableView.reloadRowsAtIndexPaths([selectedItem], withRowAnimation: UITableViewRowAnimation.Fade)
            self.tableView.deselectRowAtIndexPath(selectedItem, animated: true)
        }
        self.startAutoFetch()
        
        if self.viewModel.getNotificationMessage() != nil {
            performSegueWithIdentifier(kSegueToMessageDetailFromNotification, sender: self)
        }
    }
    
    @IBAction func undoAction(sender: UIButton) {
        self.undoTheMessage();
        self.hideUndoView();
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kReachabilityChangedNotification, object:nil)
        self.stopAutoFetch()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        sharedPushNotificationService.processCachedLaunchOptions()
        
        let usedStorageSpace = sharedUserDataService.usedSpace
        let maxStorageSpace = sharedUserDataService.maxSpace
        StorageLimit().checkSpace(usedSpace: usedStorageSpace, maxSpace: maxStorageSpace)
        
        
        self.updateInterfaceWithReachability(sharedInternetReachability)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.tableView.respondsToSelector(Selector("setSeparatorInset:"))) {
            self.tableView.separatorInset = UIEdgeInsetsZero
        }
        
        if (self.tableView.respondsToSelector(Selector("setLayoutMargins:"))) {
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
        self.refreshControl.addTarget(self, action: #selector(MailboxViewController.getLatestMessages), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl.tintColor = UIColor.grayColor()
        self.refreshControl.tintColorDidChange()
        
        self.tableView.addSubview(self.refreshControl)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.noSeparatorsBelowFooter()
        
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MailboxViewController.handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
        
        self.menuBarButtonItem = self.navigationItem.leftBarButtonItem
    }
    
    private func addConstraints() {
        
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.tableView.reloadData()
    }
    
    // MARK: - Prepare for segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSegueToMessageDetailFromNotification {
            self.cancelButtonTapped()
            let messageDetailViewController = segue.destinationViewController as! MessageViewController
            if let msgID = self.viewModel.getNotificationMessage() {
                if let context = fetchedResultsController?.managedObjectContext {
                    if let message = Message.messageForMessageID(msgID, inManagedObjectContext: context) {
                        messageDetailViewController.message = message
                        self.viewModel.resetNotificationMessage()
                    }
                }
            } else {
                PMLog.D("No selected row.")
            }
        } else if (segue.identifier == kSegueToMessageDetailController) {
            self.cancelButtonTapped()
            let messageDetailViewController = segue.destinationViewController as! MessageViewController
            let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = self.messageAtIndexPath(indexPathForSelectedRow) {
                    messageDetailViewController.message = message
                } else {
                    let alert = NSLocalizedString("Can't find the clicked message please try again!").alertController()
                    alert.addOKAction()
                    presentViewController(alert, animated: true, completion: nil)
                }
            } else {
                PMLog.D("No selected row.")
            }
        } else if segue.identifier == kSegueToComposeShow {
            self.cancelButtonTapped()
            let composeViewController = segue.destinationViewController.childViewControllers[0] as! ComposeEmailViewController
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = self.messageAtIndexPath(indexPathForSelectedRow) {
                    sharedVMService.openDraftViewModel(composeViewController, msg: selectedDraft ?? message)
                } else {
                    let alert = NSLocalizedString("Can't find the clicked message please try again!").alertController()
                    alert.addOKAction()
                    presentViewController(alert, animated: true, completion: nil)
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
            let composeViewController = segue.destinationViewController.childViewControllers[0] as! ComposeEmailViewController
            sharedVMService.newDraftViewModel(composeViewController)
            
        } else if segue.identifier == kSegueToTour {
            let popup = segue.destinationViewController as! OnboardingViewController
            popup.viewModel = LabelViewModelImpl(msg: self.getSelectedMessages())
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        } else if segue.identifier == kSegueToFeedback {
            let popup = segue.destinationViewController as! FeedbackPopViewController
            popup.feedbackDelegate = self
            //popup.viewModel = LabelViewModelImpl(msg: self.getSelectedMessages())
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        } else if segue.identifier == kSegueToFeedbackView {
            
        }
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
    
    func performSegueForMessageFromNotification() {
        performSegueWithIdentifier(kSegueToMessageDetailFromNotification, sender: self)
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
        
        if viewModel.isShowEmptyFolder() {
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Empty Folder"), style: .Destructive, handler: { (action) -> Void in
                self.viewModel.emptyFolder()
                self.showNoResultLabel()
                self.navigationController?.popViewControllerAnimated(true)
            }))
        } else {
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Mark Read"), style: .Default, handler: { (action) -> Void in
                self.selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.isRead)
                self.cancelButtonTapped();
                self.navigationController?.popViewControllerAnimated(true)
            }))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Add Star"), style: .Default, handler: { (action) -> Void in
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
        }
        alertController.popoverPresentationController?.barButtonItem = moreBarButtonItem
        alertController.popoverPresentationController?.sourceRect = self.view.frame
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
    
    //    internal func createRateReviewCell () {
    //        let count = fetchedResultsController?.numberOfRowsInSection(0) ?? 0
    //        if count > 3 {
    //            if let message = fetchedResultsController?.objectAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as? Message {
    //                if let context = message.managedObjectContext {
    //                    let newMessage = Message(context: context)
    //                    newMessage.messageType = 1
    //                    newMessage.title = ""
    
    //    newMessage.messageStatus = 1
    
    //                    newMessage.time = message.time ?? NSDate()
    //                    if let error = newMessage.managedObjectContext?.saveUpstreamIfNeeded() {
    //                        PMLog.D("error: \(error)")
    //                    }
    //                    ratingMessage = newMessage
    //                }
    //            }
    //        }
    //    }
    
    internal func cleanRateReviewCell () {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == 1", Message.Attributes.messageType)
            do {
                if let messages = try context.executeFetchRequest(fetchRequest) as? [Message] {
                    for msg in messages {
                        if msg.managedObjectContext != nil {
                            context.deleteObject(msg)
                        }
                    }
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
                    }
                }
            } catch let ex as NSError {
                PMLog.D("error: \(ex)")
            }
        }
    }
    
    // MARK: - Private methods
    private func startAutoFetch()
    {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(MailboxViewController.refreshPage), userInfo: nil, repeats: true)
        fetchingStopped = false
        self.timer.fire()
    }
    
    private func stopAutoFetch()
    {
        fetchingStopped = true
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    func refreshPage()
    {
        if !fetchingStopped {
            getLatestMessages()
        }
    }
    
    private func messageAtIndexPath(indexPath: NSIndexPath) -> Message? {
        
        if self.fetchedResultsController?.numberOfSections() > indexPath.section {
            if self.fetchedResultsController?.numberOfRowsInSection(indexPath.section) > indexPath.row {
                if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
                    if message.managedObjectContext != nil {
                        return message
                    }
                }
            }
        }
        return nil
    }
    
    private func configureCell(mailboxCell: MailboxMessageCell, atIndexPath indexPath: NSIndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            mailboxCell.configureCell(message, showLocation: viewModel.showLocation())
            mailboxCell.setCellIsChecked(selectedMessages.containsObject(message.messageID))
            if (self.isEditing) {
                mailboxCell.showCheckboxOnLeftSide()
            }
            else {
                mailboxCell.hideCheckboxOnLeftSide()
            }
            
            mailboxCell.defaultColor = UIColor.lightGrayColor()
            let leftCrossView = UILabel();
            leftCrossView.text = self.viewModel.getSwipeTitle(leftSwipeAction)
            leftCrossView.sizeToFit()
            leftCrossView.textColor = UIColor.whiteColor()
            
            let rightCrossView = UILabel();
            rightCrossView.text = self.viewModel.getSwipeTitle(rightSwipeAction)
            rightCrossView.sizeToFit()
            rightCrossView.textColor = UIColor.whiteColor()
            
            if self.viewModel.isSwipeActionValid(self.leftSwipeAction) {
                mailboxCell.setSwipeGestureWithView(leftCrossView, color: leftSwipeAction.actionColor, mode: MCSwipeTableViewCellMode.Exit, state: MCSwipeTableViewCellState.State1 ) { (cell, state, mode) -> Void in
                    if let indexp = self.tableView.indexPathForCell(cell) {
                        if self.viewModel.isSwipeActionValid(self.leftSwipeAction) {
                            if !self.processSwipeActions(self.leftSwipeAction, indexPath: indexp) {
                                mailboxCell.swipeToOriginWithCompletion(nil)
                            } else if self.viewModel.stayAfterAction(self.leftSwipeAction) {
                                mailboxCell.swipeToOriginWithCompletion(nil)
                            }
                        } else {
                            mailboxCell.swipeToOriginWithCompletion(nil)
                        }
                    } else {
                        self.tableView.reloadData()
                    }
                }
            }
            
            if self.viewModel.isSwipeActionValid(self.rightSwipeAction) {
                mailboxCell.setSwipeGestureWithView(rightCrossView, color: rightSwipeAction.actionColor, mode: MCSwipeTableViewCellMode.Exit, state: MCSwipeTableViewCellState.State3  ) { (cell, state, mode) -> Void in
                    if let indexp = self.tableView.indexPathForCell(cell) {
                        if self.viewModel.isSwipeActionValid(self.rightSwipeAction) {
                            if !self.processSwipeActions(self.rightSwipeAction, indexPath: indexp) {
                                mailboxCell.swipeToOriginWithCompletion(nil)
                            } else if self.viewModel.stayAfterAction(self.rightSwipeAction) {
                                mailboxCell.swipeToOriginWithCompletion(nil)
                            }
                        } else {
                            mailboxCell.swipeToOriginWithCompletion(nil)
                        }
                    } else {
                        self.tableView.reloadData()
                    }
                }
            }
        } else {
            PMLog.D("should not go here!")
        }
    }
    
    
    private func processSwipeActions(action: MessageSwipeAction, indexPath: NSIndexPath) -> Bool {
        switch (action) {
        case .archive:
            self.archiveMessageForIndexPath(indexPath)
            return true
        case .trash:
            self.deleteMessageForIndexPath(indexPath)
            return true
        case .spam:
            self.spamMessageForIndexPath(indexPath)
            return true
        case .star:
            self.starMessageForIndexPath(indexPath)
            return false
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
    
    private func spamMessageForIndexPath(indexPath: NSIndexPath) {
        if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
            viewModel.spamMessage(message)
            showUndoView("Spammed")
        }
    }
    
    private func starMessageForIndexPath(indexPath: NSIndexPath) {
        if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
            viewModel.starMessage(message)
        }
    }
    
    private func undoTheMessage() { //need move into viewModel
        if undoMessage != nil {
            if let context = fetchedResultsController?.managedObjectContext {
                if let message = Message.messageForMessageID(undoMessage!.messageID, inManagedObjectContext: context) {
                    viewModel.updateBadgeNumberMoveOutInbox(message)
                    message.location = undoMessage!.oldLocation
                    message.needsUpdate = true
                    viewModel.updateBadgeNumberMoveInInbox(message)
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
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
        self.timerAutoDismiss = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(MailboxViewController.timerTriggered), userInfo: nil, repeats: false)
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
                if let current = self.messageAtIndexPath(indexPath) {
                    let updateTime = viewModel.lastUpdateTime()
                    if let currentTime = current.time {
                        let isOlderMessage = updateTime.end.compare(currentTime) != NSComparisonResult.OrderedAscending
                        let isLastMessage = (last == current)
                        if  (isOlderMessage || isLastMessage) && !fetching {
                            let sectionCount = fetchedResultsController.numberOfRowsInSection(0) ?? 0
                            let recordedCount = Int(updateTime.total)
                            if updateTime.isNew || recordedCount > sectionCount { //here need add a counter to check if tried too many times make one real call in case count not right
                                self.fetching = true
                                tableView.showLoadingFooter()
                                let updateTime = viewModel.lastUpdateTime()
                                
                                let unixTimt:Int = (updateTime.end == NSDate.distantPast() ) ? 0 : Int(updateTime.end.timeIntervalSince1970)
                                viewModel.fetchMessages(last.messageID ?? "0", Time: unixTimt, foucsClean: false, completion: { (task, response, error) -> Void in
                                    self.tableView.hideLoadingFooter()
                                    self.fetching = false
                                    if error != nil {
                                        PMLog.D("search error: \(error)")
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
                                    PMLog.D("search error: \(error)")
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
            let complete : APIService.CompletionBlock = { (task, res, error) -> Void in
                self.needToShowNewMessage = false
                self.newMessageCount = 0
                self.fetchingMessage = false
                
                if self.fetchingStopped! == true {
                    return;
                }
                
                if let error = error {
                    //No connectivity detected...
                    self.showErrorMessage(error)
                    NSLog("error: \(error)")
                }
                
                if error == nil {
                    self.viewModel.resetNotificationMessage()
                    if !updateTime.isNew {
//                        if let messages = res?["Messages"] as? [AnyObject] {
//                        }
                    }
                }
                
                delay(1.0, closure: {
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
                self.needToShowNewMessage = true
                viewModel.fetchNewMessages(self.viewModel.getNotificationMessage(), Time: Int(updateTime.start.timeIntervalSince1970),  completion: complete)
                self.checkEmptyMailbox()
            }
        }
    }
    
    private func showNoResultLabel() {
        let count = (self.fetchedResultsController?.numberOfSections() > 0) ? (self.fetchedResultsController?.numberOfRowsInSection(0) ?? 0) : 0
        if (count <= 0 && !fetchingMessage ) {
            self.noResultLabel.hidden = false;
        } else {
            self.noResultLabel.hidden = true;
        }
    }
    
    
    private func moveMessagesToLocation(location: MessageLocation) {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, selectedMessages)
            do {
                if let messages = try context.executeFetchRequest(fetchRequest) as? [Message] {
                    for message in messages {
                        message.location = location
                        message.needsUpdate = true
                    }
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
                    }
                }
            } catch let ex as NSError {
                PMLog.D(" error: \(ex)")
            }
        }
    }
    
    private func performSegueForMessage(message: Message) {
        if viewModel.isDrafts() {
            if !message.messageID.isEmpty {
                sharedMessageDataService.ForcefetchDetailForMessage(message) {_, _, msg, error in
                    if error != nil {
                        PMLog.D("error: \(error)")
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
                    if let indexPath = fetchedResultsController?.indexPathForObject(message) {
                        tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Top)
                    }
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
            do {
                if let messages = try context.executeFetchRequest(fetchRequest) as? [Message] {
                    NSArray(array: messages).setValue(value, forKey: key)
                    NSArray(array: messages).setValue(true, forKey: "needsUpdate")
                    let error = context.saveUpstreamIfNeeded()
                    if let error = error {
                        PMLog.D(" error: \(error)")
                    }
                }
            } catch let ex as NSError {
                PMLog.D(" error: \(ex)")
            }
        }
    }
    
    private func getSelectedMessages() -> [Message] {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, selectedMessages)
            do {
                if let messages = try context.executeFetchRequest(fetchRequest) as? [Message] {
                    return messages;
                }
            } catch let ex as NSError {
                PMLog.D(" error: \(ex)")
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
                self.cancelBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(MailboxViewController.cancelButtonTapped))
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
                self.composeBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_compose"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MailboxViewController.composeButtonTapped))
            }
            
            if (self.searchBarButtonItem == nil) {
                self.searchBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_search"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MailboxViewController.searchButtonTapped))
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_more"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MailboxViewController.moreButtonTapped))
            }
            
            if viewModel.isShowEmptyFolder() {
                rightButtons = [self.moreBarButtonItem, self.composeBarButtonItem, self.searchBarButtonItem]
            } else {
                rightButtons = [self.composeBarButtonItem, self.searchBarButtonItem]
            }
        } else {
            if (self.unreadBarButtonItem == nil) {
                self.unreadBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_unread"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MailboxViewController.unreadButtonTapped))
            }
            
            if (self.labelBarButtonItem == nil) {
                self.labelBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_label"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MailboxViewController.labelButtonTapped))
            }
            
            if (self.removeBarButtonItem == nil) {
                self.removeBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_trash"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MailboxViewController.removeButtonTapped))
            }
            
            if (self.favoriteBarButtonItem == nil) {
                self.favoriteBarButtonItem = UIBarButtonItem(image: UIImage(named: "favorite"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MailboxViewController.favoriteButtonTapped))
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_more"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MailboxViewController.moreButtonTapped))
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
        if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
            for indexPath in indexPathsForVisibleRows {
                if let messageCell: MailboxMessageCell = self.tableView.cellForRowAtIndexPath(indexPath) as? MailboxMessageCell {
                    messageCell.setCellIsChecked(false)
                    messageCell.hideCheckboxOnLeftSide()
                    
                    UIView.animateWithDuration(0.25, animations: { () -> Void in
                        messageCell.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    private func showCheckOptions(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let point: CGPoint = longPressGestureRecognizer.locationInView(self.tableView)
        let indexPath: NSIndexPath? = self.tableView.indexPathForRowAtPoint(point)
        
        if let indexPath = indexPath {
            if (longPressGestureRecognizer.state == UIGestureRecognizerState.Began) {
                self.isEditing = true
                if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
                    for visibleIndexPath in indexPathsForVisibleRows {
                        if let messageCell: MailboxMessageCell = self.tableView.cellForRowAtIndexPath(visibleIndexPath) as? MailboxMessageCell {
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
        
        
        if let t = text where t.characters.count > 0 {
            self.title = t
            self.navigationTitleLabel.text = t
        } else {
            self.title = ""
            self.navigationTitleLabel.text = ""
        }
    }
}

extension MailboxViewController : TopMessageViewDelegate {
    
    internal func showErrorMessage(error: NSError?) {
        if error != nil {
            self.topMsgTopConstraint.constant = self.kDefaultSpaceShow
            self.topMessageView.updateMessage(error: error!)
            self.updateViewConstraints()
            
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
    
    internal func showNewMessageCount(count : Int) {
        if self.needToShowNewMessage == true {
            self.needToShowNewMessage = false
            self.self.newMessageCount = 0
            if count > 0 {
                self.topMsgTopConstraint.constant = self.kDefaultSpaceShow
                if count == 1 {
                    self.topMessageView.updateMessage(newMessage: "You have a new email!")
                } else {
                    self.topMessageView.updateMessage(newMessage: "You have \(count) new emails!")
                }
                self.updateViewConstraints()
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    internal func reachabilityChanged(note : NSNotification) {
        if let curReach = note.object as? Reachability {
            self.updateInterfaceWithReachability(curReach)
        }
    }
    
    internal func updateInterfaceWithReachability(reachability : Reachability) {
        let netStatus = reachability.currentReachabilityStatus()
        let connectionRequired = reachability.connectionRequired()
        PMLog.D("connectionRequired : \(connectionRequired)")
        switch (netStatus)
        {
        case NotReachable:
            PMLog.D("Access Not Available")
            self.topMsgTopConstraint.constant = self.kDefaultSpaceShow
            self.topMessageView.updateMessage(noInternet: "The internet connection appears to be offline.")
            self.updateViewConstraints()
        case ReachableViaWWAN:
            PMLog.D("Reachable WWAN")
            self.topMsgTopConstraint.constant = self.kDefaultSpaceHide
            self.updateViewConstraints()
        case ReachableViaWiFi:
            PMLog.D("Reachable WiFi")
            self.topMsgTopConstraint.constant = self.kDefaultSpaceHide
            self.updateViewConstraints()
        default:
            PMLog.D("Reachable default unknow")
        }
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    internal func hideTopMessage() {
        
        self.topMsgTopConstraint.constant = self.kDefaultSpaceHide
        self.updateViewConstraints()
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func close() {
        self.hideTopMessage()
    }
    
    func retry() {
        
    }
}

extension MailboxViewController : FeedbackPopViewControllerDelegate {
    
    func cancelled() {
        // just cancelled
    }
    
    func showHelp() {
        self.performSegueWithIdentifier(kSegueToFeedbackView, sender: self)
    }
    
    func showSupport() {
        self.performSegueWithIdentifier(kSegueToFeedbackView, sender: self)
    }
    
    func showRating() {
        self.performSegueWithIdentifier(kSegueToFeedbackView, sender: self)
    }
    
}

// MARK : review delegate
extension MailboxViewController: MailboxRateReviewCellDelegate {
    func mailboxRateReviewCell(cell: UITableViewCell, yesORno: Bool) {
        cleanRateReviewCell()
        
        // go to next screen
        if yesORno == true {
            self.performSegueWithIdentifier(kSegueToFeedback, sender: self)
        }
    }
}


// MARK: - UITableViewDataSource

extension MailboxViewController: UITableViewDataSource {
    
    func getRatingIndex () -> NSIndexPath?{
        if let msg = ratingMessage {
            if let indexPath = fetchedResultsController?.indexPathForObject(msg) {
                return indexPath
            }
        }
        return nil
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.numberOfSections() ?? 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let rIndex = self.getRatingIndex() {
            if rIndex == indexPath {
                let mailboxRateCell = tableView.dequeueReusableCellWithIdentifier(MailboxRateReviewCell.Constant.identifier, forIndexPath: rIndex) as! MailboxRateReviewCell
                mailboxRateCell.callback = self
                mailboxRateCell.selectionStyle = .None
                return mailboxRateCell
            }
        }
        let mailboxCell = tableView.dequeueReusableCellWithIdentifier(MailboxMessageCell.Constant.identifier, forIndexPath: indexPath) as! MailboxMessageCell
        configureCell(mailboxCell, atIndexPath: indexPath)
        return mailboxCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fetchedResultsController?.numberOfRowsInSection(section) ?? 0
        return count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if (cell.respondsToSelector(Selector("setSeparatorInset:"))) {
            cell.separatorInset = UIEdgeInsetsZero
        }
        
        if (cell.respondsToSelector(Selector("setLayoutMargins:"))) {
            cell.layoutMargins = UIEdgeInsetsZero
        }
        
        fetchMessagesIfNeededForIndexPath(indexPath)
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension MailboxViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
        self.showNewMessageCount(self.newMessageCount)
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
                PMLog.D("Section: \(newIndexPath.section) Row: \(newIndexPath.row) ")
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                if self.needToShowNewMessage == true {
                    if let newMsg = anObject as? Message {
                        if let msgTime = newMsg.time where !newMsg.isRead {
                            let updateTime = viewModel.lastUpdateTime()
                            if msgTime.compare(updateTime.start) != NSComparisonResult.OrderedAscending {
                                self.newMessageCount += 1
                            }
                            
                        }
                    }
                }
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
    }
}


// MARK: - UITableViewDelegate

extension MailboxViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let rIndex = self.getRatingIndex() {
            if rIndex == indexPath {
                return kMailboxRateReviewCellHeight
            }
        }
        return kMailboxCellHeight
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if let rIndex = self.getRatingIndex() {
            if rIndex == indexPath {
                return nil
            }
        }
        return indexPath
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            if (self.isEditing) {
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
                
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            } else {
                self.indexPathForSelectedRow = indexPath
                performSegueForMessage(message)
            }
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let frame = noResultLabel.frame;
        if scrollView.contentOffset.y <= 0 {
            self.noResultLabel.frame = CGRect(x: frame.origin.x, y: -scrollView.contentOffset.y, width: frame.width, height: frame.height);
        } else {
            self.noResultLabel.frame = CGRect(x: frame.origin.x, y: 0, width: frame.width, height: frame.height);
        }
    }
}
