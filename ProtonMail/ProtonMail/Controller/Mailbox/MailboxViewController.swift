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
import SkeletonView
import SwipyCell
import ProtonCore_Services
import ProtonCore_UIFoundations
import Alamofire
class MailboxViewController: ProtonMailViewController, ViewModelProtocol, CoordinatedNew, ComposeSaveHintProtocol {
    typealias viewModelType = MailboxViewModel
    typealias coordinatorType = MailboxCoordinator

    private(set) var viewModel: MailboxViewModel!
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

    lazy var replacingEmails: [Email] = { [unowned self] in
        viewModel.allEmails()
    }()

    var listEditing: Bool = false
    
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
    
    // MARK: TopActions
    @IBOutlet weak var topActionsView: UIView!
    @IBOutlet weak var updateTimeLabel: UILabel!
    @IBOutlet weak var unreadFilterButton: UIButton!
    @IBOutlet weak var unreadFilterButtonWidth: NSLayoutConstraint!
    
    // MARK: TopMessage
    private weak var topMessageView: BannerView?
    
    // MARK: MailActionBar
    private var mailActionBar: PMActionBar?
    
    // MARK: - Private attributes
    private var timerAutoDismiss : Timer?

    private var bannerContainer: UIView?
    private var bannerShowConstrain: NSLayoutConstraint?
    private var isInternetBannerPresented = false
    private var isHidingBanner = false
    
    private var fetchingNewer : Bool = false
    private var fetchingOlder : Bool = false
    private var indexPathForSelectedRow : IndexPath?
    
    private var undoMessage : UndoMessage?
    
    private var isShowUndo : Bool = false
    private var isCheckingHuman: Bool = false
    
    private var fetchingMessage : Bool = false
    private var fetchingStopped : Bool = true
    private var needToShowNewMessage : Bool = false
    private var newMessageCount = 0
    private var hasNetworking = true
    private var isFirstFetch = true
    private var isEditingMode = true
    
    // MAKR : - Private views
    private var refreshControl: UIRefreshControl!
    private var navigationTitleLabel = UILabel()
    
    // MARK: - Right bar buttons
    private var composeBarButtonItem: UIBarButtonItem!
    private var storageExceededBarButtonItem: UIBarButtonItem!
    private var searchBarButtonItem: UIBarButtonItem!
    private var cancelBarButtonItem: UIBarButtonItem!
    
    // MARK: - Left bar button
    private var menuBarButtonItem: UIBarButtonItem!
    
    // MARK: - No result image and label
    @IBOutlet weak var noResultImage: UIImageView!
    @IBOutlet weak var noResultMainLabel: UILabel!
    @IBOutlet weak var noResultSecondaryLabel: UILabel!
    @IBOutlet weak var noResultFooterLabel: UILabel!
    
    // MARK: action sheet
    private var actionSheet: PMActionSheet?
    
    private var lastNetworkStatus : NetworkStatus? = nil
    
    private var shouldAnimateSkeletonLoading = false
    private var shouldKeepSkeletonUntilManualDismissal = false
    private var isShowingUnreadMessageOnly: Bool {
        return self.unreadFilterButton.isSelected
    }

    private let messageCellPresenter = NewMailboxMessageCellPresenter()
    private let mailListActionSheetPresenter = MailListActionSheetPresenter()
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()

    private var isSwipingCell = false

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
        self.updateLastUpdateTimeLabel()
        self.updateUnreadButton()

        refetchAllIfNeeded()
        startAutoFetch()
    }

    @objc func doEnterBackground() {
        stopAutoFetch()
    }

    private func refetchAllIfNeeded() {
        if BackgroundTimer.shared.wasInBackgroundForMoreThanOneHour {
            pullDown()
            BackgroundTimer.shared.updateLastForegroundDate()
        }
    }
    
    func resetTableView() {
        self.viewModel.resetFetchedController()
        self.viewModel.setupFetchController(self, isUnread: self.unreadFilterButton.isSelected)
        self.tableView.reloadData()
    }

    override var prefersStatusBarHidden: Bool {
        false
    }
    
    // MARK: - UIViewController Lifecycle
    
    class func instance() -> MailboxViewController {
        let board = UIStoryboard.Storyboard.inbox.storyboard
        let vc = board.instantiateViewController(withIdentifier: "MailboxViewController") as! MailboxViewController
        let _ = UINavigationController(rootViewController: vc)
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(self.viewModel != nil)
        assert(self.coordinator != nil)

        self.viewModel.viewModeIsChanged = { [weak self] in
            self?.handleViewModeIsChanged()
        }

        configureUnreadFilterButton()

        if [Message.Location.spam,
            Message.Location.archive,
            Message.Location.trash,
            Message.Location.sent].map(\.rawValue).contains(viewModel.labelID)
            && viewModel.isCurrentUserSelectedUnreadFilterInInbox {
            unreadMessageFilterButtonTapped(unreadFilterButton as Any)
        }

        self.viewModel.setupFetchController(self,
                                            isUnread: viewModel.isCurrentUserSelectedUnreadFilterInInbox)
        
        self.undoButton.setTitle(LocalString._messages_undo_action, for: .normal)
        self.setNavigationTitleText(viewModel.localizedNavigationTitle)
        
        SkeletonAppearance.default.renderSingleLineAsView = true
        
        self.tableView.separatorColor = UIColorManager.InteractionWeak
        self.tableView.register(NewMailboxMessageCell.self, forCellReuseIdentifier: NewMailboxMessageCell.defaultID())
        self.tableView.RegisterCell(MailBoxSkeletonLoadingCell.Constant.identifier)
        
        self.addSubViews()

        self.updateNavigationController(listEditing)
        
        if !userCachedStatus.isTourOk() {
            userCachedStatus.resetTourValue()
            self.coordinator?.go(to: .onboarding)
        }
        
        self.undoBottomDistance.constant = self.kUndoHidePosition
        self.undoButton.isHidden = true
        self.undoView.isHidden = true
        
        //Setup top actions
        self.topActionsView.backgroundColor = UIColorManager.BackgroundNorm
        self.updateTimeLabel.textColor = UIColorManager.TextHint
        
        self.updateUnreadButton()
        self.updateLastUpdateTimeLabel()
        
        self.viewModel.cleanReviewItems()
        generateAccessibilityIdentifiers()
        configureBannerContainer()

        SwipyCellConfig.shared.triggerPoints.removeValue(forKey: -0.75)
        SwipyCellConfig.shared.triggerPoints.removeValue(forKey: 0.75)

        refetchAllIfNeeded()
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

            NotificationCenter.default.addObserver(self,
                                                   selector:#selector(doEnterBackground),
                                                   name:  UIWindowScene.didEnterBackgroundNotification,
                                                   object: nil)
        } else {
            NotificationCenter.default.addObserver(self,
                                                    selector:#selector(doEnterForeground),
                                                    name: UIApplication.willEnterForegroundNotification,
                                                    object: nil)

            NotificationCenter.default.addObserver(self,
                                                    selector:#selector(doEnterBackground),
                                                    name: UIApplication.didEnterBackgroundNotification,
                                                    object: nil)
        }

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged,
                                 argument: self.navigationController?.view)
        }

        if viewModel.eventsService.status != .started {
            self.startAutoFetch()
        } else {
            viewModel.eventsService.resume()
            viewModel.eventsService.call()
        }
        self.updateUnreadButton()
        deleteExpiredMessages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideTopMessage()
        NotificationCenter.default.removeObserver(self)
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

        self.updateInterface(reachability: sharedInternetReachability)
        
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
        
        FileManager.default.cleanCachedAttsLegacy()

        checkHuman()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }
    
    private func addSubViews() {
        self.navigationTitleLabel.backgroundColor = UIColor.clear
        self.navigationTitleLabel.font = Fonts.h3.semiBold
        self.navigationTitleLabel.textAlignment = NSTextAlignment.center
        self.navigationTitleLabel.textColor = UIColorManager.TextNorm
        self.navigationTitleLabel.text = self.title ?? LocalString._locations_inbox_title
        self.navigationTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationTitleLabel
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = .clear
        self.refreshControl.addTarget(self, action: #selector(pullDown), for: UIControl.Event.valueChanged)
        self.refreshControl.tintColor = UIColorManager.BrandNorm
        self.refreshControl.tintColorDidChange()
        
        self.view.backgroundColor = UIColorManager.BackgroundNorm

        self.tableView.addSubview(self.refreshControl)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.noSeparatorsBelowFooter()
        
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)
        
        self.menuBarButtonItem = self.navigationItem.leftBarButtonItem
        self.menuBarButtonItem.tintColor = UIColorManager.IconNorm
        
        self.noResultMainLabel.textColor = UIColorManager.TextNorm
        self.noResultMainLabel.isHidden = true
        
        self.noResultSecondaryLabel.textColor = UIColorManager.TextWeak
        self.noResultSecondaryLabel.isHidden = true
        
        self.noResultFooterLabel.textColor = UIColorManager.TextHint
        self.noResultFooterLabel.isHidden = true
        let attridutes = FontManager.CaptionHint
        self.noResultFooterLabel.attributedText = NSAttributedString(string: LocalString._mailbox_footer_no_result, attributes: attridutes)
        
        self.noResultImage.isHidden = true
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
        self.navigationTitleLabel.sizeToFit()
    }
    
    func showNoEmailSelected(title: String) {
        let alert = UIAlertController(title: title, message: LocalString._message_list_no_email_selected, preferredStyle: .alert)
        alert.addOKAction()
        self.present(alert, animated: true, completion: nil)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleShadow(isScrolled: scrollView.contentOffset.y > 0)
    }
    
    // MARK: - Button Targets
    @IBAction func undoAction(_ sender: UIButton) {
        self.undoTheMessage()
        self.hideUndoView()
    }
    
    @objc internal func composeButtonTapped() {
        if checkHuman() {
            self.coordinator?.go(to: .composer)
        }
    }

    @objc func storageExceededButtonTapped() {
        LocalString._storage_exceeded.alertToastBottom()
    }
    
    @objc internal func searchButtonTapped() {
        self.coordinator?.go(to: .search)
    }
    
    @objc internal func cancelButtonTapped() {
        self.viewModel.removeAllSelectedIDs()
        self.hideCheckOptions()
        self.updateNavigationController(false)
        if viewModel.eventsService.status != .running {
            self.startAutoFetch(false)
        }
        self.hideActionBar()
        self.hideActionSheet()
    }
    
    @objc internal func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        self.showCheckOptions(longPressGestureRecognizer)
        updateNavigationController(listEditing)
        // invalidate tiemr in multi-selected mode to prevent ui refresh issue
        self.viewModel.eventsService.pause()
    }
    
    @IBAction func unreadMessageFilterButtonTapped(_ sender: Any) {
        self.unreadFilterButton.isSelected.toggle()
        let isSelected = self.unreadFilterButton.isSelected
        if isSelected {
            //update the predicate in fetch controller
            self.viewModel.setupFetchController(self, isUnread: true)

            if self.viewModel.countOfFetchedObjects == 0 {
                self.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: true, completion: nil)
            }
        } else {
            self.viewModel.setupFetchController(self, isUnread: false)
        }
        self.viewModel.isCurrentUserSelectedUnreadFilterInInbox = isSelected
        self.tableView.reloadData()
        self.updateUnreadButton()
        self.showNoResultLabel()
    }
    
    private func beginRefreshingManually(animated: Bool) {
        if animated {
            self.refreshControl.beginRefreshing()
        }
    }
    
    // MARK: - Private methods

    private func handleViewModeIsChanged() {
        // Cancel selected items
        cancelButtonTapped()

        viewModel.setupFetchController(self,
                                       isUnread: viewModel.isCurrentUserSelectedUnreadFilterInInbox)
        tableView.reloadData()

        if viewModel.countOfFetchedObjects == 0 {
            viewModel.fetchMessages(time: 0,
                                    forceClean: false,
                                    isUnread: viewModel.isCurrentUserSelectedUnreadFilterInInbox,
                                    completion: nil)
        }

        updateUnreadButton()
        showNoResultLabel()
    }
    
    // MARK: Auto refresh methods
    private func startAutoFetch(_ run : Bool = true) {
        viewModel.eventsService.start()
        viewModel.eventsService.begin(subscriber: self)
        fetchingStopped = false
        if run {
            self.viewModel.eventsService.call()
        }
    }
    
    private func stopAutoFetch() {
        fetchingStopped = true
        viewModel.eventsService.pause()
    }
    
    private func checkContact() {
        self.viewModel.fetchContacts()
    }
    
    @discardableResult
    private func checkHuman() -> Bool {
        if self.viewModel.isRequiredHumanCheck && isCheckingHuman == false {
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

    // MARK: cell configuration methods
    private func configure(cell inputCell: UITableViewCell?, indexPath: IndexPath) {
        guard let mailboxCell = inputCell as? NewMailboxMessageCell else {
            return
        }
        
        switch self.viewModel.locationViewMode {
        case .singleMessage:
            guard let message: Message = self.viewModel.item(index: indexPath) else {
                return
            }
            let viewModel = buildNewMailboxMessageViewModel(
                message: message,
                customFolderLabels: self.viewModel.customFolders,
                weekStart: viewModel.user.userinfo.weekStartValue
            )
            mailboxCell.id = message.messageID
            mailboxCell.cellDelegate = self
            messageCellPresenter.present(viewModel: viewModel, in: mailboxCell.customView)
            if message.expirationTime != nil &&
                message.messageLocation != .draft {
                mailboxCell.startUpdateExpiration()
            }

            configureSwipeAction(mailboxCell, indexPath: indexPath, message: message)
        case .conversation:
            guard let conversation = self.viewModel.itemOfConversation(index: indexPath) else {
                return
            }
            let viewModel = buildNewMailboxMessageViewModel(
                conversation: conversation,
                customFolderLabels: self.viewModel.customFolders,
                weekStart: viewModel.user.userinfo.weekStartValue
            )
            mailboxCell.id = conversation.conversationID
            mailboxCell.cellDelegate = self
            messageCellPresenter.present(viewModel: viewModel, in: mailboxCell.customView)
            configureSwipeAction(mailboxCell, indexPath: indexPath, conversation: conversation)
        }
        let accessibilityAction =
            UIAccessibilityCustomAction(name: LocalString._accessibility_list_view_custom_action_of_switch_editing_mode,
                                        target: self,
                                        selector: #selector(self.handleAccessibilityAction))
        inputCell?.accessibilityCustomActions = [accessibilityAction]
    }

    private func configureSwipeAction(_ cell: SwipyCell, indexPath: IndexPath, message: Message) {
        cell.delegate = self
        
        let leftToRightAction = userCachedStatus.leftToRightSwipeActionType
        let leftToRightMsgAction = viewModel.convertSwipeActionTypeToMessageSwipeAction(leftToRightAction,
                                                                                        message: message)

        if leftToRightMsgAction != .none && viewModel.isSwipeActionValid(leftToRightMsgAction, message: message) {
            let leftToRightSwipeView = makeSwipeView(messageSwipeAction: leftToRightMsgAction)
            cell.addSwipeTrigger(forState: .state(0, .left),
                                 withMode: .exit,
                                 swipeView: leftToRightSwipeView,
                                 swipeColor: leftToRightMsgAction.actionColor) { [weak self] (cell, trigger, state, mode) in
                guard let self = self else { return }
                self.isSwipingCell = true
                self.handleSwipeAction(on: cell, action: leftToRightMsgAction, message: message)
                delay(0.5) {
                    self.isSwipingCell = false
                }
            }
        }

        let rightToLeftAction = userCachedStatus.rightToLeftSwipeActionType
        let rightToLeftMsgAction = viewModel.convertSwipeActionTypeToMessageSwipeAction(rightToLeftAction, message: message)

        if rightToLeftMsgAction != .none && viewModel.isSwipeActionValid(rightToLeftMsgAction, message: message) {
            let rightToLeftSwipeView = makeSwipeView(messageSwipeAction: rightToLeftMsgAction)
            cell.addSwipeTrigger(forState: .state(0, .right),
                                 withMode: .exit,
                                 swipeView: rightToLeftSwipeView,
                                 swipeColor: rightToLeftMsgAction.actionColor) { [weak self] (cell, trigger, state, mode) in
                guard let self = self else { return }
                self.isSwipingCell = true
                self.handleSwipeAction(on: cell, action: rightToLeftMsgAction, message: message)
                delay(0.5) {
                    self.isSwipingCell = false
                }
            }
        }
    }

    private func configureSwipeAction(_ cell: SwipyCell, indexPath: IndexPath, conversation: Conversation) {
        let leftToRightAction = userCachedStatus.leftToRightSwipeActionType
        let leftToRightMsgAction = viewModel.convertSwipeActionTypeToMessageSwipeAction(leftToRightAction,
                                                                                        conversation: conversation)

        if leftToRightMsgAction != .none && viewModel.isSwipeActionValid(leftToRightMsgAction, conversation: conversation) {
            let leftToRightSwipeView = makeSwipeView(messageSwipeAction: leftToRightMsgAction)
            cell.addSwipeTrigger(forState: .state(0, .left),
                                 withMode: .exit,
                                 swipeView: leftToRightSwipeView,
                                 swipeColor: leftToRightMsgAction.actionColor) { [weak self] (cell, trigger, state, mode) in
                self?.handleSwipeAction(on: cell, action: leftToRightMsgAction, conversation: conversation)
            }
        }

        let rightToLeftAction = userCachedStatus.rightToLeftSwipeActionType
        let rightToLeftMsgAction = viewModel.convertSwipeActionTypeToMessageSwipeAction(rightToLeftAction,
                                                                                        conversation: conversation)

        if rightToLeftMsgAction != .none && viewModel.isSwipeActionValid(rightToLeftMsgAction, conversation: conversation) {
            let rightToLeftSwipeView = makeSwipeView(messageSwipeAction: rightToLeftMsgAction)
            cell.addSwipeTrigger(forState: .state(0, .right),
                                 withMode: .exit,
                                 swipeView: rightToLeftSwipeView,
                                 swipeColor: rightToLeftMsgAction.actionColor) { [weak self] (cell, trigger, state, mode) in
                self?.handleSwipeAction(on: cell, action: rightToLeftMsgAction, conversation: conversation)
            }
        }
    }

    private func handleSwipeAction(on cell: SwipyCell, action: MessageSwipeAction, message: Message) {
        guard let indexPathOfCell = self.tableView.indexPath(for: cell) else {
            self.tableView.reloadData()
            return
        }

        guard self.viewModel.isSwipeActionValid(action, message: message) else {
            cell.swipeToOrigin {}
            return
        }

        guard !self.processSwipeActions(action,
                                     indexPath: indexPathOfCell) else {
            return
        }

        guard action != .read && action != .unread else {
            return
        }

        cell.swipeToOrigin {}
    }

    private func handleSwipeAction(on cell: SwipyCell, action: MessageSwipeAction, conversation: Conversation) {
        guard let indexPathOfCell = self.tableView.indexPath(for: cell) else {
            self.tableView.reloadData()
            return
        }

        guard self.viewModel.isSwipeActionValid(action, conversation: conversation) else {
            cell.swipeToOrigin {}
            return
        }

        guard !self.processSwipeActions(action,
                                     indexPath: indexPathOfCell) else {
            return
        }

        guard action != .read && action != .unread else {
            return
        }

        cell.swipeToOrigin {}
    }

    private func processSwipeActions(_ action: MessageSwipeAction, indexPath: IndexPath) -> Bool {
        /// UIAccessibility
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: action.description)
        // TODO: handle conversation
        switch action {
        case .none:
            break
        case .labelAs:
            labelAs(indexPath)
        case .moveTo:
            moveTo(indexPath)
        case .unread:
            self.unread(indexPath)
            return false
        case .read:
            self.read(indexPath)
            return false
        case .star:
            self.star(indexPath)
            return false
        case .unstar:
            self.unstar(indexPath)
            return false
        case .trash:
            return self.delete(indexPath)
        case .archive:
            self.archive(indexPath)
            return true
        case .spam:
            self.spam(indexPath)
            return true
        }
        return false
    }

    private func labelAs(_ index: IndexPath) {
        if let message = viewModel.item(index: index) {
            showLabelAsActionSheet(messages: [message])
        } else if let conversation = viewModel.itemOfConversation(index: index) {
            showLabelAsActionSheet(conversations: [conversation])
        }
    }

    private func moveTo(_ index: IndexPath) {
        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        if let message = viewModel.item(index: index) {
            showMoveToActionSheet(messages: [message],
                                  isEnableColor: isEnableColor,
                                  isInherit: isInherit)
        } else if let conversation = viewModel.itemOfConversation(index: index) {
            showMoveToActionSheet(conversations: [conversation],
                                  isEnableColor: isEnableColor,
                                  isInherit: isInherit)
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
    
    private func delete(_ index: IndexPath) -> Bool {
        let (res, undo, actionDidSucceed) = self.viewModel.delete(index: index)
        switch res {
        case .showUndo:
            undoMessage = undo
            showUndoView(LocalString._locations_deleted_desc)
        case .showGeneral:
            showMessageMoved(title: LocalString._messages_has_been_deleted)
        default: break
        }
        return actionDidSucceed
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
        } else if let conversation = viewModel.itemOfConversation(index: indexPath) {
            viewModel.labelConversations(conversationIDs: [conversation.conversationID],
                                         labelID: Message.Location.starred.rawValue) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.viewModel.eventsService.fetchEvents(labelID: self.viewModel.labelId)
                }
            }
        }
    }

    private func unstar(_ indexPath: IndexPath) {
        if let message = self.viewModel.item(index: indexPath) {
            self.viewModel.label(msg: message, with: Message.Location.starred.rawValue, apply: false)
        } else if let conversation = viewModel.itemOfConversation(index: indexPath) {
            viewModel.unlabelConversations(conversationIDs: [conversation.conversationID],
                                         labelID: Message.Location.starred.rawValue) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.viewModel.eventsService.fetchEvents(labelID: self.viewModel.labelId)
                }
            }
        }
    }

    private func unread(_ indexPath: IndexPath) {
        if let message = self.viewModel.item(index: indexPath) {
            self.viewModel.mark(messages: [message])
        } else if let conversation = viewModel.itemOfConversation(index: indexPath) {
            viewModel.markConversationAsUnread(conversationIDs: [conversation.conversationID],
                                               currentLabelID: viewModel.labelID,
                                               completion: nil)
        }
    }

    private func read(_ indexPath: IndexPath) {
        if let message = self.viewModel.item(index: indexPath) {
            self.viewModel.mark(messages: [message], unread: false)
        } else if let conversation = viewModel.itemOfConversation(index: indexPath) {
            viewModel.markConversationAsRead(conversationIDs: [conversation.conversationID],
                                             currentLabelID: viewModel.labelId,
                                             completion: nil)
        }
    }

    private func makeSwipeView(messageSwipeAction: MessageSwipeAction) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)

        let iconView = UIImageView()
        iconView.translatesAutoresizingMaskIntoConstraints = false
        [
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24)
        ].activate()

        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(label)

        var attribute = FontManager.CaptionStrong
        attribute[.foregroundColor] = UIColorManager.TextInverted
        label.attributedText = messageSwipeAction.description.apply(style: attribute)
        iconView.image = messageSwipeAction.icon
        iconView.tintColor = UIColorManager.TextInverted

        return stackView
    }

    private func undoTheMessage() { //need move into viewModel
        if let undoMsg = undoMessage {
            self.viewModel.undo(undoMsg)
            undoMessage = nil
        }
    }
    
    private func showUndoView(_ title : String) {
        undoLabel.text = String(format: LocalString._messages_with_title, title)
        self.undoBottomDistance.constant = self.kUndoShowPosition
        self.undoButton.isHidden = true
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
    
    private func showMessageMoved(title : String) {
        undoLabel.text = title
        self.undoBottomDistance.constant = self.kUndoShowPosition
        self.undoButton.isHidden = true
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
    
    private func hideUndoView() {
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
    
    @objc private func timerTriggered() {
        self.hideUndoView()
    }
    
    private func checkEmptyMailbox () {
        guard self.viewModel.sectionCount() > 0 else {
            return
        }
        self.pullDown()
    }
    
    private func handleRequestError(_ error : NSError) {
        PMLog.D("error: \(error)")
        guard sharedInternetReachability.currentReachabilityStatus() != .NotReachable else { return }
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
        case APIErrorCode.HTTP503, NSURLErrorBadServerResponse:
            show503ErrorMessage(error)
        case APIErrorCode.forcePasswordChange:
            showErrorMessage(error)
        default:
            showTimeOutErrorMessage()
        }
    }

    @objc private func pullDown() {
        guard !tableView.isDragging else {
            return
        }
        guard self.hasNetworking else {
            self.refreshControl.endRefreshing()
            return
        }
        // to update used space, pull down will wipe event data
        // so the latest used space can't update by event api
        self.viewModel.user.fetchUserInfo()
        forceRefreshAllMessages()
        self.showNoResultLabel()
    }
    
    @objc private func goTroubleshoot() {
        self.coordinator?.go(to: .troubleShoot)
    }
    
    private func getLatestMessagesCompletion(task: URLSessionDataTask?, res: [String : Any]?, error: NSError?, completeIsFetch: ((_ fetch: Bool) -> Void)?) {
        self.needToShowNewMessage = false
        self.newMessageCount = 0
        self.fetchingMessage = false
        
        if self.fetchingStopped == true {
            self.refreshControl?.endRefreshing()
            if let _ = res?["Total"] {
                // There are 2 api will call this completion
                // 1. fetch event
                // 2. fetch message
                // Only the response of fetch message will contain Total
                // The no result label only care about the result of fetch message
                self.showNoResultLabel()
            }
            completeIsFetch?(false)
            return
        }
        self.setupRightButtons(self.isEditingMode)
        if let error = error {
            DispatchQueue.main.async {
                self.handleRequestError(error)
            }
        }
        
        var loadMore: Int?
        if error == nil {
            self.viewModel.resetNotificationMessage()
            if let notices = res?["Notices"] as? [String] {
                serverNotice.check(notices)
            }
            
            if let more = res?["More"] as? Int {
               loadMore = more
            }
            
            if let more = loadMore, more <= 0 {
                self.viewModel.messageService.updateMessageCount()
            }
        }
        
        if let more = loadMore, more > 0 {
            if self.retryCounter >= 10 {
                completeIsFetch?(false)
                delay(1.0) {
                    self.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: false, completion: { (_, _, _) in
                        self.retry()
                        self.retryCounter += 1
                    })
                }
            } else {
                completeIsFetch?(false)
                self.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: false, completion: { (_, _, _) in
                    self.retry()
                    self.retryCounter += 1
                })
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                if let _ = res?["Total"] {
                    self.showNoResultLabel()
                }
            }
            
            self.retryCounter = 0
            if self.fetchingStopped == true {
                completeIsFetch?(false)
                return
            }
            
            let _ = self.checkHuman()
            //temperay to check message status and fetch metadata
            self.viewModel.messageService.purgeOldMessages()
            
            if userCachedStatus.hasMessageFromNotification {
                userCachedStatus.hasMessageFromNotification = false
                self.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: false, completion: nil)
                completeIsFetch?(false)
            } else {
                completeIsFetch?(true)
            }
        }
    }
    
    var retryCounter = 0
    @objc internal func getLatestMessages() {
        self.getLatestMessagesRaw() { [weak self] _ in
            self?.deleteExpiredMessages()
            
            self?.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: false) { [weak self] task, res, error in
                self?.getLatestMessagesCompletion(task: task, res: res, error: error, completeIsFetch: nil)
            }
            
            self?.showNoResultLabel()
        }
    }
    
    internal func getLatestMessagesRaw(_ completeIsFetch: ((_ fetch: Bool) -> Void)?) {
        self.hideTopMessage()
        if !fetchingMessage {
            fetchingMessage = true
            self.beginRefreshingManually(animated: self.viewModel.rowCount(section: 0) < 1 ? true : false)
            self.showRefreshController()
            if isFirstFetch {
                isFirstFetch = false
                if viewModel.currentViewMode == .conversation {
                    viewModel.fetchConversationCount(completion: nil)
                }
                viewModel.fetchMessages(time: 0, forceClean: false, isUnread: isShowingUnreadMessageOnly) { [weak self] task, res, error in
                    self?.getLatestMessagesCompletion(task: task, res: res, error: error, completeIsFetch: completeIsFetch)
                }
            } else {
                if viewModel.isEventIDValid() {
                    //fetch
                    self.needToShowNewMessage = true
                    viewModel.fetchEvents(time: 0,
                                          notificationMessageID: self.viewModel.notificationMessageID) { [weak self] task, res, error in
                        self?.getLatestMessagesCompletion(task: task, res: res, error: error, completeIsFetch: completeIsFetch)
                    }
                } else {// this new
                    viewModel.fetchDataWithReset(time: 0, cleanContact: false, removeAllDraft: false, unreadOnly: false) { [weak self] task, res, error in
                        self?.getLatestMessagesCompletion(task: task, res: res, error: error, completeIsFetch: completeIsFetch)
                    }
                }
            }
            self.checkContact()
        }
        
        self.viewModel.getLatestMessagesForOthers()
    }
    
    private func forceRefreshAllMessages() {
        guard !self.fetchingMessage else { return }
        self.fetchingMessage = true
        self.shouldAnimateSkeletonLoading = true
        self.shouldKeepSkeletonUntilManualDismissal = true
        self.tableView.reloadData()
        stopAutoFetch()

        viewModel.fetchDataWithReset(time: 0, cleanContact: true, removeAllDraft: false, unreadOnly: isShowingUnreadMessageOnly) { [weak self] task, res, error in
            if self?.unreadFilterButton.isSelected == true {
                self?.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: false, completion: nil)
            }
            delay(0.2) {
                self?.shouldAnimateSkeletonLoading = false
                self?.shouldKeepSkeletonUntilManualDismissal = false
                self?.tableView.reloadData()
            }
            self?.getLatestMessagesCompletion(task: task, res: res, error: error, completeIsFetch: nil)
            self?.startAutoFetch()
        }
        self.viewModel.forceRefreshMessagesForOthers()
    }
    
    fileprivate func showNoResultLabel() {
        delay(0.5) {
            {
                let count = self.viewModel.sectionCount() > 0 ? self.viewModel.rowCount(section: 0) : 0
                if (count <= 0 && !self.fetchingMessage ) {
                    let isNotInInbox = self.viewModel.labelID != Message.Location.inbox.rawValue

                    self.noResultImage.image = isNotInInbox ? UIImage(named: "mail_folder_no_result_icon") : UIImage(named: "mail_no_result_icon")
                    self.noResultImage.isHidden = false

                    self.noResultMainLabel.attributedText = NSMutableAttributedString(string: isNotInInbox ? LocalString._mailbox_folder_no_result_mail_label : LocalString._mailbox_no_result_main_label, attributes: FontManager.Headline)
                    self.noResultMainLabel.isHidden = false

                    self.noResultSecondaryLabel.attributedText = NSMutableAttributedString(string: isNotInInbox ? LocalString._mailbox_folder_no_result_secondary_label : LocalString._mailbox_no_result_secondary_label, attributes: FontManager.DefaultWeak)
                    self.noResultSecondaryLabel.isHidden = false

                    self.noResultFooterLabel.isHidden = false
                } else {
                    let isHidden = count > 0 || self.fetchingMessage == false
                    self.noResultImage.isHidden = isHidden
                    self.noResultMainLabel.isHidden = isHidden
                    self.noResultSecondaryLabel.isHidden = isHidden
                    self.noResultFooterLabel.isHidden = isHidden
                }
            } ~> .main
        }
    }
    
    private func showRefreshController() {
        let height = tableView.tableFooterView?.frame.height ?? 0
        let count = tableView.visibleCells.count
        guard height == 0 && count == 0 else {return}
        
        // Show refreshControl if there is no bottom loading view
        refreshControl.beginRefreshing()
        self.tableView.setContentOffset(CGPoint(x: 0, y: -refreshControl.frame.size.height), animated: true)
    }
    
    var messageTapped = false
    let serialQueue = DispatchQueue(label: "com.protonamil.messageTapped")
    
    private func getTapped() -> Bool {
        serialQueue.sync {
            let ret = self.messageTapped
            if ret == false {
                self.messageTapped = true
            }
            return ret
        }
    }
    private func updateTapped(status: Bool) {
        serialQueue.sync {
            self.messageTapped = status
        }
    }

    private func tapped(at indexPath: IndexPath) {
        switch viewModel.locationViewMode {
        case .singleMessage:
            if let message = viewModel.item(index: indexPath) {
                tappedMessage(message)
            }
        case .conversation:
            // TODO: navigate to conversation view
            break
        }
    }
    
    private func tappedMessage(_ message: Message) {
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
            
            showProgressHud()
            self.viewModel.messageService.ForcefetchDetailForMessage(message, runInQueue: false) { [weak self] _, _, msg, error in
                self?.hideProgressHud()
                guard let objectId = msg?.objectID,
                      let message = self?.viewModel.object(by: objectId),
                      message.body.isEmpty == false else
                {
                    if error != nil {
                        PMLog.D("error: \(String(describing: error))")
                        let alert = LocalString._unable_to_edit_offline.alertController()
                        alert.addOKAction()
                        self?.present(alert, animated: true, completion: nil)
                        self?.tableView.indexPathsForSelectedRows?.forEach {
                            self?.tableView.deselectRow(at: $0, animated: true)
                        }
                    }
                    self?.updateTapped(status: false)
                    return
                }
                
                if self?.checkHuman() == true {
                    self?.coordinator?.go(to: .composeShow, sender: message)
                    self?.tableView.indexPathsForSelectedRows?.forEach {
                        self?.tableView.deselectRow(at: $0, animated: true)
                    }
                }
                self?.updateTapped(status: false)
            }
        }
        
    }

    private func setupLeftButtons(_ editingMode: Bool) {
        var leftButtons: [UIBarButtonItem]
        
        if (!editingMode) {
            leftButtons = [self.menuBarButtonItem]
        } else {
            leftButtons = []
        }
        
        self.navigationItem.setLeftBarButtonItems(leftButtons, animated: true)
    }
    
    private func setupNavigationTitle(_ editingMode: Bool) {
        if (editingMode) {
            let count = self.viewModel.selectedIDs.count
            self.setNavigationTitleText("\(count) " + LocalString._selected_navogationTitle)
        } else {
            self.setNavigationTitleText(viewModel.localizedNavigationTitle)
        }
    }
    
    private func BarItem(image: UIImage?, action: Selector? ) -> UIBarButtonItem {
       return  UIBarButtonItem(image: image, style: UIBarButtonItem.Style.plain, target: self, action: action)
    }
    
    private func setupRightButtons(_ editingMode: Bool) {
        if editingMode {
            if self.cancelBarButtonItem == nil {
                let item = UIBarButtonItem(title: LocalString._general_cancel_button,
                                           style: UIBarButtonItem.Style.plain,
                                           target: self,
                                           action: #selector(cancelButtonTapped))
                item.tintColor = UIColorManager.BrandNorm
                self.cancelBarButtonItem = item
            }
            self.navigationItem.setRightBarButtonItems([self.cancelBarButtonItem],
                                                       animated: true)
            return
        }

        if self.composeBarButtonItem == nil {
            let button = Asset.composeIcon.image.toUIBarButtonItem(
                target: self,
                action: #selector(composeButtonTapped),
                tintColor: UIColorManager.IconNorm,
                backgroundSquareSize: 40
            )
            self.composeBarButtonItem = button
            self.composeBarButtonItem.accessibilityLabel = LocalString._composer_compose_action
        }
        
        if self.storageExceededBarButtonItem == nil {
            let button = Asset.composeIcon.image.toUIBarButtonItem(
                target: self,
                action: #selector(storageExceededButtonTapped),
                tintColor: UIColorManager.Shade50,
                backgroundSquareSize: 40
            )
            self.storageExceededBarButtonItem = button
            self.storageExceededBarButtonItem.accessibilityLabel = LocalString._storage_exceeded
        }
        
        if self.searchBarButtonItem == nil {
            let button = Asset.searchIcon.image.toUIBarButtonItem(
                target: self,
                action: #selector(searchButtonTapped),
                tintColor: UIColorManager.IconNorm,
                backgroundSquareSize: 40
            )
            self.searchBarButtonItem = button
            self.searchBarButtonItem.accessibilityLabel = LocalString._general_search_placeholder
        }

        let item: UIBarButtonItem = self.viewModel.user.isStorageExceeded ? self.storageExceededBarButtonItem: self.composeBarButtonItem
        let rightButtons: [UIBarButtonItem] = [item, self.searchBarButtonItem]
        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
    }
    
    private func hideCheckOptions() {
        guard listEditing else { return }
        self.listEditing = false
        if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
            self.tableView.reloadRows(at: indexPathsForVisibleRows, with: .automatic)
        }
    }

    private func enterListEditingMode(indexPath: IndexPath) {
        self.listEditing = true

        guard let visibleRowsIndexPaths = self.tableView.indexPathsForVisibleRows else { return }
        visibleRowsIndexPaths.forEach { visibleRowIndexPath in
            let visibleCell = self.tableView.cellForRow(at: visibleRowIndexPath)
            guard let messageCell = visibleCell as? NewMailboxMessageCell else { return }
            messageCellPresenter.presentSelectionStyle(style: .selection(isSelected: false), in: messageCell.customView)
            guard indexPath == visibleRowIndexPath else { return }
            tableView(tableView, didSelectRowAt: indexPath)
        }

        PMLog.D("Long press on table view at row \(indexPath.row)")
    }
    
    private func showCheckOptions(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let point: CGPoint = longPressGestureRecognizer.location(in: self.tableView)
        let indexPath: IndexPath? = self.tableView.indexPathForRow(at: point)
        guard let touchedRowIndexPath = indexPath,
              longPressGestureRecognizer.state == .began && listEditing == false else { return }
        enterListEditingMode(indexPath: touchedRowIndexPath)
    }
    
    private func updateNavigationController(_ editingMode: Bool) {
        self.isEditingMode = editingMode
        self.setupLeftButtons(editingMode)
        self.setupNavigationTitle(editingMode)
        self.setupRightButtons(editingMode)
    }
 
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // TODO: refactor SearchViewController to have Coordinator and properly inject this hunk
        if let search = (segue.destination as? UINavigationController)?.topViewController as? SearchViewController {
            let viewModel = self.viewModel.getSearchViewModel(uiDelegate: search)
            search.set(viewModel: viewModel)
        }
        super.prepare(for: segue, sender: sender)
    }
    
    private func retry(delay: Double = 0) {
        // When network reconnect, the DNS data seems will miss at a short time
        // Delay 5 seconds to retry can prevent some relative error
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.getLatestMessages()
        }
    }
    
    private func updateUnreadButton() {
        let unread = viewModel.lastUpdateTime()?.unread ?? 0
        let isInUnreadFilter = unreadFilterButton.isSelected
        unreadFilterButton.backgroundColor = isInUnreadFilter ? UIColorManager.BrandNorm : UIColorManager.BackgroundSecondary
        unreadFilterButton.isHidden = isInUnreadFilter ? false : unread == 0
        let number = unread > 9999 ? " +9999" : "\(unread)"

        if isInUnreadFilter {
            var selectedAttributes = FontManager.CaptionStrong
            selectedAttributes[.foregroundColor] = UIColorManager.TextInverted

            unreadFilterButton.setAttributedTitle("\(number) \(LocalString._unread_action) ".apply(style: selectedAttributes),
                                                  for: .selected)
        } else {
            var normalAttributes = FontManager.CaptionStrong
            normalAttributes[.foregroundColor] = UIColorManager.BrandNorm

            unreadFilterButton.setAttributedTitle("\(number) \(LocalString._unread_action) ".apply(style: normalAttributes),
                                                  for: .normal)
        }

        let titleWidth = unreadFilterButton.titleLabel?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width ?? 0.0
        let width = titleWidth + 16 + (isInUnreadFilter ? 16 : 0)
        unreadFilterButtonWidth.constant = width
    }
    
    private func updateLastUpdateTimeLabel() {
        if let status = self.lastNetworkStatus, status == .NotReachable {
            var attribute = FontManager.CaptionHint
            attribute[.foregroundColor] = UIColorManager.NotificationError
            updateTimeLabel.attributedText = NSAttributedString(string: LocalString._mailbox_offline_text, attributes: attribute)
            return
        }
        
        let timeText = self.viewModel.getLastUpdateTimeText()
        updateTimeLabel.attributedText = NSAttributedString(string: timeText, attributes: FontManager.CaptionHint)
    }

    private func configureBannerContainer() {
        let bannerContainer = UIView(frame: .zero)

        view.addSubview(bannerContainer)
        view.bringSubviewToFront(topActionsView)

        [
            bannerContainer.topAnchor.constraint(equalTo: topActionsView.bottomAnchor),
            bannerContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            bannerContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ].activate()

        self.bannerContainer = bannerContainer
    }

    private func showInternetConnectionBanner() {
        guard let container = bannerContainer, isInternetBannerPresented == false,
              UIApplication.shared.applicationState == .active else { return }
        hideAllBanners()
        let banner = MailBannerView()

        container.addSubview(banner)

        banner.label.attributedText = LocalString._banner_no_internet_connection
            .apply(style: FontManager.body3RegularTextInverted)

        [
            banner.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            banner.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ].activate()

        bannerShowConstrain = container.topAnchor.constraint(equalTo: banner.topAnchor)

        view.layoutIfNeeded()

        bannerShowConstrain?.isActive = true

        isInternetBannerPresented = true
        tableView.contentInset.top = banner.frame.size.height

        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.view.layoutIfNeeded()

            guard self?.tableView.contentOffset.y == 0 else { return }
            self?.tableView.contentOffset.y = -banner.frame.size.height
        }
    }

    private func hideAllBanners() {
        view.subviews
            .compactMap { $0 as? PMBanner }
            .forEach { $0.dismiss(animated: true) }
    }

    private func hideInternetConnectionBanner() {
        guard isInternetBannerPresented == true, isHidingBanner == false else { return }
        isHidingBanner = true
        isInternetBannerPresented = false
        bannerShowConstrain?.isActive = false
        UIView.animate(withDuration: 0.25, animations: { [weak self] in
            self?.view.layoutIfNeeded()
            self?.bannerContainer?.frame.size.height = 0
            self?.tableView.contentInset.top = .zero
        }, completion: { _ in
            self.bannerContainer?.subviews.forEach { $0.removeFromSuperview() }
            self.isHidingBanner = false
        })
    }

    private func handleShadow(isScrolled: Bool) {
        isScrolled ? topActionsView.layer.apply(shadow: .default) : topActionsView.layer.clearShadow()
    }

    private func deleteExpiredMessages() {
        viewModel.user.messageService.deleteExpiredMessage(completion: nil)
    }
}

// MARK: - Action bar
extension MailboxViewController {
    private func showActionBar() {
        guard self.mailActionBar == nil else {
            return
        }
        let actions = self.viewModel.getActionTypes()
        var actionItems: [PMActionBarItem] = []
        
        for (key, action) in actions.enumerated() {
            
            let actionHandler: (PMActionBarItem) -> Void = { [weak self] _ in
                guard let self = self else { return }
                if action == .more {
                    self.moreButtonTapped()
                } else {
                    guard !self.viewModel.selectedIDs.isEmpty else {
                        self.showNoEmailSelected(title: LocalString._warning)
                        return
                    }
                    switch action {
                    case .delete:
                        self.showDeleteAlert { [weak self] in
                            guard let `self` = self else { return }
                            self.viewModel.handleBarActions(action,
                                                            selectedIDs: NSMutableSet(set: self.viewModel.selectedIDs))
                            self.showMessageMoved(title: LocalString._messages_has_been_deleted)
                        }
                    case .moveTo:
                        self.folderButtonTapped()
                    case .labelAs:
                        self.labelButtonTapped()
                    default:
                        let temp = NSMutableSet(set: self.viewModel.selectedIDs)
                        self.viewModel.handleBarActions(action, selectedIDs: temp)
                        if action != .readUnread {
                            self.showMessageMoved(title: LocalString._messages_has_been_moved)
                        }
                        self.cancelButtonTapped()
                    }
                }
            }
            
            if key == actions.startIndex {
                let barItem = PMActionBarItem(icon: action.iconImage.withRenderingMode(.alwaysTemplate),
                                              text: action.name,
                                              itemColor: UIColorManager.TextInverted,
                                              handler: actionHandler)
                actionItems.append(barItem)
            } else {
                let barItem = PMActionBarItem(icon: action.iconImage.withRenderingMode(.alwaysTemplate),
                                              backgroundColor: .clear,
                                              handler: actionHandler)
                actionItems.append(barItem)
            }
        }
        let separator = PMActionBarItem(width: 1,
                                        verticalPadding: 6,
                                        color: UIColorManager.FloatyText)
        actionItems.insert(separator, at: 1)
        self.mailActionBar = PMActionBar(items: actionItems,
                                         backgroundColor: UIColorManager.FloatyBackground,
                                         floatingHeight: 42.0,
                                         width: .fit,
                                         height: 48.0)
        self.mailActionBar?.show(at: self)
    }
    
    private func hideActionBar() {
        self.mailActionBar?.dismiss()
        self.mailActionBar = nil
    }
    
    private func hideActionSheet() {
        self.actionSheet?.dismiss(animated: true)
        self.actionSheet = nil
    }

    private func showDeleteAlert(yesHandler: @escaping () -> Void) {
        let messagesCount = viewModel.selectedIDs.count
        let title = messagesCount > 1 ?
            String(format: LocalString._messages_delete_confirmation_alert_title, messagesCount) :
            LocalString._single_message_delete_confirmation_alert_title
        let message = messagesCount > 1 ?
            String(format: LocalString._messages_delete_confirmation_alert_message, messagesCount) :
            LocalString._single_message_delete_confirmation_alert_message
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        let yes = UIAlertAction(title: LocalString._general_delete_action, style: .destructive) { [weak self] _ in
            yesHandler()
            self?.cancelButtonTapped()
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel) { [weak self] _ in
            self?.cancelButtonTapped()
        }
        [yes, cancel].forEach(alert.addAction)
        present(alert, animated: true, completion: nil)
    }

    @objc
    private func handleAccessibilityAction() {
        listEditing.toggle()
        updateNavigationController(listEditing)
        if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows {
            tableView.reloadRows(at: indexPathsForVisibleRows, with: .automatic)
        }
    }

    func moreButtonTapped() {
        mailListActionSheetPresenter.present(
            on: navigationController ?? self,
            viewModel: viewModel.actionSheetViewModel,
            action: { [weak self] in
                self?.viewModel.handleActionSheetAction($0)
                self?.handleActionSheetAction($0)
            }
        )
    }
}

extension MailboxViewController: LabelAsActionSheetPresentProtocol {
    var labelAsActionHandler: LabelAsActionSheetProtocol {
        return viewModel
    }

    func labelButtonTapped() {
        guard !viewModel.selectedIDs.isEmpty else {
            showNoEmailSelected(title: LocalString._apply_labels)
            return
        }
        switch viewModel.locationViewMode {
        case .conversation:
            showLabelAsActionSheet(conversations: viewModel.selectedConversations)
        case .singleMessage:
            showLabelAsActionSheet(messages: viewModel.selectedMessages)
        }
    }

    private func showLabelAsActionSheet(messages: [Message]) {
        let labelAsViewModel = LabelAsActionSheetViewModelMessages(menuLabels: labelAsActionHandler.getLabelMenuItems(),
                                                                   messages: messages)

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        self?.coordinator?.pendingActionAfterDismissal = { [weak self] in
                            self?.showLabelAsActionSheet(messages: messages)
                        }
                        self?.coordinator?.go(to: .newLabel)
                     },
                     selected: { [weak self] menuLabel, isOn in
                        self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                        if isHavingUnsavedChanges {
                            self?.showDiscardAlert(handleDiscard: {
                                self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: nil, isOn: false)
                                self?.dismissActionSheet()
                            })
                        } else {
                            self?.dismissActionSheet()
                        }
                     },
                     done: { [weak self] isArchive, currentOptionsStatus in
                        self?.labelAsActionHandler
                            .handleLabelAsAction(messages: messages,
                                                 shouldArchive: isArchive,
                                                 currentOptionsStatus: currentOptionsStatus)
                        self?.dismissActionSheet()
                        self?.cancelButtonTapped()
                     })
    }
    
    private func showLabelAsActionSheet(conversations: [Conversation]) {
        let labelAsViewModel = LabelAsActionSheetViewModelConversations(menuLabels: labelAsActionHandler.getLabelMenuItems(),
                                                                        conversations: conversations)

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        self?.coordinator?.pendingActionAfterDismissal = { [weak self] in
                            self?.showLabelAsActionSheet(conversations: conversations)
                        }
                        self?.coordinator?.go(to: .newLabel)
                     },
                     selected: { [weak self] menuLabel, isOn in
                        self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                        if isHavingUnsavedChanges {
                            self?.showDiscardAlert(handleDiscard: {
                                self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: nil, isOn: false)
                                self?.dismissActionSheet()
                            })
                        } else {
                            self?.dismissActionSheet()
                        }
                     },
                     done: { [weak self] isArchive, currentOptionsStatus in
                        self?.labelAsActionHandler
                            .handleLabelAsAction(conversations: conversations,
                                                 shouldArchive: isArchive,
                                                 currentOptionsStatus: currentOptionsStatus)
                        self?.dismissActionSheet()
                        self?.cancelButtonTapped()
                     })
    }
}

extension MailboxViewController: MoveToActionSheetPresentProtocol {
    var moveToActionHandler: MoveToActionSheetProtocol {
        return viewModel
    }

    func folderButtonTapped() {
        guard !self.viewModel.selectedIDs.isEmpty else {
            showNoEmailSelected(title: LocalString._apply_labels)
            return
        }

        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        let messages = viewModel.selectedMessages
        let conversations = viewModel.selectedConversations
        if !messages.isEmpty {
            showMoveToActionSheet(messages: messages,
                                  isEnableColor: isEnableColor,
                                  isInherit: isInherit)
        } else if !conversations.isEmpty {
            showMoveToActionSheet(conversations: conversations,
                                  isEnableColor: isEnableColor,
                                  isInherit: isInherit)
        }
    }

    private func showMoveToActionSheet(messages: [Message], isEnableColor: Bool, isInherit: Bool) {
        let moveToViewModel =
            MoveToActionSheetViewModelMessages(menuLabels: moveToActionHandler.getFolderMenuItems(),
                                               messages: messages,
                                               isEnableColor: isEnableColor,
                                               isInherit: isInherit,
                                               labelId: viewModel.labelId)
        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                        self?.coordinator?.pendingActionAfterDismissal = { [weak self] in
                            self?.showMoveToActionSheet(messages: messages, isEnableColor: isEnableColor, isInherit: isInherit)
                        }
                        self?.coordinator?.go(to: .newFolder)
                     },
                     selected: { [weak self] menuLabel, isOn in
                        self?.moveToActionHandler.updateSelectedMoveToDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                        if isHavingUnsavedChanges {
                            self?.showDiscardAlert(handleDiscard: {
                                self?.moveToActionHandler.updateSelectedMoveToDestination(menuLabel: nil, isOn: false)
                                self?.dismissActionSheet()
                            })
                        } else {
                            self?.dismissActionSheet()
                        }
                     },
                     done: { [weak self] isHavingUnsavedChanges in
                        defer {
                            self?.dismissActionSheet()
                            self?.cancelButtonTapped()
                        }
                        guard isHavingUnsavedChanges else {
                            return
                        }
                        self?.moveToActionHandler.handleMoveToAction(messages: messages)
                     })
    }

    private func showMoveToActionSheet(conversations: [Conversation], isEnableColor: Bool, isInherit: Bool) {
        let moveToViewModel =
            MoveToActionSheetViewModelConversations(menuLabels: moveToActionHandler.getFolderMenuItems(),
                                                    conversations: conversations,
                                                    isEnableColor: isEnableColor,
                                                    isInherit: isInherit,
                                                    labelId: viewModel.labelId)
        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                        self?.coordinator?.pendingActionAfterDismissal = { [weak self] in
                            self?.showMoveToActionSheet(conversations: conversations, isEnableColor: isEnableColor, isInherit: isInherit)
                        }
                        self?.coordinator?.go(to: .newFolder)
                     },
                     selected: { [weak self] menuLabel, isOn in
                        self?.moveToActionHandler.updateSelectedMoveToDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                        if isHavingUnsavedChanges {
                            self?.showDiscardAlert(handleDiscard: {
                                self?.moveToActionHandler.updateSelectedMoveToDestination(menuLabel: nil, isOn: false)
                                self?.dismissActionSheet()
                            })
                        } else {
                            self?.dismissActionSheet()
                        }
                     },
                     done: { [weak self] isHavingUnsavedChanges in
                        defer {
                            self?.dismissActionSheet()
                            self?.cancelButtonTapped()
                        }
                        guard isHavingUnsavedChanges else {
                            return
                        }
                        self?.moveToActionHandler.handleMoveToAction(conversations: conversations)
                     })
    }

    private func handleActionSheetAction(_ action: MailListSheetAction) {
        switch action {
        case .dismiss:
            dismissActionSheet()
        case .remove, .moveToArchive, .moveToSpam, .moveToInbox:
            showMessageMoved(title: LocalString._messages_has_been_moved)
            cancelButtonTapped()
        case .markRead, .markUnread, .star, .unstar:
            cancelButtonTapped()
        case .delete:
            showDeleteAlert { [weak self] in
                guard let `self` = self else { return }
                self.viewModel.delete(IDs: NSMutableSet(set: self.viewModel.selectedIDs))
            }
        case .labelAs:
            labelButtonTapped()
        case .moveTo:
            folderButtonTapped()
        }
    }
}

// MARK: - MailboxCaptchaVCDelegate
extension MailboxViewController : MailboxCaptchaVCDelegate {
    
    func cancel() {
        isCheckingHuman = false
    }
    
    func done() {
        isCheckingHuman = false
        self.viewModel.isRequiredHumanCheck = false
    }
}

// MARK: - Show banner or alert
extension MailboxViewController {
    private func showErrorMessage(_ error: NSError?) {
        guard let error = error, UIApplication.shared.applicationState == .active else { return }
        let banner = PMBanner(message: error.localizedDescription, style: PMBannerNewStyle.error, dismissDuration: Double.infinity)
        banner.show(at: .top, on: self)
    }

    private func showTimeOutErrorMessage() {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(message: LocalString._general_request_timed_out, style: PMBannerNewStyle.error, dismissDuration: 5.0)
        banner.addButton(text: LocalString._retry) { _ in
            banner.dismiss()
            self.getLatestMessages()
        }
        banner.show(at: .top, on: self)
    }

    private func showNoInternetErrorMessage() {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(message: LocalString._general_no_connectivity_detected, style: PMBannerNewStyle.error, dismissDuration: 5.0)
        banner.addButton(text: LocalString._retry) { _ in
            banner.dismiss()
            self.getLatestMessages()
        }
        banner.show(at: .top, on: self)
    }

    internal func showOfflineErrorMessage(_ error : NSError?) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(message: error?.localizedDescription ?? LocalString._general_pm_offline, style: PMBannerNewStyle.error, dismissDuration: 5.0)
        banner.addButton(text: LocalString._retry) { _ in
            banner.dismiss()
            self.getLatestMessages()
        }
        banner.show(at: .top, on: self)
    }

    private func show503ErrorMessage(_ error : NSError?) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(message: LocalString._general_api_server_not_reachable, style: PMBannerNewStyle.error, dismissDuration: 5.0)
        banner.addButton(text: LocalString._retry) { _ in
            banner.dismiss()
            self.getLatestMessages()
        }
        banner.show(at: .top, on: self)
    }

    private func showError(_ error : NSError) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(message: "We could not connect to the servers. Pull down to retry.", style: PMBannerNewStyle.error, dismissDuration: 5.0)
        banner.addButton(text: "Learn more") { _ in
            banner.dismiss()
            self.goTroubleshoot()
        }
        banner.show(at: .top, on: self)
    }
    
    private func showNewMessageCount(_ count : Int) {
        guard self.needToShowNewMessage, count > 0 else { return }
        self.needToShowNewMessage = false
        self.newMessageCount = 0
        let message = count == 1 ? LocalString._messages_you_have_new_email : String(format: LocalString._messages_you_have_new_emails_with, count)
        message.alertToastBottom()
    }
    
    private func hideTopMessage() {
        self.topMessageView?.remove(animated: true)
    }
}

// MARK: - Handle Network status changed
extension MailboxViewController {
    @objc private func reachabilityChanged(_ note : Notification) {
        if let currentReachability = note.object as? Reachability {
            self.updateInterface(reachability: currentReachability)
        } else {
            if let status = note.object as? Int, sharedInternetReachability.currentReachabilityStatus() != .NotReachable {
                PMLog.D("\(status)")
                DispatchQueue.main.async {
                    if status == 0 { //time out
                        self.showTimeOutErrorMessage()
                        self.hasNetworking = false
                    } else if status == 1 { //not reachable
                        self.showNoInternetErrorMessage()
                        self.hasNetworking = false
                    }
                }
            }
        }
    }
    
    private func updateInterface(reachability: Reachability) {
        let netStatus = reachability.currentReachabilityStatus()
        switch netStatus {
        case .NotReachable:
            PMLog.D("Access Not Available")
            self.showNoInternetErrorMessage()
            self.hasNetworking = false
            self.showInternetConnectionBanner()
            self.hasNetworking = false
        case .ReachableViaWWAN:
            PMLog.D("Reachable WWAN")
            self.hideInternetConnectionBanner()
            self.afterNetworkChange(status: netStatus)
            self.hasNetworking = true
        case .ReachableViaWiFi:
            PMLog.D("Reachable WiFi")
            self.hideInternetConnectionBanner()
            self.afterNetworkChange(status: netStatus)
            self.hasNetworking = true
        default:
            PMLog.D("Reachable default unknow")
        }
        lastNetworkStatus = netStatus
        
        self.updateLastUpdateTimeLabel()
    }
    
    private func afterNetworkChange(status: NetworkStatus) {
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
}

// MARK: - UITableViewDataSource
extension MailboxViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        if self.shouldAnimateSkeletonLoading {
            return 1
        } else {
            return self.viewModel.sectionCount()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.shouldAnimateSkeletonLoading {
            return 10
        } else {
            return self.viewModel.rowCount(section: section)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = self.shouldAnimateSkeletonLoading ? MailBoxSkeletonLoadingCell.Constant.identifier : NewMailboxMessageCell.defaultID()
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        if self.shouldAnimateSkeletonLoading {
            cell.showAnimatedGradientSkeleton()
        } else {
            self.configure(cell: cell, indexPath: indexPath)
        }
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
        
        if controller == self.viewModel.unreadFetchedResult {
            self.updateUnreadButton()
            return
        }

        if shouldKeepSkeletonUntilManualDismissal {
            return
        }
        
        self.tableView.reloadData()
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
        self.showNewMessageCount(self.newMessageCount)
        self.updateLastUpdateTimeLabel()
        self.showNoResultLabel()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == self.viewModel.labelFetchedResults || controller == self.viewModel.unreadFetchedResult {
            return
        }
        
        if self.shouldAnimateSkeletonLoading {
            if !shouldKeepSkeletonUntilManualDismissal {
                self.shouldAnimateSkeletonLoading = false
            }
            self.updateTimeLabel.hideSkeleton()
            self.unreadFilterButton.titleLabel?.hideSkeleton()
            self.updateUnreadButton()
            
            self.tableView.reloadData()
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if controller == self.viewModel.labelFetchedResults
        || controller == self.viewModel.unreadFetchedResult
        || shouldKeepSkeletonUntilManualDismissal {
            return
        }

        switch(type) {
        case .delete:
            popPresentedItemIfNeeded(anObject)
        case .insert:
            guard let _ = newIndexPath,
                  self.needToShowNewMessage,
                  let newMsg = anObject as? Message,
                  let msgTime = newMsg.time, newMsg.unRead,
                  let updateTime = viewModel.lastUpdateTime(),
                  msgTime.compare(updateTime.startTime) != ComparisonResult.orderedAscending else { return }
            self.newMessageCount += 1
        default:
            return
        }
    }
}

// MARK: - Popping Handling
extension MailboxViewController {
    private func popPresentedItemIfNeeded(_ anObject: Any) {
        /*
         When the unread filter is enable and we enter message or conversation detail view,
         the message or conversation will be set to read.
         This action results in the message or conversation will be removed from the list.
         And will trigger the detail view to be popped.
         */
        guard !unreadFilterButton.isSelected else {
            return
        }
        if navigationController?.topViewController is ConversationViewController
            || navigationController?.topViewController is SingleMessageViewController {
            if let contextLabel = anObject as? ContextLabel {
                if contextLabel.messageCount.intValue != 0 {
                    return
                }
                if coordinator?.conversationCoordinator?.conversation.conversationID == contextLabel.conversationID {
                    navigationController?.popViewController(animated: true)
                }
            }
            if let message = anObject as? Message {
                if coordinator?.singleMessageCoordinator?.message.messageID == message.messageID {
                    navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension MailboxViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let updateTime = viewModel.lastUpdateTime(), let currentTime = viewModel.getTimeOfItem(at: indexPath) {
            
            let endTime = self.isShowingUnreadMessageOnly ? updateTime.unreadEndTime : updateTime.endTime
            let totalMessage = self.isShowingUnreadMessageOnly ? Int(updateTime.unread) : Int(updateTime.total)
            let isNew = self.isShowingUnreadMessageOnly ? updateTime.isUnreadNew : updateTime.isNew
            
            
            let isOlderMessage = endTime.compare(currentTime) != ComparisonResult.orderedAscending
            let loadMore = self.viewModel.loadMore(index: indexPath)
            if  (isOlderMessage || loadMore) && !self.fetchingOlder && !isSwipingCell {
                let sectionCount = self.viewModel.rowCount(section: indexPath.section)
                let recordedCount = totalMessage
                //here need add a counter to check if tried too many times make one real call in case count not right
                if isNew || recordedCount > sectionCount {
                    self.fetchingOlder = true
                    if !refreshControl.isRefreshing {
                        self.tableView.showLoadingFooter()
                    }
                    let unixTimt: Int = (endTime == Date.distantPast ) ? 0 : Int(endTime.timeIntervalSince1970)
                    self.viewModel.fetchMessages(time: unixTimt, forceClean: false, isUnread: self.isShowingUnreadMessageOnly, completion: { (task, response, error) -> Void in
                        DispatchQueue.main.async {
                            self.tableView.hideLoadingFooter()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                            self.showNoResultLabel()
                        }
                        self.fetchingOlder = false
                        self.checkHuman()
                    })
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.shouldAnimateSkeletonLoading {
            return 90.0
        } else {
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !shouldAnimateSkeletonLoading
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch viewModel.locationViewMode {
        case .singleMessage:
            handleMessageSelection(indexPath: indexPath)
        case .conversation:
            handleConversationSelection(indexPath: indexPath)
        }
    }

    private func handleMessageSelection(indexPath: IndexPath) {
        guard let message = viewModel.item(index: indexPath) else { return }
        if listEditing {
            handleEditingDataSelection(of: message.messageID, indexPath: indexPath)
        } else {
            self.indexPathForSelectedRow = indexPath
            self.tapped(at: indexPath)
        }
    }

    private func handleConversationSelection(indexPath: IndexPath) {
        guard let conversation = viewModel.itemOfConversation(index: indexPath) else { return }
        if listEditing {
            handleEditingDataSelection(of: conversation.conversationID, indexPath: indexPath)
        } else {
            self.coordinator?.go(to: .details)
        }
    }

    private func handleEditingDataSelection(of id: String, indexPath: IndexPath) {
        let itemAlreadySelected = viewModel.selectionContains(id: id)
        let selectionAction = itemAlreadySelected ? viewModel.removeSelected : viewModel.select
        selectionAction(id)

        if viewModel.selectedIDs.isEmpty {
            hideActionBar()
        } else {
            showActionBar()
        }

        // update checkbox state
        if let mailboxCell = tableView.cellForRow(at: indexPath) as? NewMailboxMessageCell {
            messageCellPresenter.presentSelectionStyle(
                style: .selection(isSelected: !itemAlreadySelected),
                in: mailboxCell.customView
            )
        }

        tableView.deselectRow(at: indexPath, animated: true)
        self.setupNavigationTitle(true)
    }
}

extension MailboxViewController: NewMailboxMessageCellDelegate {
    func getExpirationDate(id: String) -> String? {
        let tappedCell = tableView.visibleCells
            .compactMap { $0 as? NewMailboxMessageCell }
            .first(where: { $0.id == id })
        guard let cell = tappedCell,
              let indexPath = tableView.indexPath(for: cell),
              let expirationTime = viewModel.item(index: indexPath)?.expirationTime else { return nil }
        return expirationTime.countExpirationTime
    }

    func didSelectButtonStatusChange(id: String?) {
        let tappedCell = tableView.visibleCells
            .compactMap { $0 as? NewMailboxMessageCell }
            .first(where: { $0.id == id })
        guard let cell = tappedCell, let indexPath = tableView.indexPath(for: cell) else { return }

        if !listEditing {
            self.enterListEditingMode(indexPath: indexPath)
            updateNavigationController(listEditing)
        } else {
            tableView(self.tableView, didSelectRowAt: indexPath)
        }
    }
}

extension MailboxViewController {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if refreshControl.isRefreshing {
            self.pullDown()
        }
    }

    private func configureUnreadFilterButton() {
        self.unreadFilterButton.setTitleColor(UIColorManager.BrandNorm, for: .normal)
        self.unreadFilterButton.setTitleColor(UIColorManager.BackgroundNorm, for: .selected)
        self.unreadFilterButton.setImage(Asset.mailLabelCrossIcon.image, for: .selected)
        self.unreadFilterButton.semanticContentAttribute = .forceRightToLeft
        self.unreadFilterButton.titleLabel?.isSkeletonable = true
        self.unreadFilterButton.titleLabel?.font = UIFont.systemFont(ofSize: 13.0)
        self.unreadFilterButton.translatesAutoresizingMaskIntoConstraints = false
        self.unreadFilterButton.layer.cornerRadius = self.unreadFilterButton.frame.height / 2
        self.unreadFilterButton.layer.masksToBounds = true
        self.unreadFilterButton.backgroundColor = UIColorManager.BackgroundSecondary
        self.unreadFilterButton.isSelected = viewModel.isCurrentUserSelectedUnreadFilterInInbox
    }
}

extension MailboxViewController: Deeplinkable {
    var deeplinkNode: DeepLink.Node {
        return DeepLink.Node(name: String(describing: MailboxViewController.self), value: self.viewModel.labelID)
    }
}

extension MailboxViewController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return MailBoxSkeletonLoadingCell.Constant.identifier
    }
}

extension MailboxViewController: EventsConsumer {
    func shouldCallFetchEvents() {
        guard self.hasNetworking, !fetchingMessage else { return }
        getLatestMessages()
    }
}

extension MailboxViewController: SwipyCellDelegate {
    func swipyCellDidStartSwiping(_ cell: SwipyCell) {
        tableView.visibleCells.filter({ $0 != cell }).forEach { cell in
            if let swipyCell = cell as? SwipyCell {
                swipyCell.gestureRecognizers?.compactMap({ $0 as? UIPanGestureRecognizer }).forEach({ $0.isEnabled = false })
            }
        }
    }

    func swipyCellDidFinishSwiping(_ cell: SwipyCell, atState state: SwipyCellState, triggerActivated activated: Bool) {
        tableView.visibleCells.forEach { cell in
            if let swipyCell = cell as? SwipyCell {
                swipyCell.gestureRecognizers?.compactMap({ $0 as? UIPanGestureRecognizer }).forEach({ $0.isEnabled = true })
            }
        }
    }

    func swipyCell(_ cell: SwipyCell, didSwipeWithPercentage percentage: CGFloat, currentState state: SwipyCellState, triggerActivated activated: Bool) {

    }
}
