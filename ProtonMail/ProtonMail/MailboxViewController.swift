// MailboxViewController.swift
//
// Created by Yanfeng Zhang on 8/16/15.
// Copyright © 2016 ProtonMail. All rights reserved.
//

import UIKit
import CoreData
import MCSwipeTableViewCell

class MailboxViewController: ProtonMailViewController, ViewModelProtocol {
    
    // MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Private constants
    
    fileprivate let kMailboxCellHeight: CGFloat           = 62.0
    fileprivate let kMailboxRateReviewCellHeight: CGFloat = 125.0
    fileprivate let kLongPressDuration: CFTimeInterval    = 0.60 // seconds
    fileprivate let kMoreOptionsViewHeight: CGFloat       = 123.0
    
    fileprivate let kCellIdentifier                       = "MailboxCell"
    fileprivate let kSegueToCompose                       = "toCompose"
    fileprivate let kSegueToComposeShow                   = "toComposeShow"
    fileprivate let kSegueToSearchController              = "toSearchViewController"
    fileprivate let kSegueToMessageDetailController       = "toMessageDetailViewController"
    fileprivate let kSegueToMessageDetailFromNotification = "toMessageDetailViewControllerFromNotification"
    fileprivate let kSegueToTour                          = "to_onboarding_segue"
    fileprivate let kSegueToFeedback                      = "to_feedback_segue"
    fileprivate let kSegueToFeedbackView                  = "to_feedback_view_segue"
    fileprivate let kSegueToHumanCheckView                = "toHumanCheckView"
    
    fileprivate let kSegueMoveToFolders                   = "toMoveToFolderSegue"
    fileprivate let kSegueToApplyLabels                   = "toApplyLabelsSegue"
    
    @IBOutlet weak var undoView: UIView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var undoButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var undoBottomDistance: NSLayoutConstraint!
    // MARK: - Private attributes
    
    internal var viewModel: MailboxViewModel!
    //TODO:: this need release the delegate after use
    fileprivate var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    // this is for when user click the notification email
    internal var messageID: String?
    fileprivate var selectedMessages: NSMutableSet = NSMutableSet()
    internal var listEditing: Bool = false
    fileprivate var timer : Timer!
    
    fileprivate var timerAutoDismiss : Timer?
    
    fileprivate var fetching : Bool = false
    fileprivate var selectedDraft : Message!
    fileprivate var indexPathForSelectedRow : IndexPath!
    
    fileprivate var undoMessage : UndoMessage?
    
    fileprivate var isShowUndo : Bool = false
    fileprivate var isCheckingHuman: Bool = false
    
    fileprivate var ratingMessage : Message?
    
    // MAKR : - Private views
    internal var refreshControl: UIRefreshControl!
    fileprivate var navigationTitleLabel = UILabel()
    @IBOutlet weak var undoLabel: UILabel!
    @IBOutlet weak var noResultLabel: UILabel!
    
    // MARK: - Right bar buttons
    
    fileprivate var composeBarButtonItem: UIBarButtonItem!
    fileprivate var searchBarButtonItem: UIBarButtonItem!
    fileprivate var removeBarButtonItem: UIBarButtonItem!
    fileprivate var favoriteBarButtonItem: UIBarButtonItem!
    fileprivate var labelBarButtonItem: UIBarButtonItem!
    fileprivate var folderBarButtonItem: UIBarButtonItem!
    fileprivate var unreadBarButtonItem: UIBarButtonItem!
    fileprivate var moreBarButtonItem: UIBarButtonItem!
    
    
    // MARK: - Left bar button
    
    fileprivate var cancelBarButtonItem: UIBarButtonItem!
    fileprivate var menuBarButtonItem: UIBarButtonItem!
    fileprivate var fetchingMessage : Bool! = false
    fileprivate var fetchingStopped : Bool! = true
    fileprivate var needToShowNewMessage : Bool = false
    fileprivate var newMessageCount = 0
    
    // MARK: swipactions
    fileprivate var leftSwipeAction : MessageSwipeAction = .archive
    fileprivate var rightSwipeAction : MessageSwipeAction = .trash
    
    
    // MARK: TopMessage
    @IBOutlet weak var topMessageView: TopMessageView!
    @IBOutlet weak var topMsgTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var topMsgHeightConstraint: NSLayoutConstraint!
    fileprivate let kDefaultSpaceHide : CGFloat = -34.0
    fileprivate let kDefaultSpaceShow : CGFloat = 4.0
    fileprivate var latestSpaceHide : CGFloat = 0.0
    
    
    //not in used
    func setViewModel(_ vm: Any) {
        self.viewModel = vm as! MailboxViewModel
    }
    
    func inactiveViewModel() {
        resetFetchedResultsController()
    }
    
    @objc func doEnterForeground(){
        if viewModel.reloadTable() {
            resetTableView()
        }
    }
    
    func resetTableView() {
        resetFetchedResultsController()
        setupFetchedResultsController()
        self.tableView.reloadData()
    }
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.noResultLabel.text = NSLocalizedString("No Messages", comment: "message when mailbox doesnt have emailsß")
        
        undoButton.setTitle(NSLocalizedString("Undo", comment: "Action"), for: .normal)

        self.setNavigationTitleText(viewModel.getNavigationTitle())
        
        self.tableView!.RegisterCell(MailboxMessageCell.Constant.identifier)
        self.tableView!.RegisterCell(MailboxRateReviewCell.Constant.identifier)
        
        self.setupFetchedResultsController()
        
        self.addSubViews()
        self.addConstraints()
        
        self.updateNavigationController(listEditing)
        
        if !userCachedStatus.isTourOk() {
            userCachedStatus.resetTourValue()
            self.performSegue(withIdentifier: self.kSegueToTour, sender: self)
        }
        
        if userCachedStatus.isTouchIDEnabled {
            userCachedStatus.touchIDEmail = sharedUserDataService.username ?? ""
        }
        self.topMessageView.delegate = self
        
        self.undoBottomDistance.constant = -88
        self.undoButton.isHidden = true
        self.undoView.isHidden = true
        
        cleanRateReviewCell()
    }
    
    deinit {
        resetFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideTopMessage()
        NotificationCenter.default.addObserver(self, selector: #selector(MailboxViewController.reachabilityChanged(_:)), name: NSNotification.Name.reachabilityChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector:#selector(MailboxViewController.doEnterForeground), name:  NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        leftSwipeAction = sharedUserDataService.swiftLeft
        rightSwipeAction = sharedUserDataService.swiftRight
        
        self.refreshControl.endRefreshing()
    }
    
    @IBAction func undoAction(_ sender: UIButton) {
        self.undoTheMessage();
        self.hideUndoView();
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        self.stopAutoFetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        sharedPushNotificationService.processCachedLaunchOptions()
        
        let usedStorageSpace = sharedUserDataService.usedSpace
        let maxStorageSpace = sharedUserDataService.maxSpace
        StorageLimit().checkSpace(usedStorageSpace, maxSpace: maxStorageSpace)
        
        self.updateInterfaceWithReachability(sharedInternetReachability)
        //self.updateInterfaceWithReachability(sharedRemoteReachability)
        
        let selectedItem: IndexPath? = self.tableView.indexPathForSelectedRow as IndexPath?
        if let selectedItem = selectedItem {
            self.tableView.reloadRows(at: [selectedItem], with: UITableViewRowAnimation.fade)
            self.tableView.deselectRow(at: selectedItem, animated: true)
        }
        self.startAutoFetch()
        
        FileManager.default.cleanCachedAtts()
        
        if self.viewModel.getNotificationMessage() != nil {
            performSegue(withIdentifier: kSegueToMessageDetailFromNotification, sender: self)
        } else {
            let _ = checkHuman()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    fileprivate func addSubViews() {
        self.navigationTitleLabel.backgroundColor = UIColor.clear
        self.navigationTitleLabel.font = Fonts.h2.regular
        self.navigationTitleLabel.textAlignment = NSTextAlignment.center
        self.navigationTitleLabel.textColor = UIColor.white
        self.navigationTitleLabel.text = self.title ?? NSLocalizedString("INBOX", comment: "Title")
        self.navigationTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationTitleLabel
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        self.refreshControl.addTarget(self, action: #selector(MailboxViewController.getLatestMessages), for: UIControlEvents.valueChanged)
        self.refreshControl.tintColor = UIColor.gray
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
    
    fileprivate func addConstraints() {
        
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.tableView.reloadData()
    }
    
    // MARK: - Prepare for segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueToMessageDetailFromNotification {
            self.cancelButtonTapped()
            let messageDetailViewController = segue.destination as! MessageViewController
            sharedVMService.messageDetails(fromPush: messageDetailViewController)
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
            let messageDetailViewController = segue.destination as! MessageViewController
            sharedVMService.messageDetails(fromList: messageDetailViewController)
            let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = self.messageAtIndexPath(indexPathForSelectedRow) {
                    messageDetailViewController.message = message
                } else {
                    let alert = NSLocalizedString("Can't find the clicked message please try again!", comment: "Description").alertController()
                    alert.addOKAction()
                    present(alert, animated: true, completion: nil)
                }
            } else {
                PMLog.D("No selected row.")
            }
        } else if segue.identifier == kSegueToComposeShow {
            self.cancelButtonTapped()
            let composeViewController = segue.destination.childViewControllers[0] as! ComposeEmailViewController
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = self.messageAtIndexPath(indexPathForSelectedRow) {
                    sharedVMService.openDraftViewModel(composeViewController, msg: selectedDraft ?? message)
                } else {
                    let alert = NSLocalizedString("Can't find the clicked message please try again!", comment: "Description").alertController()
                    alert.addOKAction()
                    present(alert, animated: true, completion: nil)
                }
                
            } else {
                PMLog.D("No selected row.")
            }
            
        } else if segue.identifier == kSegueToApplyLabels {
            let popup = segue.destination as! LablesViewController
            popup.viewModel = LabelApplyViewModelImpl(msg: self.getSelectedMessages())
            popup.delegate = self
            self.setPresentationStyleForSelfController(self, presentingController: popup)
            self.cancelButtonTapped()
            
        } else if segue.identifier == kSegueMoveToFolders {
            let popup = segue.destination as! LablesViewController
            popup.viewModel = FolderApplyViewModelImpl(msg: self.getSelectedMessages())
            popup.delegate = self
            self.setPresentationStyleForSelfController(self, presentingController: popup)
            self.cancelButtonTapped()
            
        }
        else if segue.identifier == kSegueToHumanCheckView{
            let popup = segue.destination as! MailboxCaptchaViewController
            popup.viewModel = CaptchaViewModelImpl()
            popup.delegate = self
            self.setPresentationStyleForSelfController(self, presentingController: popup)
            
        } else if segue.identifier == kSegueToCompose {
            let composeViewController = segue.destination.childViewControllers[0] as! ComposeEmailViewController
            sharedVMService.newDraftViewModel(composeViewController)
            
        } else if segue.identifier == kSegueToTour {
            let popup = segue.destination as! OnboardingViewController
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        } else if segue.identifier == kSegueToFeedback {
            let popup = segue.destination as! FeedbackPopViewController
            popup.feedbackDelegate = self
            //popup.viewModel = LabelViewModelImpl(msg: self.getSelectedMessages())
            self.setPresentationStyleForSelfController(self, presentingController: popup)
        } else if segue.identifier == kSegueToFeedbackView {
            
        }
    }
    
    
    // MARK: - Button Targets
    @objc internal func composeButtonTapped() {
        if checkHuman() {
            self.performSegue(withIdentifier: kSegueToCompose, sender: self)
        }
    }
    @objc internal func searchButtonTapped() {
        self.performSegue(withIdentifier: kSegueToSearchController, sender: self)
    }
    
    @objc internal func labelButtonTapped() {
        self.performSegue(withIdentifier: kSegueToApplyLabels, sender: self)
    }
    
    @objc internal func folderButtonTapped() {
        self.performSegue(withIdentifier: kSegueMoveToFolders, sender: self)
    }
    
    func performSegueForMessageFromNotification() {
        performSegue(withIdentifier: kSegueToMessageDetailFromNotification, sender: self)
    }
    
    @objc internal func removeButtonTapped() {
        if viewModel.isDelete() {
            moveMessagesToLocation(.deleted)
            showMessageMoved(title: NSLocalizedString("Message has been deleted.", comment: "Title"))
        } else {
            moveMessagesToLocation(.trash)
            showMessageMoved(title: NSLocalizedString("Message has been moved.", comment: "Title"))
        }
        cancelButtonTapped();
    }
    
    @objc internal func favoriteButtonTapped() {
        selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.isStarred)
        cancelButtonTapped();
    }
    
    @objc internal func unreadButtonTapped() {
        selectedMessagesSetValue(setValue: false, forKey: Message.Attributes.isRead)
        cancelButtonTapped();
    }
    
    @objc internal func moreButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel",  comment: "Action"), style: .cancel, handler: nil))
        
        if viewModel.isShowEmptyFolder() {
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Empty Folder",  comment: "Action"), style: .destructive, handler: { (action) -> Void in

                self.viewModel.emptyFolder()
                self.showNoResultLabel()
                self.navigationController?.popViewController(animated: true)
            }))
        } else {
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Mark Read",  comment: "Action"), style: .default, handler: { (action) -> Void in
                self.selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.isRead)
                self.cancelButtonTapped();
                self.navigationController?.popViewController(animated: true)
            }))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Add Star",  comment: "Action"), style: .default, handler: { (action) -> Void in
                self.selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.isStarred)
                self.selectedMessagesSetStar()
                self.cancelButtonTapped();
                self.navigationController?.popViewController(animated: true)
            }))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Remove Star",  comment: "Action"), style: .default, handler: { (action) -> Void in
                self.selectedMessagesSetValue(setValue: false, forKey: Message.Attributes.isStarred)
                self.selectedMessagesSetUnStar()
                self.cancelButtonTapped();
                self.navigationController?.popViewController(animated: true)
            }))
            
            var locations: [MessageLocation : UIAlertActionStyle] = [.inbox : .default, .spam : .default, .archive : .default]
            if !viewModel.isCurrentLocation(.outbox) {
                locations = [.spam : .default, .archive : .default]
            }
            
            if (viewModel.isCurrentLocation(.outbox)) {
                locations = [:];
            }
            
            for (location, style) in locations {
                if !viewModel.isCurrentLocation(location) {
                    alertController.addAction(UIAlertAction(title: location.actionTitle, style: style, handler: { (action) -> Void in
                        self.moveMessagesToLocation(location)
                        self.cancelButtonTapped();
                        self.navigationController?.popViewController(animated: true)
                    }))
                }
            }
        }
        
        alertController.popoverPresentationController?.barButtonItem = moreBarButtonItem
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        present(alertController, animated: true, completion: nil)
    }
    
    @objc internal func cancelButtonTapped() {
        self.selectedMessages.removeAllObjects()
        self.hideCheckOptions()
        
        self.updateNavigationController(false)
    }
    
    @objc internal func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        self.showCheckOptions(longPressGestureRecognizer)
        updateNavigationController(listEditing)
    }
    
    //    internal func createRateReviewCell () {
    //        let count = fetchedResultsController?.numberOfRowsInSection(0) ?? 0
    //        if count > 3 {
    //            if let message = fetchedResultsController?.objectAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as? Message {
    //                if let context = message.managedObjectContext {
    //                    let newMessage = Message(context: context)
    //                    newMessage.messageType = 1
    //                    newMessage.title = ""
    //                    newMessage.messageStatus = 1
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
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K == 1", Message.Attributes.messageType)
            do {
                if let messages = try context.fetch(fetchRequest) as? [Message] {
                    for msg in messages {
                        if msg.managedObjectContext != nil {
                            context.delete(msg)
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
    
    internal func beginRefreshingManually() {
        self.refreshControl.beginRefreshing()
        if (self.tableView.contentOffset.y == 0) {
            UIView.animate(withDuration: 0.25, animations: {
                self.tableView.contentOffset = CGPoint(x: 0, y: -self.refreshControl.frame.size.height);
            })
        }
    }
    
    // MARK: - Private methods
    fileprivate func startAutoFetch(_ run : Bool = true)
    {
        self.timer = Timer.scheduledTimer(timeInterval: self.timerInterval, target: self, selector: #selector(MailboxViewController.refreshPage), userInfo: nil, repeats: true)
        fetchingStopped = false
        
        if run {
            self.timer.fire()
        }
    }
    
    fileprivate func stopAutoFetch()
    {
        fetchingStopped = true
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    @objc func refreshPage()
    {
        if !fetchingStopped {
            getLatestMessages()
        }
    }
    
    fileprivate func checkHuman() -> Bool {
        if sharedMessageQueue.isRequiredHumanCheck && isCheckingHuman == false {
            //show human check view with warning
            isCheckingHuman = true
            performSegue(withIdentifier: kSegueToHumanCheckView, sender: self)
            return false
        }
        return true
    }
    
    fileprivate var timerInterval : TimeInterval = 30
    fileprivate var failedTimes = 30
    
    func offlineTimerReset() {
        timerInterval = TimeInterval(arc4random_uniform(90)) + 30;
        PMLog.D("next check will be after : \(timerInterval) seconds")
        stopAutoFetch()
        startAutoFetch(false)
    }
    
    func onlineTimerReset() {
        timerInterval = 30
        stopAutoFetch()
        startAutoFetch(false)
    }
    
    fileprivate func messageAtIndexPath(_ indexPath: IndexPath) -> Message? {
        if self.fetchedResultsController?.numberOfSections() > indexPath.section {
            if self.fetchedResultsController?.numberOfRows(in: indexPath.section) > indexPath.row {
                if let message = fetchedResultsController?.object(at: indexPath) as? Message {
                    if message.managedObjectContext != nil {
                        return message
                    }
                }
            }
        }
        return nil
    }
    
    fileprivate func configureCell(_ mailboxCell: MailboxMessageCell, atIndexPath indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            mailboxCell.configureCell(message, showLocation: viewModel.showLocation(), ignoredTitle: viewModel.ignoredLocationTitle())
            mailboxCell.setCellIsChecked(selectedMessages.contains(message.messageID))
            if (self.listEditing) {
                mailboxCell.showCheckboxOnLeftSide()
            } else {
                mailboxCell.hideCheckboxOnLeftSide()
            }
            
            mailboxCell.defaultColor = UIColor.lightGray
            let leftCrossView = UILabel();
            leftCrossView.text = self.viewModel.getSwipeTitle(leftSwipeAction)
            leftCrossView.sizeToFit()
            leftCrossView.textColor = UIColor.white
            
            let rightCrossView = UILabel();
            rightCrossView.text = self.viewModel.getSwipeTitle(rightSwipeAction)
            rightCrossView.sizeToFit()
            rightCrossView.textColor = UIColor.white
            
            if self.viewModel.isSwipeActionValid(self.leftSwipeAction) {
                mailboxCell.setSwipeGestureWith(leftCrossView, color: leftSwipeAction.actionColor, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state1 ) { (cell, state, mode) -> Void in
                    if let indexp = self.tableView.indexPath(for: cell!) {
                        if self.viewModel.isSwipeActionValid(self.leftSwipeAction) {
                            if !self.processSwipeActions(self.leftSwipeAction, indexPath: indexp) {
                                mailboxCell.swipeToOrigin(completion: nil)
                            } else if self.viewModel.stayAfterAction(self.leftSwipeAction) {
                                mailboxCell.swipeToOrigin(completion: nil)
                            }
                        } else {
                            mailboxCell.swipeToOrigin(completion: nil)
                        }
                    } else {
                        self.tableView.reloadData()
                    }
                }
            }
            
            if self.viewModel.isSwipeActionValid(self.rightSwipeAction) {
                mailboxCell.setSwipeGestureWith(rightCrossView, color: rightSwipeAction.actionColor, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state3  ) { (cell, state, mode) -> Void in
                    if let indexp = self.tableView.indexPath(for: cell!) {
                        if self.viewModel.isSwipeActionValid(self.rightSwipeAction) {
                            if !self.processSwipeActions(self.rightSwipeAction, indexPath: indexp) {
                                mailboxCell.swipeToOrigin(completion: nil)
                            } else if self.viewModel.stayAfterAction(self.rightSwipeAction) {
                                mailboxCell.swipeToOrigin(completion: nil)
                            }
                        } else {
                            mailboxCell.swipeToOrigin(completion: nil)
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
    
    
    fileprivate func processSwipeActions(_ action: MessageSwipeAction, indexPath: IndexPath) -> Bool {
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
    
    fileprivate func archiveMessageForIndexPath(_ indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
            let res = viewModel.archiveMessage(message)
            switch res {
            case .showUndo:
                showUndoView(NSLocalizedString("Archived", comment: "Description"))
            case .showGeneral:
                showMessageMoved(title: NSLocalizedString("Message has been moved.", comment: "Title"))
            default: break
            }
        }
    }
    
    fileprivate func deleteMessageForIndexPath(_ indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
            let res = viewModel.deleteMessage(message)
            switch res {
            case .showUndo:
                showUndoView(NSLocalizedString("Deleted", comment: "Description"))
            case .showGeneral:
                showMessageMoved(title: NSLocalizedString("Message has been deleted.", comment: "Title"))
            default: break
            }
        }
    }
    
    fileprivate func spamMessageForIndexPath(_ indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
            let res = viewModel.spamMessage(message)
            switch res {
            case .showUndo:
                showUndoView(NSLocalizedString("Spammed", comment: "Description"))
            case .showGeneral:
                showMessageMoved(title: NSLocalizedString("Message has been moved.", comment: "Title"))
            default: break
            }
        }
    }
    
    fileprivate func starMessageForIndexPath(_ indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
            let _ = viewModel.starMessage(message)
        }
    }
    
    fileprivate func undoTheMessage() { //need move into viewModel
        if let undoMsg = undoMessage {
            if let context = fetchedResultsController?.managedObjectContext {
                if let message = Message.messageForMessageID(undoMsg.messageID, inManagedObjectContext: context) {
                    self.viewModel.updateBadgeNumberWhenMove(message, to: undoMsg.oldLocation)
                    message.removeLocationFromLabels(currentlocation: message.location, location: undoMsg.oldLocation, keepSent: true)
                    message.needsUpdate = true
                    message.location = undoMsg.oldLocation
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D("error: \(error)")
                    }
                }
            }
            undoMessage = nil
        }
    }
    
    fileprivate func showUndoView(_ title : String) {
        undoLabel.text = String(format: NSLocalizedString("Message %@", comment: "Message with title"), title)
        self.undoBottomDistance.constant = 0
        self.undoButton.isHidden = false
        self.undoView.isHidden = false
        self.undoButtonWidth.constant = 100.0
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.timerAutoDismiss = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(MailboxViewController.timerTriggered), userInfo: nil, repeats: false)
    }
    
    fileprivate func showMessageMoved(title : String) {
        undoLabel.text = title
        self.undoBottomDistance.constant = 0
        self.undoButton.isHidden = false
        self.undoView.isHidden = false
        self.undoButtonWidth.constant = 0.0
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.timerAutoDismiss = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(MailboxViewController.timerTriggered), userInfo: nil, repeats: false)
    }
    
    fileprivate func hideUndoView() {
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        
        self.undoBottomDistance.constant = -88
        self.undoButton.isHidden = true
        self.undoView.isHidden = true
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func timerTriggered() {
        self.hideUndoView()
    }
    
    fileprivate func setupFetchedResultsController() {
        self.fetchedResultsController = self.viewModel.getFetchedResultsController()
        self.fetchedResultsController?.delegate = self
    }
    
    func resetFetchedResultsController() {
        if let controller = self.fetchedResultsController {
            controller.delegate = nil
        }
    }
    
    fileprivate func fetchMessagesIfNeededForIndexPath(_ indexPath: IndexPath) {
        if let fetchedResultsController = fetchedResultsController {
            if let last = fetchedResultsController.fetchedObjects?.last as? Message {
                if let current = self.messageAtIndexPath(indexPath) {
                    let updateTime = viewModel.lastUpdateTime()
                    if let currentTime = current.time {
                        let isOlderMessage = updateTime.end.compare(currentTime as Date) != ComparisonResult.orderedAscending
                        let isLastMessage = (last == current)
                        if  (isOlderMessage || isLastMessage) && !fetching {
                            let sectionCount = fetchedResultsController.numberOfRows(in: 0)
                            let recordedCount = Int(updateTime.total)
                            if updateTime.isNew || recordedCount > sectionCount { //here need add a counter to check if tried too many times make one real call in case count not right
                                self.fetching = true
                                tableView.showLoadingFooter()
                                let updateTime = viewModel.lastUpdateTime()
                                let unixTimt:Int = (updateTime.end as Date == Date.distantPast ) ? 0 : Int(updateTime.end.timeIntervalSince1970)
                                viewModel.fetchMessages(last.messageID, Time: unixTimt, foucsClean: false, completion: { (task, response, error) -> Void in
                                    self.tableView.hideLoadingFooter()
                                    self.fetching = false
                                    if error != nil {
                                        PMLog.D("search error: \(String(describing: error))")
                                    } else {
                                        
                                    }
                                    let _ = self.checkHuman()
                                })
                            }
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func checkEmptyMailbox () {
        
        if self.fetchingStopped! == true {
            return;
        }
        
        if let fetchedResultsController = fetchedResultsController {
            let secouts = fetchedResultsController.numberOfSections() 
            if secouts > 0 {
                let sectionCount = fetchedResultsController.numberOfRows(in: 0)
                if sectionCount == 0 {
                    let updateTime = viewModel.lastUpdateTime()
                    let recordedCount = Int(updateTime.total)
                    if updateTime.isNew || recordedCount > sectionCount {
                        self.fetching = true
                        viewModel.fetchMessages("", Time: 0, foucsClean: false, completion: { (task, messages, error) -> Void in
                            self.fetching = false
                            if error != nil {
                                PMLog.D("search error: \(String(describing: error))")
                            } else {
                                
                            }
                            let _ = self.checkHuman()
                        })
                    }
                }
            }
        }
    }
    
    func handleRequestError (_ error : NSError) {
        let code = error.code
        if code == NSURLErrorTimedOut {
            self.showTimeOutErrorMessage()
        } else if code == NSURLErrorNotConnectedToInternet || code == NSURLErrorCannotConnectToHost {
            self.showNoInternetErrorMessage()
        } else if code == APIErrorCode.API_offline {
            self.showOfflineErrorMessage(error)
            offlineTimerReset()
        } else if code == APIErrorCode.HTTP503 || code == NSURLErrorBadServerResponse {
            self.show503ErrorMessage(error)
            offlineTimerReset()
        } else if code == APIErrorCode.HTTP504 {
            self.showTimeOutErrorMessage()
        }
        PMLog.D("error: \(error)")
    }
    
    @objc internal func getLatestMessages() {
        self.hideTopMessage()
        if !fetchingMessage {
            fetchingMessage = true
            
            self.beginRefreshingManually()
            let updateTime = viewModel.lastUpdateTime()
            let complete : APIService.CompletionBlock = { (task, res, error) -> Void in
                self.needToShowNewMessage = false
                self.newMessageCount = 0
                self.fetchingMessage = false
                
                if self.fetchingStopped! == true {
                    return;
                }
                
                if let error = error {
                    self.handleRequestError(error)
                }
                
                var loadMore: Int = 0
                if error == nil {
                    self.onlineTimerReset()
                    self.viewModel.resetNotificationMessage()
                    if !updateTime.isNew {
                        
                    }
                    if let notices = res?["Notices"] as? [String] {
                        serverNotice.check(notices)
                    }
                    
                    if let more = res?["More"] as? Int {
                       loadMore = more
                    }
                }
                
                if loadMore > 0 {
                     self.retry()
                } else {
                    delay(1.0, closure: {
                        self.refreshControl.endRefreshing()
                        if self.fetchingStopped! == true {
                            return;
                        }
                        self.showNoResultLabel()
                        self.tableView.reloadData()
                        let _ = self.checkHuman()
                    })
                }
                
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
                viewModel.fetchNewMessages(self.viewModel.getNotificationMessage(),
                                           Time: Int(updateTime.start.timeIntervalSince1970),
                                           completion: complete)
                self.checkEmptyMailbox()
            }
        }
    }
    
    fileprivate func showNoResultLabel() {
        let count = (self.fetchedResultsController?.numberOfSections() > 0) ? (self.fetchedResultsController?.numberOfRows(in: 0) ?? 0) : 0
        if (count <= 0 && !fetchingMessage ) {
            self.noResultLabel.isHidden = false;
        } else {
            self.noResultLabel.isHidden = true;
        }
    }
    
    
    fileprivate func moveMessagesToLocation(_ location: MessageLocation) {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, self.selectedMessages)
            do {
                if let messages = try context.fetch(fetchRequest) as? [Message] {
                    for message in messages {
                        message.removeLocationFromLabels(currentlocation: message.location, location: location, keepSent: true);
                        message.needsUpdate = true
                        message.location = location
                        if let error = context.saveUpstreamIfNeeded() {
                            PMLog.D("error: \(error)")
                        }
                    }
                    
                }
            } catch let ex as NSError {
                PMLog.D(" error: \(ex)")
            }
            
        }
    }
    fileprivate func performSegueForMessage(_ message: Message) {
        if viewModel.isDrafts() || message.hasDraftLabel() {
            if !message.messageID.isEmpty {
                sharedMessageDataService.ForcefetchDetailForMessage(message) {_, _, msg, error in
                    if error != nil {
                        PMLog.D("error: \(String(describing: error))")
                    }
                    else
                    {
                        self.selectedDraft = msg
                        
                        if self.checkHuman() {
                            self.performSegue(withIdentifier: self.kSegueToComposeShow, sender: self)
                        }
                    }
                }
            } else {
                if self.checkHuman() {
                    self.performSegue(withIdentifier: self.kSegueToComposeShow, sender: self)
                }
            }
        } else {
            performSegue(withIdentifier: kSegueToMessageDetailController, sender: self)
        }
    }
    
    fileprivate func selectMessageIDIfNeeded() {
        if messageID != nil {
            if let messages = fetchedResultsController?.fetchedObjects as? [Message] {
                if let message = messages.filter({ $0.messageID == self.messageID }).first {
                    if let indexPath = fetchedResultsController?.indexPath(forObject: message) {
                        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
                    }
                    performSegueForMessage(message)
                    messageID = nil
                }
            }
        }
    }
    
    fileprivate func selectedMessagesSetValue(setValue value: Any?, forKey key: String) {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, self.selectedMessages)
            
            do {
                if let messages = try context.fetch(fetchRequest) as? [Message] {
                    if key == Message.Attributes.isRead {
                        if let changeto = value as? Bool {
                            for msg in messages {
                                self.viewModel.updateBadgeNumberWhenRead(msg, changeToRead: changeto)
                            }
                        }
                    }
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
    
    
    fileprivate func selectedMessagesSetStar() {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, self.selectedMessages)
            do {
                if let messages = try context.fetch(fetchRequest) as? [Message] {
                    for msg in messages {
                        msg.setLabelLocation(.starred);
                    }
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
    
    fileprivate func selectedMessagesSetUnStar() {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, self.selectedMessages)
            do {
                if let messages = try context.fetch(fetchRequest) as? [Message] {
                    for msg in messages {
                        msg.removeLocationFromLabels(currentlocation: .starred, location: .deleted, keepSent: true);
                    }
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
    
    fileprivate func getSelectedMessages() -> [Message] {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, selectedMessages)
            do {
                if let messages = try context.fetch(fetchRequest) as? [Message] {
                    return messages;
                }
            } catch let ex as NSError {
                PMLog.D(" error: \(ex)")
            }
        }
        return [Message]();
    }
    
    fileprivate func setupLeftButtons(_ editingMode: Bool) {
        var leftButtons: [UIBarButtonItem]
        
        if (!editingMode) {
            leftButtons = [self.menuBarButtonItem]
        } else {
            if (self.cancelBarButtonItem == nil) {
                self.cancelBarButtonItem = UIBarButtonItem(title:NSLocalizedString("Cancel", comment: "Action"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MailboxViewController.cancelButtonTapped))
            }
            
            leftButtons = [self.cancelBarButtonItem]
        }
        
        self.navigationItem.setLeftBarButtonItems(leftButtons, animated: true)
    }
    
    fileprivate func setupNavigationTitle(_ editingMode: Bool) {
        // title animation
        if (editingMode) {
            self.setNavigationTitleText("")
        } else {
            self.setNavigationTitleText(viewModel.getNavigationTitle())
        }
    }
    
    fileprivate func setupRightButtons(_ editingMode: Bool) {
        var rightButtons: [UIBarButtonItem]
        
        if (!editingMode) {
            if (self.composeBarButtonItem == nil) {
                self.composeBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_compose"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MailboxViewController.composeButtonTapped))
            }
            
            if (self.searchBarButtonItem == nil) {
                self.searchBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_search"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MailboxViewController.searchButtonTapped))
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_more"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MailboxViewController.moreButtonTapped))
            }
            
            if viewModel.isShowEmptyFolder() {
                rightButtons = [self.moreBarButtonItem, self.composeBarButtonItem, self.searchBarButtonItem]
            } else {
                rightButtons = [self.composeBarButtonItem, self.searchBarButtonItem]
            }
        } else {
            if (self.unreadBarButtonItem == nil) {
                self.unreadBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_unread"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MailboxViewController.unreadButtonTapped))
            }
            
            if (self.labelBarButtonItem == nil) {
                self.labelBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_label"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MailboxViewController.labelButtonTapped))
            }
            
            if (self.folderBarButtonItem == nil) {
                self.folderBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_folder"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MailboxViewController.folderButtonTapped))
            }
            
            if (self.removeBarButtonItem == nil) {
                self.removeBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_trash"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MailboxViewController.removeButtonTapped))
            }
            
            if (self.favoriteBarButtonItem == nil) {
                self.favoriteBarButtonItem = UIBarButtonItem(image: UIImage(named: "favorite"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MailboxViewController.favoriteButtonTapped))
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_more"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(MailboxViewController.moreButtonTapped))
            }
            
            if (viewModel.isDrafts()) {
                rightButtons = [self.removeBarButtonItem]
            } else if (viewModel.isCurrentLocation(.outbox)) {
                rightButtons = [self.moreBarButtonItem, self.removeBarButtonItem, self.labelBarButtonItem, self.unreadBarButtonItem]
            } else {
                rightButtons = [self.moreBarButtonItem, self.removeBarButtonItem, self.folderBarButtonItem, self.labelBarButtonItem, self.unreadBarButtonItem]
            }
        }
        
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    
    fileprivate func hideCheckOptions() {
        self.listEditing = false
        if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
            for indexPath in indexPathsForVisibleRows {
                if let messageCell: MailboxMessageCell = self.tableView.cellForRow(at: indexPath) as? MailboxMessageCell {
                    messageCell.setCellIsChecked(false)
                    messageCell.hideCheckboxOnLeftSide()
                    
                    UIView.animate(withDuration: 0.25, animations: { () -> Void in
                        messageCell.layoutIfNeeded()
                    })
                }
            }
        }
    }
    
    fileprivate func showCheckOptions(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let point: CGPoint = longPressGestureRecognizer.location(in: self.tableView)
        let indexPath: IndexPath? = self.tableView.indexPathForRow(at: point)
        
        if let indexPath = indexPath {
            if (longPressGestureRecognizer.state == UIGestureRecognizerState.began) {
                self.listEditing = true
                if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
                    for visibleIndexPath in indexPathsForVisibleRows {
                        if let messageCell: MailboxMessageCell = self.tableView.cellForRow(at: visibleIndexPath) as? MailboxMessageCell {
                            messageCell.showCheckboxOnLeftSide()
                            
                            // set selected row to checked
                            if (indexPath.row == visibleIndexPath.row) {
                                if let message = self.messageAtIndexPath(indexPath) {
                                    selectedMessages.add(message.messageID)
                                }
                                messageCell.setCellIsChecked(true)
                            }
                            
                            UIView.animate(withDuration: 0.25, animations: { () -> Void in
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
    
    fileprivate func updateNavigationController(_ editingMode: Bool) {
        self.setupLeftButtons(editingMode)
        self.setupNavigationTitle(editingMode)
        self.setupRightButtons(editingMode)
    }
    
    // MARK: - Public methods
    func setNavigationTitleText(_ text: String?) {
        let animation = CATransition()
        animation.duration = 0.25
        animation.type = kCATransitionFade
        self.navigationController?.navigationBar.layer.add(animation, forKey: "fadeText")
        if let t = text, t.count > 0 {
            self.title = t
            self.navigationTitleLabel.text = t
        } else {
            self.title = ""
            self.navigationTitleLabel.text = ""
        }
    }
}

extension MailboxViewController : LablesViewControllerDelegate {
    func dismissed() {
        
    }
    
    func apply(type: LabelFetchType) {
        if type == .label {
            showMessageMoved(title: NSLocalizedString("Labels have been applied.", comment: "Title"))
        } else if type == .folder {
            showMessageMoved(title: NSLocalizedString("Message has been moved.", comment: "Title"))
        }
    }
}

extension MailboxViewController : MailboxCaptchaVCDelegate {
    
    func cancel() {
        isCheckingHuman = false
    }
    
    func done() {
        isCheckingHuman = false
        sharedMessageQueue.isRequiredHumanCheck = false
    }
}

extension MailboxViewController : TopMessageViewDelegate {
    
    internal func showErrorMessage(_ error: NSError?) {
        if error != nil {
            self.topMsgTopConstraint.constant = self.kDefaultSpaceShow
            self.latestSpaceHide = self.topMessageView.updateMessage(error: error!)
            self.topMsgHeightConstraint.constant = self.latestSpaceHide >= 0.0 ? self.kDefaultSpaceHide : (self.latestSpaceHide * -1)
            self.updateViewConstraints()
            
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
    
    internal func showTimeOutErrorMessage() {
        self.topMsgTopConstraint.constant = self.kDefaultSpaceShow
        self.latestSpaceHide = self.topMessageView.updateMessage(timeOut: NSLocalizedString("The request timed out.", comment: "Title"))
        self.topMsgHeightConstraint.constant = self.latestSpaceHide >= 0.0 ? self.kDefaultSpaceHide : (self.latestSpaceHide * -1)
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    internal func showNoInternetErrorMessage() {
        self.topMsgTopConstraint.constant = self.kDefaultSpaceShow
        self.latestSpaceHide = self.topMessageView.updateMessage(noInternet : NSLocalizedString("No connectivity detected...", comment: "Title"))
        self.topMsgHeightConstraint.constant = self.latestSpaceHide >= 0.0 ? self.kDefaultSpaceHide : (self.latestSpaceHide * -1)
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    internal func showOfflineErrorMessage(_ error : NSError?) {
        self.topMsgTopConstraint.constant = self.kDefaultSpaceShow
        self.latestSpaceHide = self.topMessageView.updateMessage(noInternet : error?.localizedDescription ?? NSLocalizedString("The ProtonMail current offline...", comment: "Title"))
        self.topMsgHeightConstraint.constant = self.latestSpaceHide >= 0.0 ? self.kDefaultSpaceHide : (self.latestSpaceHide * -1)
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    internal func show503ErrorMessage(_ error : NSError?) {
        self.topMsgTopConstraint.constant = self.kDefaultSpaceShow
        self.latestSpaceHide = self.topMessageView.updateMessage(noInternet : NSLocalizedString("API Server not reachable...", comment: "Title"))
        self.topMsgHeightConstraint.constant = self.latestSpaceHide >= 0.0 ? self.kDefaultSpaceHide : (self.latestSpaceHide * -1)
        self.updateViewConstraints()
        
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    
    internal func showNewMessageCount(_ count : Int) {
        if self.needToShowNewMessage == true {
            self.needToShowNewMessage = false
            self.newMessageCount = 0
            if count > 0 {
                self.topMsgTopConstraint.constant = self.kDefaultSpaceShow
                if count == 1 {
                    self.latestSpaceHide = self.topMessageView.updateMessage(newMessage: NSLocalizedString("You have a new email!", comment: "Title"))
                } else {
                    self.latestSpaceHide = self.topMessageView.updateMessage(newMessage: String(format: NSLocalizedString("You have %d new emails!", comment: "Message"), count))
                }
                self.topMsgHeightConstraint.constant = self.latestSpaceHide >= 0.0 ? self.kDefaultSpaceHide : (self.latestSpaceHide * -1)
                self.updateViewConstraints()
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @objc internal func reachabilityChanged(_ note : Notification) {
        if let curReach = note.object as? Reachability {
            self.updateInterfaceWithReachability(curReach)
        } else {
            if let status = note.object as? Int {
                PMLog.D("\(status)")
                if status == 0 { //time out
                    showTimeOutErrorMessage()
                } else if status == 1 { //not reachable
                    showNoInternetErrorMessage()
                }
            }
        }
    }
    
    internal func updateInterfaceWithReachability(_ reachability : Reachability) {
        let netStatus = reachability.currentReachabilityStatus()
        //let connectionRequired = reachability.connectionRequired()
        //PMLog.D("connectionRequired : \(connectionRequired)")
        switch (netStatus)
        {
        case NotReachable:
            PMLog.D("Access Not Available")
            self.topMsgTopConstraint.constant = self.kDefaultSpaceShow
            self.latestSpaceHide = self.topMessageView.updateMessage(noInternet: NSLocalizedString("No connectivity detected...", comment: "Title"))
            self.topMsgHeightConstraint.constant = self.latestSpaceHide >= 0.0 ? self.kDefaultSpaceHide : (self.latestSpaceHide * -1)
            self.updateViewConstraints()
        case ReachableViaWWAN:
            //PMLog.D("Reachable WWAN")
            self.topMsgTopConstraint.constant = self.latestSpaceHide >= 0.0 ? self.kDefaultSpaceHide : self.latestSpaceHide
            self.latestSpaceHide = 0.0
            self.updateViewConstraints()
        case ReachableViaWiFi:
            //PMLog.D("Reachable WiFi")
            self.topMsgTopConstraint.constant = self.latestSpaceHide >= 0.0 ? self.kDefaultSpaceHide : self.latestSpaceHide
            self.latestSpaceHide = 0.0
            self.updateViewConstraints()
        default:
            PMLog.D("Reachable default unknow")
        }
        
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func hideTopMessage() {
        self.topMsgTopConstraint.constant = self.latestSpaceHide >= 0.0 ? self.kDefaultSpaceHide : self.latestSpaceHide
        self.latestSpaceHide = 0.0
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func close() {
        self.hideTopMessage()
    }
    
    func retry() {
        self.getLatestMessages()
    }
}

extension MailboxViewController : FeedbackPopViewControllerDelegate {
    
    func cancelled() {
        // just cancelled
    }
    
    func showHelp() {
        self.performSegue(withIdentifier: kSegueToFeedbackView, sender: self)
    }
    
    func showSupport() {
        self.performSegue(withIdentifier: kSegueToFeedbackView, sender: self)
    }
    
    func showRating() {
        self.performSegue(withIdentifier: kSegueToFeedbackView, sender: self)
    }
    
}

// MARK : review delegate
extension MailboxViewController: MailboxRateReviewCellDelegate {
    func mailboxRateReviewCell(_ cell: UITableViewCell, yesORno: Bool) {
        cleanRateReviewCell()
        
        // go to next screen
        if yesORno == true {
            self.performSegue(withIdentifier: kSegueToFeedback, sender: self)
        }
    }
}


// MARK: - UITableViewDataSource

extension MailboxViewController: UITableViewDataSource {
    
    func getRatingIndex () -> IndexPath?{
        if let msg = ratingMessage {
            if let indexPath = fetchedResultsController?.indexPath(forObject: msg) {
                return indexPath
            }
        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.numberOfSections() ?? 1
    }
    
    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let rIndex = self.getRatingIndex() {
            if rIndex == indexPath {
                //let mailboxRateCell = tableView.dequeueReusableCellWithIdentifier(MailboxRateReviewCell.Constant.identifier, forIndexPath: rIndex) as! MailboxRateReviewCell
                //mailboxRateCell.callback = self
                //mailboxRateCell.selectionStyle = .None
                //return mailboxRateCell
            }
        }
        let mailboxCell = tableView.dequeueReusableCell(withIdentifier: MailboxMessageCell.Constant.identifier, for: indexPath) as! MailboxMessageCell
        configureCell(mailboxCell, atIndexPath: indexPath)
        return mailboxCell
    }
    
    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fetchedResultsController?.numberOfRows(in: section) ?? 0
        return count
    }
    
    @objc func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.zeroMargin()
        fetchMessagesIfNeededForIndexPath(indexPath)
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension MailboxViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        self.showNewMessageCount(self.newMessageCount)
        selectMessageIDIfNeeded()
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
        //PMLog.D("\()")
        
        switch(type) {
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
        case .insert:
            if let newIndexPath = newIndexPath {
                PMLog.D("Section: \(newIndexPath.section) Row: \(newIndexPath.row) ")
                tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
                if self.needToShowNewMessage == true {
                    if let newMsg = anObject as? Message {
                        if let msgTime = newMsg.time, !newMsg.isRead {
                            let updateTime = viewModel.lastUpdateTime()
                            if msgTime.compare(updateTime.start as Date) != ComparisonResult.orderedAscending {
                                self.newMessageCount += 1
                            }
                        }
                    }
                }
            }
        case .update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRow(at: indexPath) as? MailboxMessageCell {
                    configureCell(cell, atIndexPath: indexPath)
                }
            }
        default:
            return
        }
        
        if self.noResultLabel.isHidden == false {
            self.showNoResultLabel()
        }
    }
}

// MARK: - UITableViewDelegate

extension MailboxViewController: UITableViewDelegate {
    @objc func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let rIndex = self.getRatingIndex() {
            if rIndex == indexPath {
                return kMailboxRateReviewCellHeight
            }
        }
        return kMailboxCellHeight
    }
    
    @objc func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let rIndex = self.getRatingIndex() {
            if rIndex == indexPath {
                return nil
            }
        }
        return indexPath
    }
    
    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            if (self.listEditing) {
                let messageAlreadySelected: Bool = selectedMessages.contains(message.messageID)
                if (messageAlreadySelected) {
                    selectedMessages.remove(message.messageID)
                } else {
                    selectedMessages.add(message.messageID)
                }
                // update checkbox state
                if let mailboxCell: MailboxMessageCell = tableView.cellForRow(at: indexPath) as? MailboxMessageCell {
                    mailboxCell.setCellIsChecked(!messageAlreadySelected)
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
            } else {
                self.indexPathForSelectedRow = indexPath
                performSegueForMessage(message)
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let frame = noResultLabel.frame;
        if scrollView.contentOffset.y <= 0 {
            self.noResultLabel.frame = CGRect(x: frame.origin.x, y: -scrollView.contentOffset.y, width: frame.width, height: frame.height);
        } else {
            self.noResultLabel.frame = CGRect(x: frame.origin.x, y: 0, width: frame.width, height: frame.height);
        }
    }
}
