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
    
    private let kMailboxCellHeight: CGFloat = 64.0
    private let kCellIdentifier: String = "MailboxCell"
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds
    private let kSegueToCompose = "toCompose"
    private let kSegueToComposeShow = "toComposeShow"
    private let kSegueToSearchController: String = "toSearchViewController"
    private let kSegueToMessageDetailController: String = "toMessageDetailViewController"
    private let kMoreOptionsViewHeight: CGFloat = 123.0
    
    
    // MARK: - Private attributes
    
    internal var refreshControl: UIRefreshControl!
    internal var mailboxLocation: MessageLocation! = .inbox
    internal var messageID: String?
    
    private var fetchedResultsController: NSFetchedResultsController?
    private var moreOptionsView: MoreOptionsView!
    private var navigationTitleLabel = UILabel()
    private var pagingManager = PagingManager()
    private var selectedMessages: NSMutableSet = NSMutableSet()
    private var isEditing: Bool = false
    private var isViewingMoreOptions: Bool = false
    private var timer : NSTimer!
    
    
    private var selectedDraft : Message!
    private var indexPathForSelectedRow : NSIndexPath!
    
    
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
        setupFetchedResultsController()
        addSubViews()
        addConstraints()
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
        
        self.refreshControl.tintColor = UIColor.whiteColor()
        self.refreshControl.tintColorDidChange()
    
        let usedStorageSpace = sharedUserDataService.userInfo!.usedSpace
        let maxStorageSpace = sharedUserDataService.userInfo!.maxSpace
        StorageLimit().checkSpace(usedSpace: usedStorageSpace, maxSpace: maxStorageSpace)
    }
    
    private func addSubViews() {
        self.moreOptionsView = MoreOptionsView()
        self.moreOptionsView.delegate = self
        self.view.addSubview(self.moreOptionsView)
        
        self.navigationTitleLabel.backgroundColor = UIColor.clearColor()
        self.navigationTitleLabel.font = UIFont.robotoLight(size: UIFont.Size.h2)
        self.navigationTitleLabel.textAlignment = NSTextAlignment.Center
        self.navigationTitleLabel.textColor = UIColor.whiteColor()
        self.navigationTitleLabel.text = self.title ?? NSLocalizedString("INBOX")
        self.navigationTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationTitleLabel
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = UIColor.ProtonMail.Blue_475F77
        self.refreshControl.addTarget(self, action: "getLatestMessages", forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl.tintColor = UIColor.whiteColor()
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
        self.moreOptionsView.mas_makeConstraints { (make) -> Void in
            make.left.equalTo()(self.view)
            make.right.equalTo()(self.view)
            make.height.equalTo()(self.kMoreOptionsViewHeight)
            make.bottom.equalTo()(self.view.mas_top)
        }
    }
    
    // MARK: - Prepare for segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == kSegueToMessageDetailController) {
            self.cancelButtonTapped()
            
            let messageDetailViewController: MessageDetailViewController = segue.destinationViewController as! MessageDetailViewController
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

            let composeViewController: ComposeViewController = segue.destinationViewController as! ComposeViewController
            //let indexPathForSelectedRow = self.tableView.indexPathForSelectedRow()
            if let indexPathForSelectedRow = indexPathForSelectedRow {
                if let message = fetchedResultsController?.objectAtIndexPath(indexPathForSelectedRow) as? Message {
                    composeViewController.viewModel = ComposeViewModelImpl(msg: message, action : ComposeMessageAction.Draft)
                }
                else
                {
                    println("No selected row.")
                }
            } else {
                println("No selected row.")
            }
        } else if segue.identifier == kSegueToCompose {
            let composeViewController: ComposeViewController = segue.destinationViewController.viewControllers![0] as! ComposeViewController
            composeViewController.viewModel = ComposeViewModelImpl(msg: nil, action: ComposeMessageAction.Draft)
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
        moveMessagesToLocation(.trash)
    }
    
    internal func favoriteButtonTapped() {
        selectedMessagesSetValue(setValue: true, forKey: Message.Attributes.isStarred)
    }
    
    internal func moreButtonTapped() {
        self.view.bringSubviewToFront(self.moreOptionsView)
        //TODO:: need monitor here
        let topLayoutGuide: UIView = self.topLayoutGuide as! UIView
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
    
    internal func handleLongPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        showCheckOptions(longPressGestureRecognizer)
        updateNavigationController(isEditing)
    }
    
    
    // MARK: - Private methods
    private func startAutoFetch()
    {
        self.timer = NSTimer.scheduledTimerWithTimeInterval(120, target: self, selector: "refreshPage", userInfo: nil, repeats: true)
        self.timer.fire()
    }
    
    private func stopAutoFetch()
    {
        self.timer.invalidate()
        self.timer = nil
    }
    
    func refreshPage()
    {
        getLatestMessages()
    }
    
    private func configureCell(mailboxCell: MailboxTableViewCell, atIndexPath indexPath: NSIndexPath) {
        if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
            mailboxCell.configureCell(message)
            mailboxCell.setCellIsChecked(selectedMessages.containsObject(message.messageID))
            
            if (self.isEditing) {
                mailboxCell.showCheckboxOnLeftSide()
            }
            else
            {
                mailboxCell.hideCheckboxOnLeftSide()
            }
        }
    }
    
    private func deleteMessageForIndexPath(indexPath: NSIndexPath) {
        if let message = fetchedResultsController?.objectAtIndexPath(indexPath) as? Message {
            
            switch(mailboxLocation!) {
            case .trash, .spam:
                message.location = .deleted
            default:
                message.location = .trash
            }
            
            if let error = message.managedObjectContext?.saveUpstreamIfNeeded() {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
    }
    
    private func setupFetchedResultsController() {
        self.fetchedResultsController = sharedMessageDataService.fetchedResultsControllerForLocation(self.mailboxLocation)
        self.fetchedResultsController?.delegate = self
        
        NSLog("\(__FUNCTION__) INFO: \(fetchedResultsController?.sections)")
        
        if let fetchedResultsController = fetchedResultsController {
            var error: NSError?
            if !fetchedResultsController.performFetch(&error) {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
    }
    
    private func fetchMessagesIfNeededForIndexPath(indexPath: NSIndexPath) {
        if !pagingManager.hasMorePages {
            return
        }
        
        if let fetchedResultsController = fetchedResultsController {
            if let last = fetchedResultsController.fetchedObjects?.last as? Message {
                if let current = fetchedResultsController.objectAtIndexPath(indexPath) as? Message {
                    if last == current {
                        if !pagingManager.hasMorePages {
                            return
                        }
                        
                        let sectionCount = fetchedResultsController.numberOfRowsInSection(0) ?? 0
                        if(sectionCount > 8)
                        {
                            tableView.showLoadingFooter()
                        }
                        
                        sharedMessageDataService.fetchMessagesForLocation(mailboxLocation, MessageID: last.messageID ?? "0", Time:Int( last.time?.timeIntervalSince1970 ?? 0), completion:
                            { (task, messages, error) -> Void in
                                self.tableView.hideLoadingFooter()
                                
                                if error != nil {
                                    NSLog("\(__FUNCTION__) search error: \(error)")
                                } else {
                                    self.pagingManager.resultCount(messages?.count ?? 0)
                                }
                        })
                    }
                }
            }
        }
    }
    
    internal func getLatestMessages() {
        pagingManager.reset()
        
        self.refreshControl.beginRefreshing()
        
        sharedMessageDataService.fetchLatestMessagesForLocation(self.mailboxLocation) { _, messages, error in
            if let error = error {
                NSLog("error: \(error)")
            }
            
            self.pagingManager.reset()
            delay(1.0, {
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            })
        }
        
        if let fetchedResultsController = fetchedResultsController {
            if let first = fetchedResultsController.fetchedObjects?.first as? Message {
                sharedMessageDataService.fetchNewMessagesForLocation(mailboxLocation, MessageID: first.messageID ?? "0", Time:Int( first.time?.timeIntervalSince1970 ?? 0), completion:
                    { (task, messages, error) -> Void in
                        if let error = error {
                            NSLog("error: \(error)")
                        }
                        
                        self.pagingManager.reset()
                        delay(1.0, {
                            self.refreshControl.endRefreshing()
                            self.tableView.reloadData()
                        })
                })
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
                }
                error = context.saveUpstreamIfNeeded()
            }
            
            if let error = error {
                NSLog("\(__FUNCTION__) error: \(error)")
            }
        }
    }
    
    private func performSegueForMessage(message: Message) {
        if isDrafts() {
            sharedMessageDataService.fetchMessageDetailForMessage(message) {_, _, msg, error in
                if error != nil {
                    NSLog("\(__FUNCTION__) error: \(error)")
                }
                else
                {
                    self.selectedDraft = msg
                   // delay(1.0, {
                       self.performSegueWithIdentifier(self.kSegueToComposeShow, sender: self)
                  //  })
                    
                }
            }
            //message.fetchDetailIfNeeded()
//            message.fetchDetailIfNeeded() { _, _, msg, error in
//                println(self.message.isDetailDownloaded)
//                
//                if error != nil {
//                    NSLog("\(__FUNCTION__) error: \(error)")
//                }
//                else
//                {
//                    if !self.message.isDetailDownloaded
//                    {
//                        // println(msg?.isDetailDownloaded)
//                        if let fetchedMessageController = self.fetchedMessageController {
//                            println( fetchedMessageController.fetchedObjects?.count)
//                            if let last = fetchedMessageController.fetchedObjects?.last as? Message {
//                                println(last.isDetailDownloaded)
//                                self.message = last
//                                self.messageDetailView.message = self.message
//                            }
//                            else
//                            {
//                                self.setupFetchedResultsController(self.message.messageID)
//                                if let fetchedMessageController = self.fetchedMessageController {
//                                    println( fetchedMessageController.fetchedObjects?.count)
//                                    if let last = fetchedMessageController.fetchedObjects?.last as? Message {
//                                        println(last.isDetailDownloaded)
//                                        self.message = last
//                                        self.messageDetailView.message = self.message
//                                    }
//                                }
//                                
//                            }
//                        }
//                    }
//                }

            
            
            
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
            
            if (isDrafts()) {
                rightButtons = [self.removeBarButtonItem]
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
    
    private func isDrafts() -> Bool {
        return self.mailboxLocation == MessageLocation.draft
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


// MARK: - MoreOptionsViewDelegate

extension MailboxViewController: MoreOptionsViewDelegate {
    private func hideMoreButtonIfNeeded() {
        if isViewingMoreOptions {
            moreButtonTapped()
        }
    }
    
    func moreOptionsViewDidMarkAsUnread(moreOptionsView: MoreOptionsView) {
        selectedMessagesSetValue(setValue: false, forKey: Message.Attributes.isRead)
        hideMoreButtonIfNeeded()
    }
    
    func moreOptionsViewDidSelectMoveTo(moreOptionsView: MoreOptionsView) {
        let alertController = UIAlertController(title: NSLocalizedString("Move to..."), message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Cancel, handler: nil))
        
        let locations: [MessageLocation : UIAlertActionStyle] = [.inbox : .Default, .spam : .Default, .trash : .Destructive]
        
        for (location, style) in locations {
            if mailboxLocation != location {
                alertController.addAction(UIAlertAction(title: location.description, style: style, handler: { (action) -> Void in
                    self.moveMessagesToLocation(location)
                    
                    self.navigationController?.popViewControllerAnimated(true)
                }))
            }
        }
        
        presentViewController(alertController, animated: true, completion: nil)
        hideMoreButtonIfNeeded()
    }
}

// MARK: - UITableViewDataSource

extension MailboxViewController: UITableViewDataSource {
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
        return fetchedResultsController?.numberOfSections() ?? 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var mailboxCell = tableView.dequeueReusableCellWithIdentifier(kCellIdentifier, forIndexPath: indexPath) as! MailboxTableViewCell
        mailboxCell.delegate = self
        
        configureCell(mailboxCell, atIndexPath: indexPath)
        
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
        let trashed: UITableViewRowAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Trash") { (rowAction, indexPath) -> Void in
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
