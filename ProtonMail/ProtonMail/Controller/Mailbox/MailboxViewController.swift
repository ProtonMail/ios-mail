//
//  MailboxViewController.swift
//  ProtonMail - Created on 8/16/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import CoreData
import MCSwipeTableViewCell

class MailboxViewController: ProtonMailViewController, ViewModelProtocolNew, CoordinatedNew {
    typealias viewModelType = MailboxViewModel
    typealias coordinatorType = MailboxCoordinator

    private var viewModel: MailboxViewModel!
    private var coordinator: MailboxCoordinator?
    
    func getCoordinator() -> CoordinatorNew? {
        return self.coordinator
    }
    
    func set(coordinator: MailboxCoordinator) {
        self.coordinator = coordinator
    }
    
    func set(viewModel: MailboxViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Private constants
    
    private let kMailboxCellHeight: CGFloat           = 62.0 // change it to auto height
    private let kMailboxRateReviewCellHeight: CGFloat = 125.0
    private let kLongPressDuration: CFTimeInterval    = 0.60 // seconds
    private let kMoreOptionsViewHeight: CGFloat       = 123.0
    
    /// The undo related UI. //TODO:: should move to a custom view to handle it.
    @IBOutlet weak var undoView: UIView!
    @IBOutlet weak var undoLabel: UILabel!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var undoButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var undoBottomDistance: NSLayoutConstraint!
    
    /// no result label
    @IBOutlet weak var noResultLabel: UILabel!
    
    // MARK: TopMessage
    @available(*, deprecated)
    private weak var topMessageView: TopMessageView?
    
    // MARK: - Private attributes
    
    //TODO:: this need release the delegate after use
    private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    // this is for when user click the notification email
    private var messageID: String?
    private var listEditing: Bool = false
    private var selectedMessages: NSMutableSet = NSMutableSet()
    private var timer : Timer!
    private var timerAutoDismiss : Timer?
    
    private var fetching : Bool = false
    private var selectedDraft : Message!
    private var indexPathForSelectedRow : IndexPath!
    
    private var undoMessage : UndoMessage?
    
    private var isShowUndo : Bool = false
    private var isCheckingHuman: Bool = false
    
    private var fetchingMessage : Bool! = false
    private var fetchingStopped : Bool! = true
    private var needToShowNewMessage : Bool = false
    private var newMessageCount = 0
    
    private var ratingMessage : Message?
    
    // MAKR : - Private views
    private var refreshControl: UIRefreshControl!
    private var navigationTitleLabel = UILabel()
    
    // MARK: - Right bar buttons
    
    private var composeBarButtonItem: UIBarButtonItem!
    private var searchBarButtonItem: UIBarButtonItem!
    private var removeBarButtonItem: UIBarButtonItem!
    private var labelBarButtonItem: UIBarButtonItem!
    private var folderBarButtonItem: UIBarButtonItem!
    private var unreadBarButtonItem: UIBarButtonItem!
    private var moreBarButtonItem: UIBarButtonItem!
    
    // MARK: - Left bar button
    
    private var cancelBarButtonItem: UIBarButtonItem!
    private var menuBarButtonItem: UIBarButtonItem!
    
    // MARK: swipactions
    
    private var leftSwipeAction : MessageSwipeAction  = .archive
    private var rightSwipeAction : MessageSwipeAction = .trash

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
        
        self.noResultLabel.text = LocalString._messages_no_messages
        self.undoButton.setTitle(LocalString._messages_undo_action, for: .normal)
        self.setNavigationTitleText(viewModel.localizedNavigationTitle)
        self.tableView!.RegisterCell(MailboxMessageCell.Constant.identifier)
        self.tableView!.RegisterCell(MailboxRateReviewCell.Constant.identifier)
        
        self.setupFetchedResultsController()
        
        self.addSubViews()
        
        self.updateNavigationController(listEditing)
        
        if !userCachedStatus.isTourOk() {
            userCachedStatus.resetTourValue()
            //TODO::QA
            self.coordinator?.go(to: .onboarding)
        }
        
        self.undoBottomDistance.constant = -100
        self.undoButton.isHidden = true
        self.undoView.isHidden = true
        
        cleanRateReviewCell()
        
        
        self.leftSwipeAction = sharedUserDataService.swiftLeft
        self.rightSwipeAction = sharedUserDataService.swiftRight
    }
    
    deinit {
        resetFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideTopMessage()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MailboxViewController.reachabilityChanged(_:)),
                                               name: NSNotification.Name.reachabilityChanged,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(MailboxViewController.doEnterForeground),
                                               name:  UIApplication.willEnterForegroundNotification,
                                               object: nil)
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
        
        PushNotificationService.shared.processCachedLaunchOptions()
        
        let usedStorageSpace = sharedUserDataService.usedSpace
        let maxStorageSpace = sharedUserDataService.maxSpace
        StorageLimit().checkSpace(usedStorageSpace, maxSpace: maxStorageSpace)
        
        self.updateInterfaceWithReachability(sharedInternetReachability)
        //self.updateInterfaceWithReachability(sharedRemoteReachability)
        
        let selectedItem: IndexPath? = self.tableView.indexPathForSelectedRow as IndexPath?
        if let selectedItem = selectedItem {
            self.tableView.reloadRows(at: [selectedItem], with: UITableView.RowAnimation.fade)
            self.tableView.deselectRow(at: selectedItem, animated: true)
        }
        self.startAutoFetch()
        
        FileManager.default.cleanCachedAtts()
        
        if self.viewModel.notificationMessageID != nil {
            //TODO::QA
            self.coordinator?.go(to: .detailsFromNotify)
        } else {
            checkHuman()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    private func addSubViews() {
        self.navigationTitleLabel.backgroundColor = UIColor.clear
        self.navigationTitleLabel.font = Fonts.h2.regular
        self.navigationTitleLabel.textAlignment = NSTextAlignment.center
        self.navigationTitleLabel.textColor = UIColor.white
        self.navigationTitleLabel.text = self.title ?? LocalString._locations_inbox_title
        self.navigationTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationTitleLabel
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        self.refreshControl.addTarget(self, action: #selector(MailboxViewController.getLatestMessages), for: UIControl.Event.valueChanged)
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
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.tableView.reloadData()
    }
    
    
    // MARK: - Button Targets
    @objc internal func composeButtonTapped() {
        if checkHuman() {
            //TODO::QA
            self.coordinator?.go(to: .composer)
        }
    }
    @objc internal func searchButtonTapped() {
        //TODO::QA
        self.coordinator?.go(to: .search)
    }
    
    @objc internal func labelButtonTapped() {
        //TODO::QA
        self.coordinator?.go(to: .labels)
    }
    
    @objc internal func folderButtonTapped() {
        //TODO::QA
        self.coordinator?.go(to: .folder)
    }
    
    //TODO:: this is a global message should move it to the
    func performSegueForMessageFromNotification() {
        //TODO::QA
        self.coordinator?.go(to: .detailsFromNotify)
    }
    
    @objc internal func removeButtonTapped() {
        //TODO::QA
        if viewModel.isDelete() {
            moveMessagesToLocation(.trash)
            showMessageMoved(title: LocalString._messages_has_been_deleted)
        } else {
            moveMessagesToLocation(.trash)
            showMessageMoved(title: LocalString._messages_has_been_moved)
        }
        self.cancelButtonTapped();
    }
    
    @objc internal func favoriteButtonTapped() {
        selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.isStarred)
        cancelButtonTapped();
    }
    
    @objc internal func unreadButtonTapped() {
        selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.unRead)
        cancelButtonTapped();
    }
    
    @objc internal func moreButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        
        if viewModel.isShowEmptyFolder() {
            let locations: [ExclusiveLabel : UIAlertAction.Style] = [.inbox : .default]
            for (location, style) in locations {
                if !viewModel.isCurrentLocation(location) {
                    alertController.addAction(UIAlertAction(title: location.actionTitle, style: style, handler: { (action) -> Void in
                        self.moveMessagesToLocation(location)
                        self.cancelButtonTapped();
                        self.navigationController?.popViewController(animated: true)
                    }))
                }
            }
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Empty Folder",  comment: "Action"),
                                                    style: .destructive, handler: { (action) -> Void in
                                                        self.viewModel.emptyFolder()
                                                        self.showNoResultLabel()
                                                        self.navigationController?.popViewController(animated: true)
            }))
        } else {
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Mark Read",  comment: "Action"),
                                                    style: .default, handler: { (action) -> Void in
                self.selectedMessagesSetValue(setValue: false, forKey: Message.Attributes.unRead)
                self.cancelButtonTapped();
                self.navigationController?.popViewController(animated: true)
            }))
            
            alertController.addAction(UIAlertAction(title: LocalString._locations_add_star_action,
                                                    style: .default, handler: { (action) -> Void in
                self.selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.isStarred)
                self.selectedMessagesSetStar()
                self.cancelButtonTapped();
                self.navigationController?.popViewController(animated: true)
            }))
            
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Remove Star",  comment: "Action"),
                                                    style: .default, handler: { (action) -> Void in
                self.selectedMessagesSetValue(setValue: false, forKey: Message.Attributes.isStarred)
                self.selectedMessagesSetUnStar()
                self.cancelButtonTapped();
                self.navigationController?.popViewController(animated: true)
            }))
            
            var locations: [ExclusiveLabel : UIAlertAction.Style] = [.inbox : .default, .spam : .default, .archive : .default]
            if !viewModel.isCurrentLocation(.sent) {
                locations = [.spam : .default, .archive : .default]
            }

            if (viewModel.isCurrentLocation(.sent)) {
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
            context.perform {
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
    private func startAutoFetch(_ run : Bool = true) {
        self.timer = Timer.scheduledTimer(timeInterval: self.timerInterval,
                                          target: self,
                                          selector: #selector(MailboxViewController.refreshPage),
                                          userInfo: nil,
                                          repeats: true)
        fetchingStopped = false
        if run {
            self.timer.fire()
        }
    }
    
    private func stopAutoFetch() {
        fetchingStopped = true
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
    }
    
    @objc func refreshPage() {
        if !fetchingStopped {
            self.getLatestMessages()
        }
    }
    
    private func checkContact() {
        sharedContactDataService.fetchContacts { (_, _) in

        }
    }
    
    @discardableResult
    private func checkHuman() -> Bool {
        if sharedMessageQueue.isRequiredHumanCheck && isCheckingHuman == false {
            //show human check view with warning
            isCheckingHuman = true
            //TODO::QA
            self.coordinator?.go(to: .humanCheck)
            return false
        }
        return true
    }
    
    fileprivate var timerInterval : TimeInterval = 30
    fileprivate var failedTimes = 30
    
    func offlineTimerReset() {
        timerInterval = TimeInterval(arc4random_uniform(90)) + 30;
        stopAutoFetch()
        startAutoFetch(false)
    }
    
    func onlineTimerReset() {
        timerInterval = 30
        stopAutoFetch()
        startAutoFetch(false)
    }
    
    internal func messageAtIndexPath(_ indexPath: IndexPath) -> Message? {
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
    
    private func configureCell(_ mailboxCell: MailboxMessageCell, atIndexPath indexPath: IndexPath) {
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
                mailboxCell.setSwipeGestureWith(leftCrossView, color: leftSwipeAction.actionColor, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state1 ) { [weak self] (cell, state, mode) -> Void in
                    guard let `self` = self else { return }
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
                mailboxCell.setSwipeGestureWith(rightCrossView, color: rightSwipeAction.actionColor, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state3  ) { [weak self] (cell, state, mode) -> Void in
                    guard let `self` = self else { return }
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
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: action.description)
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
        case .unread:
            self.unreadMessageForIndexPath(indexPath)
            return false
        }
    }
    
    fileprivate func archiveMessageForIndexPath(_ indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            //TODO::fixme
//            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
//            let res = viewModel.archiveMessage(message)
//            switch res {
//            case .showUndo:
//                showUndoView(LocalString._messages_archived)
//            case .showGeneral:
//                showMessageMoved(title: LocalString._messages_has_been_moved)
//            default: break
//            }
        }
    }
    
    fileprivate func deleteMessageForIndexPath(_ indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            //TODO::fixme
//            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
//            let res = viewModel.deleteMessage(message)
//            switch res {
//            case .showUndo:
//                showUndoView(LocalString._locations_deleted_desc)
//            case .showGeneral:
//                showMessageMoved(title: LocalString._messages_has_been_deleted)
//            default: break
//            }
        }
    }
    
    fileprivate func spamMessageForIndexPath(_ indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            //TODO::fixme
//            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
//            let res = viewModel.spamMessage(message)
//            switch res {
//            case .showUndo:
//                showUndoView(LocalString._messages_spammed)
//            case .showGeneral:
//                showMessageMoved(title: LocalString._messages_has_been_moved)
//            default: break
//            }
        }
    }
    
    fileprivate func starMessageForIndexPath(_ indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            //TODO::fixme
//            undoMessage = UndoMessage(msgID: message.messageID, oldLocation: message.location)
//            let _ = viewModel.starMessage(message)
        }
    }
    
    fileprivate func unreadMessageForIndexPath(_ indexPath: IndexPath) {
        if let message = self.messageAtIndexPath(indexPath) {
            let _ = viewModel.unreadMessage(message)
        }
    }
    
    fileprivate func undoTheMessage() { //need move into viewModel
        if let undoMsg = undoMessage {
            //TODO::fixme
//            if let context = fetchedResultsController?.managedObjectContext {
//                if let message = Message.messageForMessageID(undoMsg.messageID, inManagedObjectContext: context) {
//                    self.viewModel.updateBadgeNumberWhenMove(message, to: undoMsg.oldLocation)
//                    message.removeLocationFromLabels(currentlocation: message.location, location: undoMsg.oldLocation, keepSent: true)
//                    message.needsUpdate = true
//                    message.location = undoMsg.oldLocation
//                    if let error = context.saveUpstreamIfNeeded() {
//                        PMLog.D("error: \(error)")
//                    }
//                }
//            }
//            undoMessage = nil
        }
    }
    
    fileprivate func showUndoView(_ title : String) {
        undoLabel.text = String(format: LocalString._messages_with_title, title)
        self.undoBottomDistance.constant = 44
        self.undoButton.isHidden = false
        self.undoView.isHidden = false
        self.undoButtonWidth.constant = 100.0
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.timerAutoDismiss = Timer.scheduledTimer(timeInterval: 3,
                                                     target: self,
                                                     selector: #selector(MailboxViewController.timerTriggered),
                                                     userInfo: nil,
                                                     repeats: false)
    }
    
    fileprivate func showMessageMoved(title : String) {
        undoLabel.text = title
        self.undoBottomDistance.constant = 44
        self.undoButton.isHidden = false
        self.undoView.isHidden = false
        self.undoButtonWidth.constant = 0.0
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.timerAutoDismiss = Timer.scheduledTimer(timeInterval: 3,
                                                     target: self,
                                                     selector: #selector(MailboxViewController.timerTriggered),
                                                     userInfo: nil,
                                                     repeats: false)
    }
    
    fileprivate func hideUndoView() {
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.undoBottomDistance.constant = -100
        self.updateViewConstraints()
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            self.undoButton.isHidden = true
            self.undoView.isHidden = true
        }
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
    
    
    /// TODO:: need refactor this function
    ///
    /// - Parameter indexPath: <#indexPath description#>
    fileprivate func fetchMessagesIfNeededForIndexPath(_ indexPath: IndexPath) {
        // This thing hangs app with big cache when used with batch fetches
        
        if let fetchedResultsController = fetchedResultsController {
            let lastIndex = fetchedResultsController.numberOfRows(in: indexPath.section)
                if let current = self.messageAtIndexPath(indexPath) {
                    let updateTime = viewModel.lastUpdateTime()
                    if let currentTime = current.time {
                        let isOlderMessage = updateTime.end.compare(currentTime as Date) != ComparisonResult.orderedAscending
                        let isLastMessage = (lastIndex == indexPath.row)
                        if  (isOlderMessage || isLastMessage) && !fetching {
                            let sectionCount = fetchedResultsController.numberOfRows(in: 0)
                            let recordedCount = Int(updateTime.total)
                            if updateTime.isNew || recordedCount > sectionCount { //here need add a counter to check if tried too many times make one real call in case count not right
                                self.fetching = true
                                tableView.showLoadingFooter()
                                let updateTime = viewModel.lastUpdateTime()
                                let unixTimt:Int = (updateTime.end as Date == Date.distantPast ) ? 0 : Int(updateTime.end.timeIntervalSince1970)
                                viewModel.fetchMessages(time: unixTimt, foucsClean: false, completion: { (task, response, error) -> Void in
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
                        viewModel.fetchMessages(time: 0, foucsClean: false, completion: { (task, messages, error) -> Void in
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
                    
                    if loadMore <= 0 {
                        sharedMessageDataService.updateMessageCount()
                    }
                }
                
                if loadMore > 0 {
                     self.retry()
                } else {
                    delay(0.1, closure: {
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
                    viewModel.fetchMessageWithReset(time: 0, completion: complete)
                }
                else {
                    viewModel.fetchMessages(time: 0, foucsClean: false, completion: complete)
                }
            } else {
                //fetch
                self.needToShowNewMessage = true
                viewModel.fetchEvents(time: Int(updateTime.start.timeIntervalSince1970),
                                      notificationMessageID: self.viewModel.notificationMessageID,
                                      completion: complete)
                self.checkEmptyMailbox()
            }
            
            self.checkContact()
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
    
    //TODO::fixme
   fileprivate func moveMessagesToLocation(_ location: ExclusiveLabel) {
//        if let context = fetchedResultsController?.managedObjectContext {
//            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
//            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, self.selectedMessages)
//            do {
//                if let messages = try context.fetch(fetchRequest) as? [Message] {
//                    for message in messages {
//                        var toLocation = location
//                        if location == .inbox {
//                            if message.hasLocation(location: .outbox)  {
//                                toLocation = .outbox
//                            }
//                            if message.hasLocation(location: .draft) {
//                                toLocation = .draft
//                            }
//                        }
//
//                        var fromLocation = message.location
//                        if let floc = self.viewModel.currentLocation() {
//                            fromLocation = floc
//                        }
//
//                        message.removeLocationFromLabels(currentlocation: fromLocation,
//                                                         location: toLocation,
//                                                         keepSent: true);
//                        message.needsUpdate = true
//                        message.location = toLocation
//                        if let error = context.saveUpstreamIfNeeded() {
//                            PMLog.D("error: \(error)")
//                        }
//                    }
//
//                }
//            } catch let ex as NSError {
    //                PMLog.D(" error: \(ex)")
    //            }
    //
    //        }
    }
    
    internal func tappedMassage(_ message: Message) {
        guard viewModel.isDrafts() || message.draft else {
            self.coordinator?.go(to: .details)
            return
        }

        guard !message.messageID.isEmpty else {
            if self.checkHuman() {
                //TODO::QA
                self.coordinator?.go(to: .composeShow)
            }
            return
        }

        sharedMessageDataService.ForcefetchDetailForMessage(message) {_, _, msg, error in
            guard let objectId = msg?.objectID,
                let message = self.fetchedResultsController?.managedObjectContext.object(with: objectId) as? Message,
                message.body.isEmpty == false else
            {
                if error != nil {
                    PMLog.D("error: \(String(describing: error))")
                    let alert = LocalString._unable_to_edit_offline.alertController()
                    alert.addOKAction()
                    self.present(alert, animated: true, completion: nil)
                    self.tableView.indexPathsForSelectedRows?.forEach {
                        self.tableView.deselectRow(at: $0, animated: true)
                    }
                }
                return
            }

            self.selectedDraft = msg
            if self.checkHuman() {
                //TODO::QA
                self.coordinator?.go(to: .composeShow)
            }
        }
    }
    
    fileprivate func selectMessageIDIfNeeded() {
        if messageID != nil {
            if let messages = fetchedResultsController?.fetchedObjects as? [Message] {
                if let message = messages.filter({ $0.messageID == self.messageID }).first {
                    if let indexPath = fetchedResultsController?.indexPath(forObject: message) {
                        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
                    }
                    self.tappedMassage(message)
                    messageID = nil
                }
            }
        }
        performSegueForMessage(message)
        self.messageID = nil
    }
    
    fileprivate func selectedMessagesSetValue(setValue value: Any?, forKey key: String) {
        if let context = fetchedResultsController?.managedObjectContext {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
            fetchRequest.predicate = NSPredicate(format: "%K in %@", Message.Attributes.messageID, self.selectedMessages)
            
            do {
                if let messages = try context.fetch(fetchRequest) as? [Message] {
                    if key == Message.Attributes.unRead {
                        if let changeto = value as? Bool {
                            for msg in messages {
                                self.viewModel.updateBadgeNumberWhenRead(msg, unRead: changeto)
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
                //TODO::fixme
//                if let messages = try context.fetch(fetchRequest) as? [Message] {
//                    for msg in messages {
//                        msg.setLabelLocation(.starred);
//                    }
//                    let error = context.saveUpstreamIfNeeded()
//                    if let error = error {
//                        PMLog.D(" error: \(error)")
//                    }
//                }
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
                //TODO::fixme
//                if let messages = try context.fetch(fetchRequest) as? [Message] {
//                    for msg in messages {
//                        msg.removeLocationFromLabels(currentlocation: .starred, location: .deleted, keepSent: true);
//                    }
//                    let error = context.saveUpstreamIfNeeded()
//                    if let error = error {
//                        PMLog.D(" error: \(error)")
//                    }
//                }
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
                self.cancelBarButtonItem = UIBarButtonItem(title: LocalString._general_cancel_button,
                                                           style: UIBarButtonItem.Style.plain,
                                                           target: self,
                                                           action: #selector(MailboxViewController.cancelButtonTapped))
            }
            
            leftButtons = [self.cancelBarButtonItem]
        }
        
        self.navigationItem.setLeftBarButtonItems(leftButtons, animated: true)
    }
    
    private func setupNavigationTitle(_ editingMode: Bool) {
        if (editingMode) {
            self.setNavigationTitleText("")
        } else {
            self.setNavigationTitleText(viewModel.localizedNavigationTitle)
        }
    }
    
    private func BarItem(image: UIImage?, action: Selector? ) -> UIBarButtonItem {
       return  UIBarButtonItem(image: image, style: UIBarButtonItem.Style.plain, target: self, action: action)
    }
    
    private func setupRightButtons(_ editingMode: Bool) {
        var rightButtons: [UIBarButtonItem]
        
        if (!editingMode) {
            if (self.composeBarButtonItem == nil) {
                self.composeBarButtonItem = BarItem(image: UIImage.Top.compose, action: #selector(composeButtonTapped))
            }
            
            if (self.searchBarButtonItem == nil) {
                self.searchBarButtonItem = BarItem(image: UIImage.Top.search, action: #selector(searchButtonTapped))
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = BarItem(image: UIImage.Top.more, action: #selector(moreButtonTapped))
            }
            
            if viewModel.isShowEmptyFolder() {
                rightButtons = [self.moreBarButtonItem, self.composeBarButtonItem, self.searchBarButtonItem]
            } else {
                rightButtons = [self.composeBarButtonItem, self.searchBarButtonItem]
            }
        } else {
            if (self.unreadBarButtonItem == nil) {
                self.unreadBarButtonItem = BarItem(image: UIImage.Top.unread, action: #selector(unreadButtonTapped))
            }
            
            if (self.labelBarButtonItem == nil) {
                self.labelBarButtonItem = BarItem(image: UIImage.Top.label, action: #selector(labelButtonTapped))
            }
            
            if (self.folderBarButtonItem == nil) {
                self.folderBarButtonItem = BarItem(image: UIImage.Top.folder, action: #selector(folderButtonTapped))
            }
            
            if (self.removeBarButtonItem == nil) {
                self.removeBarButtonItem = BarItem(image: UIImage.Top.trash, action: #selector(removeButtonTapped))
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = BarItem(image: UIImage.Top.more, action: #selector(moreButtonTapped))
            }
            
            if (viewModel.isDrafts()) {
                rightButtons = [self.removeBarButtonItem]
            } else if (viewModel.isCurrentLocation(.sent)) {
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
            if (longPressGestureRecognizer.state == UIGestureRecognizer.State.began) {
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
        animation.type = CATransitionType.fade
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
            showMessageMoved(title: LocalString._messages_labels_applied)
        } else if type == .folder {
            showMessageMoved(title: LocalString._messages_has_been_moved)
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
    
    private func showBanner(_ message: String,
                            appearance: TopMessageView.Appearance,
                            buttons: Set<TopMessageView.Buttons> = [])
    {
        if let oldMessageView = self.topMessageView {
            oldMessageView.remove(animated: true)
        }
        
        let newMessageView = TopMessageView(appearance: appearance,
                                            message: message,
                                            buttons: buttons,
                                            lowerPoint: self.navigationController!.navigationBar.frame.size.height + self.self.navigationController!.navigationBar.frame.origin.y + 8.0)
        newMessageView.delegate = self
        if let superview = self.navigationController?.view {
            self.topMessageView = newMessageView
            superview.insertSubview(newMessageView, belowSubview: self.navigationController!.navigationBar)
            newMessageView.showAnimation(withSuperView: superview)
        }
    }
    
    internal func showErrorMessage(_ error: NSError?) {
        guard let error = error else { return }
        showBanner(error.localizedDescription, appearance: .red)
    }
    
    internal func showTimeOutErrorMessage() {
        showBanner(LocalString._general_request_timed_out, appearance: .red, buttons: [.close])
    }
    
    internal func showNoInternetErrorMessage() {
        showBanner(LocalString._general_no_connectivity_detected, appearance: .red, buttons: [.close])
    }
    
    internal func showOfflineErrorMessage(_ error : NSError?) {
        showBanner(error?.localizedDescription ?? LocalString._general_pm_offline, appearance: .red, buttons: [.close])
    }
    
    internal func show503ErrorMessage(_ error : NSError?) {
        showBanner(LocalString._general_api_server_not_reachable, appearance: .red, buttons: [.close])
    }
    
    
    internal func showNewMessageCount(_ count : Int) {
        guard self.needToShowNewMessage, count > 0 else { return }
        self.needToShowNewMessage = false
        self.newMessageCount = 0
        let message = count == 1 ? LocalString._messages_you_have_new_email : String(format: LocalString._messages_you_have_new_emails_with, count)
        message.alertToastBottom()
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
        switch (netStatus){
        case .NotReachable:
            PMLog.D("Access Not Available")
            self.showNoInternetErrorMessage()
            
        case .ReachableViaWWAN:
            PMLog.D("Reachable WWAN")
            self.hideTopMessage()

        case .ReachableViaWiFi:
            PMLog.D("Reachable WiFi")
            self.hideTopMessage()

        default:
            PMLog.D("Reachable default unknow")
        }
    }
    
    func hideTopMessage() {
        self.topMessageView?.remove(animated: true)
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
        self.coordinator?.go(to: .feedbackView)
    }
    
    func showSupport() {
        self.coordinator?.go(to: .feedbackView)
    }
    
    func showRating() {
        self.coordinator?.go(to: .feedbackView)
    }
    
}

// MARK : review delegate
extension MailboxViewController: MailboxRateReviewCellDelegate {
    func mailboxRateReviewCell(_ cell: UITableViewCell, yesORno: Bool) {
        cleanRateReviewCell()
        
        // go to next screen
        if yesORno == true {
            //TODO::QA
            self.coordinator?.go(to: .feedback)
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = fetchedResultsController?.numberOfRows(in: section) ?? 0
        return count
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
        switch(type) {
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            }
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: UITableView.RowAnimation.fade)
                if self.needToShowNewMessage == true {
                    if let newMsg = anObject as? Message {
                        if let msgTime = newMsg.time, newMsg.unRead {
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

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.zeroMargin()
        self.fetchMessagesIfNeededForIndexPath(indexPath)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let rIndex = self.getRatingIndex() {
            if rIndex == indexPath {
                return kMailboxRateReviewCellHeight
            }
        }
        return kMailboxCellHeight

    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let rIndex = self.getRatingIndex() {
            if rIndex == indexPath {
                return nil
            }
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
                self.tappedMassage(message)
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
