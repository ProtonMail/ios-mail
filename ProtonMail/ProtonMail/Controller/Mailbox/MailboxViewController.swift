//
//  MailboxViewController.swift
//  ProtonMail - Created on 8/16/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit
import CoreData
import MCSwipeTableViewCell
import PMCommon

class MailboxViewController: ProtonMailViewController, ViewModelProtocol, CoordinatedNew {
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
    
    private let kUndoHidePosition: CGFloat = -100.0
    private let kUndoShowPosition: CGFloat = 44
    
    /// The undo related UI. //TODO:: should move to a custom view to handle it.
    @IBOutlet weak var undoView: UIView!
    @IBOutlet weak var undoLabel: UILabel!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var undoButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var undoBottomDistance: NSLayoutConstraint!
    
    /// no result label
    @IBOutlet weak var noResultLabel: UILabel!
    
    // MARK: TopMessage
    private weak var topMessageView: BannerView?
    
    // MARK: - Private attributes
    private lazy var replacingEmails: [Email] = { [unowned self] in
        viewModel.allEmails()
    }()
    private var listEditing: Bool = false
    private var timer : Timer!
    private var timerAutoDismiss : Timer?
    
    private var fetchingNewer : Bool = false
    private var fetchingOlder : Bool = false
    private var indexPathForSelectedRow : IndexPath!
    
    private var undoMessage : UndoMessage?
    
    private var isShowUndo : Bool = false
    private var isCheckingHuman: Bool = false
    
    private var fetchingMessage : Bool! = false
    private var fetchingStopped : Bool! = true
    private var needToShowNewMessage : Bool = false
    private var newMessageCount = 0
    
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
    private var swipeLeftToRightAction : MessageSwipeAction {
        return self.viewModel.user.userInfo.swipeLeftAction
    }
    private var swipeRightToLeftAction : MessageSwipeAction {
        return self.viewModel.user.userInfo.swipeRightAction
    }
    
    private var lastNetworkStatus : NetworkStatus? = nil
    
    ///
    var selectedIDs: NSMutableSet = NSMutableSet()

    ///
    func inactiveViewModel() {
        guard self.viewModel != nil else {
            return
        }
        self.viewModel.resetFetchedController()
    }
    
    deinit {
        self.viewModel?.resetFetchedController()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func doEnterForeground() {
        if viewModel.reloadTable() {
            resetTableView()
        }
    }
    
    func resetTableView() {
        self.viewModel.resetFetchedController()
        self.viewModel.setupFetchController(self)
        self.tableView.reloadData()
    }
    
    // MARK: - UIViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.viewModel != nil)
        assert(self.coordinator != nil)

        self.viewModel.setupFetchController(self)
        
        self.noResultLabel.text = LocalString._messages_no_messages
        self.undoButton.setTitle(LocalString._messages_undo_action, for: .normal)
        self.setNavigationTitleText(viewModel.localizedNavigationTitle)
        self.tableView.RegisterCell(MailboxMessageCell.Constant.identifier)
        self.tableView.RegisterCell(MailboxRateReviewCell.Constant.identifier)
        
        self.addSubViews()

        self.updateNavigationController(listEditing)
        
        if !userCachedStatus.isTourOk() {
            userCachedStatus.resetTourValue()
            self.coordinator?.go(to: .onboarding)
        }
        
        self.undoBottomDistance.constant = self.kUndoHidePosition
        self.undoButton.isHidden = true
        self.undoView.isHidden = true
        
        self.viewModel.cleanReviewItems()
        generateAccessibilityIdentifiers()
        
        //Do not fetch message when first logged in
        //if viewModel.isEventIDValid() {
        //  self.fetchNewMessage()
        //}
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.hideTopMessage()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChanged(_:)),
                                               name: NSNotification.Name.reachabilityChanged,
                                               object: nil)
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self,
                                                   selector:#selector(doEnterForeground),
                                                   name:  UIWindowScene.willEnterForegroundNotification,
                                                   object: nil)
        } else {
            NotificationCenter.default.addObserver(self,
                                                    selector:#selector(doEnterForeground),
                                                    name: UIApplication.willEnterForegroundNotification,
                                                    object: nil)
        }
    }
    
    @IBAction func undoAction(_ sender: UIButton) {
        self.undoTheMessage()
        self.hideUndoView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideTopMessage()
        NotificationCenter.default.removeObserver(self)
        self.stopAutoFetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            self.view.window?.windowScene?.title = self.title ?? LocalString._locations_inbox_title
        }
        
        guard let users = self.viewModel.users, users.count > 0 else {
            return
        }
        
        self.viewModel.processCachedPush()
        self.viewModel.checkStorageIsCloseLimit()
        
        self.updateInterfaceWithReachability(sharedInternetReachability)
        
        let selectedItem: IndexPath? = self.tableView.indexPathForSelectedRow as IndexPath?
        if let selectedItem = selectedItem {
            if self.viewModel.isDrafts() {
                // updated draft should either be deleted or moved to top, so all the rows in between should be moved 1 position down
                let rowsToMove = (0...selectedItem.row).map{ IndexPath(row: $0, section: 0) }
                self.tableView.reloadRows(at: rowsToMove, with: .top)
            } else {
                self.tableView.reloadRows(at: [selectedItem], with: .fade)
                self.tableView.deselectRow(at: selectedItem, animated: true)
            }
        }
        
        self.startAutoFetch()
        
        FileManager.default.cleanCachedAttsLegacy()
        
        if self.viewModel.notificationMessageID != nil {
            self.coordinator?.go(to: .detailsFromNotify)
        } else if checkHuman() {
            self.handleUpdateAlert()
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
        self.refreshControl.backgroundColor = .clear
        self.refreshControl.addTarget(self, action: #selector(pullDown), for: UIControl.Event.valueChanged)
        self.refreshControl.tintColor = UIColor.gray
        self.refreshControl.tintColorDidChange()
        
        self.tableView.addSubview(self.refreshControl)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.noSeparatorsBelowFooter()
        
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
        
        self.menuBarButtonItem = self.navigationItem.leftBarButtonItem
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
    
    func showNoEmailSelected(title: String) {
        let alert = UIAlertController(title: title, message: LocalString._message_list_no_email_selected, preferredStyle: .alert)
        alert.addOKAction()
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Button Targets
    @objc internal func composeButtonTapped() {
        if checkHuman() {
            self.coordinator?.go(to: .composer)
        }
    }
    @objc internal func searchButtonTapped() {
        self.coordinator?.go(to: .search)
    }
    @objc internal func labelButtonTapped() {
        self.removePresentedViewController()
        guard !self.selectedIDs.isEmpty else {
            showNoEmailSelected(title: LocalString._apply_labels)
            return
        }
        self.coordinator?.go(to: .labels, sender: self.viewModel.selectedMessages(selected: self.selectedIDs))
    }
    
    @objc internal func folderButtonTapped() {
        self.removePresentedViewController()
        guard !self.selectedIDs.isEmpty else {
            showNoEmailSelected(title: LocalString._labels_move_to_folder)
            return
        }
        self.coordinator?.go(to: .folder, sender: self.viewModel.selectedMessages(selected: self.selectedIDs))
    }
    
    /// unread tapped, this is the button in navigation bar 
    @objc internal func unreadTapped() {
        self.removePresentedViewController()
        self.viewModel.mark(IDs: self.selectedIDs, unread: true)
        cancelButtonTapped()
    }
    
    /// remove button tapped. in the navigation bar
    @objc internal func removeButtonTapped() {
        self.removePresentedViewController()
        guard !self.selectedIDs.isEmpty else {
            showNoEmailSelected(title: LocalString._warning)
            return
        }
        if viewModel.isDelete() {
            let alert = UIAlertController(title: LocalString._warning, message: LocalString._messages_will_be_removed_irreversibly, preferredStyle: .alert)
            let yes = UIAlertAction(title: LocalString._general_delete_action, style: .destructive) { [unowned self] _ in
                self.viewModel.delete(IDs: self.selectedIDs)
                self.showMessageMoved(title: LocalString._messages_has_been_deleted)
                self.cancelButtonTapped()
            }
            let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel) { [unowned self] _ in
                self.cancelButtonTapped()
            }
            [yes, cancel].forEach(alert.addAction)
            
            self.present(alert, animated: true, completion: nil)
        } else {
            moveMessages(to: .trash)
            showMessageMoved(title: LocalString._messages_has_been_moved)
            self.cancelButtonTapped()
        }
    }

    @objc internal func moreButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if self.selectedIDs.isEmpty {
            if viewModel.isShowEmptyFolder() {
                let title = viewModel is LabelboxViewModelImpl ? LocalString._empty_label : LocalString._empty_folder
                let confirmationAlert = UIAlertController(title: LocalString._delete_all,
                                                          message: LocalString._are_you_sure_this_cant_be_undone,
                                                          preferredStyle: .alert)
                let emptyAction = UIAlertAction(title: title,
                                                style: .destructive, handler: { (action) -> Void in
                    self.viewModel.emptyFolder()
                    self.showNoResultLabel()
                })
                confirmationAlert.addAction(cancelAction)
                confirmationAlert.addAction(emptyAction)
                
                alertController.addAction(UIAlertAction.init(title: title, style: .destructive, handler: { _ in
                    self.present(confirmationAlert, animated: true, completion: nil)
                }))
            }
        } else {
            alertController.addAction(UIAlertAction(title: LocalString._mark_read,
                                                    style: .default, handler: { (action) -> Void in
                self.viewModel.mark(IDs: self.selectedIDs, unread: false)
                self.cancelButtonTapped()
            }))
            
            alertController.addAction(UIAlertAction(title: LocalString._locations_add_star_action,
                                                    style: .default, handler: { (action) -> Void in
                self.viewModel.label(IDs: self.selectedIDs, with: Message.Location.starred.rawValue, apply: true)
                self.cancelButtonTapped()
            }))
            
            alertController.addAction(UIAlertAction(title: LocalString._remove_star,
                                                    style: .default, handler: { (action) -> Void in
                self.viewModel.label(IDs: self.selectedIDs, with: Message.Location.starred.rawValue, apply: false)
                self.cancelButtonTapped()
            }))
            
            var locations: [Message.Location : UIAlertAction.Style] = [.inbox : .default, .spam : .default, .archive : .default]
            if !viewModel.isCurrentLocation(.sent) {
                locations = [.spam : .default, .archive : .default]
            }
            
            if viewModel.isCurrentLocation(.archive) || viewModel.isCurrentLocation(.trash) || viewModel.isCurrentLocation(.spam) {
                locations[.inbox] = .default
            }

            if (viewModel.isCurrentLocation(.sent)) {
                locations = [:]
            }
            
            if viewModel.showLocation() {
                locations[.inbox] = .default
            }

            for (location, style) in locations {
                if !viewModel.isCurrentLocation(location) {
                    alertController.addAction(UIAlertAction(title: location.actionTitle, style: style, handler: { (action) -> Void in
                        self.moveMessages(to: location)
                        self.cancelButtonTapped()
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
        self.selectedIDs.removeAllObjects()
        self.hideCheckOptions()
        self.updateNavigationController(false)
        if !self.timer.isValid {
            self.startAutoFetch(false)
        }
    }
    
    @objc internal func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        self.showCheckOptions(longPressGestureRecognizer)
        updateNavigationController(listEditing)
        // invalidate tiemr in multi-selected mode to prevent ui refresh issue
        self.timer.invalidate()
    }

    internal func beginRefreshingManually(animated: Bool) {
        if animated {
            self.refreshControl.beginRefreshing()
        }
    }
    
    // MARK: - Private methods
    private func startAutoFetch(_ run : Bool = true) {
        self.timer = Timer.scheduledTimer(timeInterval: self.timerInterval,
                                          target: self,
                                          selector: #selector(refreshPage),
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
        self.viewModel.fetchContacts()
    }
    
    @discardableResult
    private func checkHuman() -> Bool {
        if sharedMessageQueue.isRequiredHumanCheck && isCheckingHuman == false {
            //show human check view with warning
            isCheckingHuman = true
            self.coordinator?.go(to: .humanCheck)
            return false
        }
        return true
    }
    
    private func checkDoh(_ error : NSError) -> Bool {
        let code = error.code
        guard DoHMail.default.codeCheck(code: code) else {
            return false
        }
        self.showError(error)
        return true
        
    }
    
    fileprivate var timerInterval : TimeInterval = 30
    fileprivate var failedTimes = 30
    
    func offlineTimerReset() {
        timerInterval = TimeInterval(arc4random_uniform(90)) + 30
        stopAutoFetch()
        startAutoFetch(false)
    }
    
    func onlineTimerReset() {
        timerInterval = 30
        stopAutoFetch()
        startAutoFetch(false)
    }
    
    private func configure(cell inputCell: UITableViewCell?, indexPath: IndexPath) {
        guard let mailboxCell = inputCell as? MailboxMessageCell else {
            return
        }
        guard let message = self.viewModel.item(index: indexPath) else {
            return
        }
        mailboxCell.configureCell(message, showLocation: viewModel.showLocation(), ignoredTitle: viewModel.ignoredLocationTitle(), replacingEmails: replacingEmails)
        mailboxCell.setCellIsChecked(self.selectedIDs.contains(message.messageID))
        if (self.listEditing) {
            mailboxCell.showCheckboxOnLeftSide()
        } else {
            mailboxCell.hideCheckboxOnLeftSide()
        }
        mailboxCell.zeroMargin()
        mailboxCell.defaultColor = UIColor.lightGray
        let leftCrossView = UILabel()
        leftCrossView.text = self.viewModel.getSwipeTitle(swipeLeftToRightAction)
        leftCrossView.sizeToFit()
        leftCrossView.textColor = UIColor.white
        
        let rightCrossView = UILabel()
        rightCrossView.text = self.viewModel.getSwipeTitle(swipeRightToLeftAction)
        rightCrossView.sizeToFit()
        rightCrossView.textColor = UIColor.white
        
        if self.viewModel.isSwipeActionValid(self.swipeLeftToRightAction) {
            mailboxCell.setSwipeGestureWith(leftCrossView, color: swipeLeftToRightAction.actionColor, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state1 ) { [weak self] (cell, state, mode) -> Void in
                guard let `self` = self else { return }
                guard let cell = cell else { return }
                if let indexp = self.tableView.indexPath(for: cell) {
                    if self.viewModel.isSwipeActionValid(self.swipeLeftToRightAction) {
                        if !self.processSwipeActions(self.swipeLeftToRightAction, indexPath: indexp) {
                            mailboxCell.swipeToOrigin(completion: nil)
                        } else if self.viewModel.stayAfterAction(self.swipeLeftToRightAction) {
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
        
        if self.viewModel.isSwipeActionValid(self.swipeRightToLeftAction) {
            mailboxCell.setSwipeGestureWith(rightCrossView, color: swipeRightToLeftAction.actionColor, mode: MCSwipeTableViewCellMode.exit, state: MCSwipeTableViewCellState.state3  ) { [weak self] (cell, state, mode) -> Void in
                guard let `self` = self else { return }
                guard let cell = cell else { return }
                if let indexp = self.tableView.indexPath(for: cell) {
                    if self.viewModel.isSwipeActionValid(self.swipeRightToLeftAction) {
                        if !self.processSwipeActions(self.swipeRightToLeftAction, indexPath: indexp) {
                            mailboxCell.swipeToOrigin(completion: nil)
                        } else if self.viewModel.stayAfterAction(self.swipeRightToLeftAction) {
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
    }
    
    private func processSwipeActions(_ action: MessageSwipeAction, indexPath: IndexPath) -> Bool {
        ///UIAccessibility
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: action.description)
        switch (action) {
        case .archive:
            self.archive(indexPath)
            return true
        case .trash:
            self.delete(indexPath)
            return true
        case .spam:
            self.spam(indexPath)
            return true
        case .star:
            self.star(indexPath)
            return false
        case .unread:
            self.unread(indexPath)
            return false
        }
    }
    
    private func archive(_ index: IndexPath) {
        let (res, undo) = self.viewModel.archive(index: index)
        switch res {
        case .showUndo:
            undoMessage = undo
            showUndoView(LocalString._messages_archived)
        case .showGeneral:
            showMessageMoved(title: LocalString._messages_has_been_moved)
        default: break
        }
    }
    private func delete(_ index: IndexPath) {
        let (res, undo) = self.viewModel.delete(index: index)
        switch res {
        case .showUndo:
            undoMessage = undo
            showUndoView(LocalString._locations_deleted_desc)
        case .showGeneral:
            showMessageMoved(title: LocalString._messages_has_been_deleted)
        default: break
        }
    }
    
    private func spam(_ index: IndexPath) {
        let (res, undo) = self.viewModel.spam(index: index)
        switch res {
        case .showUndo:
            undoMessage = undo
            showUndoView(LocalString._messages_spammed)
        case .showGeneral:
            showMessageMoved(title: LocalString._messages_has_been_moved)
        default: break
            
        }
    }
    
    private func star(_ indexPath: IndexPath) {
        if let message = self.viewModel.item(index: indexPath) {
            self.viewModel.label(msg: message, with: Message.Location.starred.rawValue)
        }
    }
    
    private func unread(_ indexPath: IndexPath) {
        if let message = self.viewModel.item(index: indexPath) {
           self.viewModel.mark(msg: message)
        }
    }
    
    fileprivate func undoTheMessage() { //need move into viewModel
        if let undoMsg = undoMessage {
            self.viewModel.undo(undoMsg)
            undoMessage = nil
        }
    }
    
    fileprivate func showUndoView(_ title : String) {
        undoLabel.text = String(format: LocalString._messages_with_title, title)
        self.undoBottomDistance.constant = self.kUndoShowPosition
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
        self.undoBottomDistance.constant = self.kUndoShowPosition
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
        self.undoBottomDistance.constant = self.kUndoHidePosition
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
  
    
    fileprivate func checkEmptyMailbox () {
        guard self.viewModel.sectionCount() > 0 else {
            return
        }
        
        self.pullDown()
    }
    
    func handleRequestError (_ error : NSError) {
        PMLog.D("error: \(error)")
        guard checkDoh(error) == false else {
            return
        }
        switch error.code {
        case NSURLErrorTimedOut, APIErrorCode.HTTP504, APIErrorCode.HTTP404:
            showTimeOutErrorMessage()
        case NSURLErrorNotConnectedToInternet, NSURLErrorCannotConnectToHost:
            showNoInternetErrorMessage()
        case APIErrorCode.API_offline:
            showOfflineErrorMessage(error)
            offlineTimerReset()
        case APIErrorCode.HTTP503, NSURLErrorBadServerResponse:
            show503ErrorMessage(error)
            offlineTimerReset()
        case APIErrorCode.forcePasswordChange:
            showErrorMessage(error)
        default:
            showTimeOutErrorMessage()
        }
    }
    
    @objc internal func pullDown() {
        guard !tableView.isDragging else {
            return
        }

        self.getLatestMessagesRaw { (fetch) in
            if fetch {
                //temperay to fix the new messages are not loaded
                self.fetchNewMessage()
            }
        }
    }
    
    private func fetchNewMessage() {
        viewModel.fetchMessages(time: 0, foucsClean: false) { (task, res, error) in
            self.showNoResultLabel()
        }
    }
    
    @objc internal func goTroubleshoot() {
        self.coordinator?.go(to: .troubleShoot)
    }
    
    
    var retryCounter = 0
    @objc internal func getLatestMessages() {
        self.getLatestMessagesRaw(nil)
    }
    internal func getLatestMessagesRaw(_ CompleteIsFetch: ((_ fetch: Bool) -> Void)?) {
        self.hideTopMessage()
        if !fetchingMessage {
            fetchingMessage = true
            self.beginRefreshingManually(animated: self.viewModel.rowCount(section: 0) < 1 ? true : false)
            var handleNoResultLabel: Bool = true
            let complete : CompletionBlock = { (task, res, error) -> Void in
                self.needToShowNewMessage = false
                self.newMessageCount = 0
                self.fetchingMessage = false
                
                if self.fetchingStopped! == true {
                    self.refreshControl?.endRefreshing()
                    return
                }
                
                if let error = error {
                    self.handleRequestError(error)
                }
                
                var loadMore: Int = 0
                if error == nil {
                    self.onlineTimerReset()
                    self.viewModel.resetNotificationMessage()
                    if let notices = res?["Notices"] as? [String] {
                        serverNotice.check(notices)
                    }
                    
                    if let more = res?["More"] as? Int {
                       loadMore = more
                    }
                    
                    if loadMore <= 0 {
                        self.viewModel.messageService.updateMessageCount()
                    }
                }
                
                if loadMore > 0 {
                    if self.retryCounter >= 10 {
                        delay(1.0) {
                            self.viewModel.fetchMessages(time: 0, foucsClean: false, completion: { (_, _, _) in
                                self.retry()
                                self.retryCounter += 1
                            })
                        }
                    } else {
                        self.viewModel.fetchMessages(time: 0, foucsClean: false, completion: { (_, _, _) in
                            self.retry()
                            self.retryCounter += 1
                        })
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                        if self.refreshControl.isRefreshing {
                            self.refreshControl.endRefreshing()
                        }
                    }
                    
                    self.retryCounter = 0
                    if self.fetchingStopped! == true {
                        return
                    }
                    if handleNoResultLabel {
                        self.showNoResultLabel()
                    }
                    let _ = self.checkHuman()
                    
                    //temperay to check message status and fetch metadata
                    self.viewModel.messageService.purgeOldMessages()
                    
                    if userCachedStatus.hasMessageFromNotification {
                        userCachedStatus.hasMessageFromNotification = false
                        self.viewModel.fetchMessages(time: 0, foucsClean: false, completion: nil)
                    } else {
                        CompleteIsFetch?(true)
                    }
                }
            }
            self.showRefreshController()
            if let updateTime = viewModel.lastUpdateTime(), updateTime.isNew == false, viewModel.isEventIDValid() {
                // let response of checkEmptyMailbox decide show label or not.
                handleNoResultLabel = false
                //fetch
                self.needToShowNewMessage = true
                viewModel.fetchEvents(time: Int(updateTime.startTime.timeIntervalSince1970),
                                      notificationMessageID: self.viewModel.notificationMessageID,
                                      completion: complete)
            } else {// this new
                if !viewModel.isEventIDValid() { //if event id is not valid reset
                    viewModel.fetchMessageWithReset(time: 0, completion: complete)
                }
                else {
                    viewModel.fetchMessages(time: 0, foucsClean: false, completion: complete)
                }
            }
            self.checkContact()
        }
        
        self.viewModel.getLatestMessagesForOthers()
    }
    
    fileprivate func showNoResultLabel() {
        
        {
            let count =  self.viewModel.sectionCount() > 0 ? self.viewModel.rowCount(section: 0) : 0
            if (count <= 0 && !self.fetchingMessage ) {
                self.noResultLabel.isHidden = false
            } else {
                self.noResultLabel.isHidden = true
            }
        } ~> .main
    }
    
    private func showRefreshController() {
        let height = tableView.tableFooterView?.frame.height ?? 0
        let count = tableView.visibleCells.count
        guard height == 0 && count == 0 else {return}
        
        // Show refreshControl if there is no bottom loading view
        refreshControl.beginRefreshing()
        self.tableView.setContentOffset(CGPoint(x: 0, y: -refreshControl.frame.size.height), animated: true)
    }

    internal func moveMessages(to location: Message.Location) {
        guard !self.selectedIDs.isEmpty else {
            showNoEmailSelected(title: LocalString._warning)
            return
        }
        self.viewModel.move(IDs: self.selectedIDs, to: location.rawValue)
    }
    
    var messageTapped = false
    let serialQueue = DispatchQueue(label: "com.protonamil.messageTapped")
    func getTapped() -> Bool {
        serialQueue.sync {
            let ret = self.messageTapped
            if ret == false {
                self.messageTapped = true
            }
            return ret
        }
    }
    func updateTapped(status: Bool) {
        serialQueue.sync {
            self.messageTapped = status
        }
    }
    
    internal func tappedMassage(_ message: Message) {
        if getTapped() == false {
            guard viewModel.isDrafts() || message.draft else {
                self.coordinator?.go(to: .details)
                self.tableView.indexPathsForSelectedRows?.forEach {
                    self.tableView.deselectRow(at: $0, animated: true)
                }
                self.updateTapped(status: false)
                return
            }
            guard !message.messageID.isEmpty else {
                if self.checkHuman() {
                    //TODO::QA
                    self.coordinator?.go(to: .composeShow)
                }
                self.updateTapped(status: false)
                return
            }
            guard !message.isSending else {
                LocalString._mailbox_draft_is_uploading.alertToast()
                self.tableView.indexPathsForSelectedRows?.forEach {
                    self.tableView.deselectRow(at: $0, animated: true)
                }
                self.updateTapped(status: false)
                return
            }
            
            self.viewModel.messageService.ForcefetchDetailForMessage(message) {_, _, msg, error in
                guard let objectId = msg?.objectID,
                    let message = self.viewModel.object(by: objectId),
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
                    self.updateTapped(status: false)
                    return
                }
                
                if self.checkHuman() {
                    self.coordinator?.go(to: .composeShow, sender: message)
                    self.tableView.indexPathsForSelectedRows?.forEach {
                        self.tableView.deselectRow(at: $0, animated: true)
                    }
                }
                self.updateTapped(status: false)
            }
        }
        
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
                                                           action: #selector(cancelButtonTapped))
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
                self.composeBarButtonItem.accessibilityLabel = LocalString._composer_compose_action
            }
            
            if (self.searchBarButtonItem == nil) {
                self.searchBarButtonItem = BarItem(image: UIImage.Top.search, action: #selector(searchButtonTapped))
                self.searchBarButtonItem.accessibilityLabel = LocalString._general_search_placeholder
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = BarItem(image: UIImage.Top.more, action: #selector(moreButtonTapped))
                self.moreBarButtonItem.accessibilityLabel = LocalString._general_more
            }
            
            if viewModel.isShowEmptyFolder() {
                rightButtons = [self.moreBarButtonItem, self.composeBarButtonItem, self.searchBarButtonItem]
            } else {
                rightButtons = [self.composeBarButtonItem, self.searchBarButtonItem]
            }
        } else {
            if (self.unreadBarButtonItem == nil) {
                self.unreadBarButtonItem = BarItem(image: UIImage.Top.unread, action: #selector(unreadTapped))
                self.unreadBarButtonItem.accessibilityLabel = LocalString._mark_as_unread
            }
            
            if (self.labelBarButtonItem == nil) {
                self.labelBarButtonItem = BarItem(image: UIImage.Top.label, action: #selector(labelButtonTapped))
                self.labelBarButtonItem.accessibilityLabel = LocalString._label_as_
            }
            
            if (self.folderBarButtonItem == nil) {
                self.folderBarButtonItem = BarItem(image: UIImage.Top.folder, action: #selector(folderButtonTapped))
                self.folderBarButtonItem.accessibilityLabel = LocalString._move_to_
            }
            
            if (self.removeBarButtonItem == nil) {
                self.removeBarButtonItem = BarItem(image: UIImage.Top.trash, action: #selector(removeButtonTapped))
                self.removeBarButtonItem.accessibilityLabel = LocalString._menu_trash_title
            }
            
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = BarItem(image: UIImage.Top.more, action: #selector(moreButtonTapped))
                self.moreBarButtonItem.accessibilityLabel = LocalString._general_more
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
                                if let message = self.viewModel.item(index: indexPath) {
                                    self.selectedIDs.add(message.messageID)
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
 
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // TODO: refactor SearchViewController to have Coordinator and properly inject this hunk
        if let search = (segue.destination as? UINavigationController)?.topViewController as? SearchViewController {
            search.user = self.viewModel.user
        }
        super.prepare(for: segue, sender: sender)
    }
    
    private func handleUpdateAlert() {
        if self.viewModel.shouldShowUpdateAlert() {
            let alertVC = UIAlertController(title: LocalString._ios10_update_title, message: LocalString._ios10_update_body, preferredStyle: .alert)
            alertVC.addOKAction { (_) in
                self.viewModel.setiOS10AlertIsShown()
            }
            self.present(alertVC, animated: true, completion: nil)
        }
    }
}

extension MailboxViewController : LablesViewControllerDelegate {
    func dismissed() {
        
    }
    
    func apply(type: LabelFetchType) {
        self.cancelButtonTapped() // this will finish multiselection mode
        
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

extension MailboxViewController {
    
    private func showBanner(_ message: String,
                            appearance: BannerView.Appearance,
                            buttons: BannerView.ButtonConfiguration? = nil,
                            button2: BannerView.ButtonConfiguration? = nil,
                            from: BannerView.Base)
    {
        guard let navigationBar = self.navigationController?.navigationBar else { return }
        let offset: CGFloat = (from == .top) ? (navigationBar.frame.size.height + navigationBar.frame.origin.y) : 8.0

        let newMessageView = BannerView(appearance: appearance,
                                            message: message,
                                            buttons: buttons,
                                            button2: button2,
                                            offset: offset + 8.0)
        if let superview = self.navigationController?.view {
            switch from {
            case .top:
                self.topMessageView?.remove(animated: true)
                self.topMessageView = newMessageView
            case .bottom:
                // TODO: old style views from storyboard are shown for this case, but can be easily refactored to TopMessageViews
                break
            }
            
            superview.insertSubview(newMessageView, belowSubview: navigationBar)
            newMessageView.drop(on: superview, from: from)
        }
    }
    
    internal func showErrorMessage(_ error: NSError?) {
        guard let error = error else { return }
        showBanner(error.localizedDescription,
                   appearance: .red,
                   from: .top)
    }
    
    internal func showTimeOutErrorMessage() {
        showBanner(LocalString._general_request_timed_out,// + " --- this is a extra long error message. test message.",
                   appearance: .red,
                   buttons: BannerView.ButtonConfiguration.init(title: LocalString._retry, action: self.getLatestMessages),
                   from: .top)
    }
    
    internal func showNoInternetErrorMessage() {
        showBanner(LocalString._general_no_connectivity_detected,
                   appearance: .red,
                   buttons: BannerView.ButtonConfiguration.init(title: LocalString._retry, action: self.getLatestMessages),
                   from: .top)
    }
    
    internal func showOfflineErrorMessage(_ error : NSError?) {
        showBanner(error?.localizedDescription ?? LocalString._general_pm_offline,
                   appearance: .red,
                   buttons: BannerView.ButtonConfiguration.init(title: LocalString._retry, action: self.getLatestMessages),
                   from: .top)
    }
    
    internal func show503ErrorMessage(_ error : NSError?) {
        showBanner(LocalString._general_api_server_not_reachable,
                   appearance: .red,
                   buttons: BannerView.ButtonConfiguration.init(title: LocalString._retry, action: self.getLatestMessages),
                   from: .top)
    }
    
    internal func showError(_ error : NSError) {
        let message = error.localizedDescription
        showBanner(message,
                   appearance: .red,
                   buttons: BannerView.ButtonConfiguration.init(title: LocalString._retry, action: self.getLatestMessages),
                   button2: BannerView.ButtonConfiguration.init(title: LocalString._troubleshoot, action: self.goTroubleshoot),
                   from: .top)
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
            self.afterNetworkChange(status: netStatus)
        case .ReachableViaWiFi:
            PMLog.D("Reachable WiFi")
            self.hideTopMessage()
            self.afterNetworkChange(status: netStatus)
        default:
            PMLog.D("Reachable default unknow")
        }
        lastNetworkStatus = netStatus
    }
    
    internal func afterNetworkChange(status: NetworkStatus) {
        guard let oldStatus = lastNetworkStatus else {
            return
        }
        
        guard oldStatus == .NotReachable else {
            return
        }
        
        if status == .ReachableViaWWAN || status == .ReachableViaWiFi {
            self.retry(delay: 5)
        }
    }
    
    func hideTopMessage() {
        self.topMessageView?.remove(animated: true)
    }
    
    func retry(delay: Double = 0) {
        // When network reconnect, the DNS data seems will miss at a short time
        // Delay 5 seconds to retry can prevent some relative error
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.getLatestMessages()
        }
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
        self.viewModel.cleanReviewItems()
        // go to next screen
        if yesORno == true {
            //TODO::QA
            self.coordinator?.go(to: .feedback)
        }
    }
}


// MARK: - UITableViewDataSource
extension MailboxViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sectionCount()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.rowCount(section: section)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let rIndex = self.viewModel.ratingIndex {
            if rIndex == indexPath {
                let mailboxRateCell = tableView.dequeueReusableCell(withIdentifier: MailboxRateReviewCell.Constant.identifier, for: rIndex) as! MailboxRateReviewCell
                mailboxRateCell.callback = self
                mailboxRateCell.selectionStyle = .none
                return mailboxRateCell
            }
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: MailboxMessageCell.Constant.identifier, for: indexPath)
        self.configure(cell: cell, indexPath: indexPath)
        return cell

    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension MailboxViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == self.viewModel.labelFetchedResults {
            tableView.reloadData()
            return
        }
        self.tableView.endUpdates()
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
        self.showNewMessageCount(self.newMessageCount)
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == self.viewModel.labelFetchedResults {
            return
        }
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        if controller == self.viewModel.labelFetchedResults {
            return
        }
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
        if controller == self.viewModel.labelFetchedResults {
            return
        }
        switch(type) {
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
                if self.needToShowNewMessage == true {
                    if let newMsg = anObject as? Message {
                        if let msgTime = newMsg.time, newMsg.unRead {
                            if let updateTime = viewModel.lastUpdateTime() {
                                if msgTime.compare(updateTime.startTime) != ComparisonResult.orderedAscending {
                                    self.newMessageCount += 1
                                }
                            }
                        }
                    }
                }
            }
        case .update:
            //#3 is active
            /// # 1
            if let indexPath = indexPath {
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }
            
//            if let newIndexPath = newIndexPath {
//                self.tableView.reloadRows(at: [newIndexPath], with: .fade)
//            }
            
            /// #2
//            if let indexPath = indexPath {
//                let cell = tableView.cellForRow(at: indexPath)
//                self.configure(cell: cell, indexPath: indexPath)
//            }

//            if let newIndexPath = newIndexPath {
//                let cell = tableView.cellForRow(at: newIndexPath)
//                self.configure(cell: cell, indexPath: newIndexPath)
//            }

            /// #3
//            if let indexPath = indexPath, let newIndexPath = newIndexPath {
//                let cell = tableView.cellForRow(at: indexPath)
//                self.configure(cell: cell, indexPath: newIndexPath)
//            }/
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            break
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
        guard let current = self.viewModel.item(index: indexPath) else {
            return
        }
        
        if let updateTime = viewModel.lastUpdateTime(), let currentTime = current.time {
            let isOlderMessage = updateTime.endTime.compare(currentTime) != ComparisonResult.orderedAscending
            let loadMore = self.viewModel.loadMore(index: indexPath)
            if  (isOlderMessage || loadMore) && !self.fetchingOlder {
                let sectionCount = self.viewModel.rowCount(section: indexPath.section)
                let recordedCount = Int(updateTime.total)
                //here need add a counter to check if tried too many times make one real call in case count not right
                if updateTime.isNew || recordedCount > sectionCount {
                    self.fetchingOlder = true
                    if !refreshControl.isRefreshing {
                        self.tableView.showLoadingFooter()
                    }
//                    let updateTime = self.viewModel.lastUpdateTime()
                    let unixTimt: Int = (updateTime.endTime == Date.distantPast ) ? 0 : Int(updateTime.endTime.timeIntervalSince1970)
                    self.viewModel.fetchMessages(time: unixTimt, foucsClean: false, completion: { (task, response, error) -> Void in
                        self.tableView.hideLoadingFooter()
                        self.fetchingOlder = false
                        self.checkHuman()
                    })
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let rIndex = self.viewModel.ratingIndex {
            if rIndex == indexPath {
                return kMailboxRateReviewCellHeight
            }
        }
        return kMailboxCellHeight
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let rIndex = self.viewModel.ratingIndex {
            if rIndex == indexPath {
                return nil
            }
        }
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let message = self.viewModel.item(index: indexPath) {
            if (self.listEditing) {
                let messageAlreadySelected: Bool = self.selectedIDs.contains(message.messageID)
                if (messageAlreadySelected) {
                    self.selectedIDs.remove(message.messageID)
                } else {
                    self.selectedIDs.add(message.messageID)
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
        let frame = noResultLabel.frame
        if scrollView.contentOffset.y <= 0 {
            self.noResultLabel.frame = CGRect(x: frame.origin.x, y: -scrollView.contentOffset.y, width: frame.width, height: frame.height)
        } else {
            self.noResultLabel.frame = CGRect(x: frame.origin.x, y: 0, width: frame.width, height: frame.height)
        }
    }
}

extension MailboxViewController {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if refreshControl.isRefreshing {
            self.pullDown()
        }
    }
}

extension MailboxViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: MailboxViewController.self), value: self.viewModel.labelID)
    }
}
