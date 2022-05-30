//
//  MailboxViewController.swift
//  Proton Mail - Created on 8/16/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Alamofire
import CoreData
import ProtonCore_DataModel
import ProtonCore_Services
import ProtonCore_UIFoundations
import SkeletonView
import SwipyCell
import UIKit

class MailboxViewController: ProtonMailViewController, ViewModelProtocol, CoordinatedNew, ComposeSaveHintProtocol, UserFeedbackSubmittableProtocol {

    typealias viewModelType = MailboxViewModel
    typealias coordinatorType = MailboxCoordinator

    private(set) var viewModel: MailboxViewModel!

    private weak var coordinator: MailboxCoordinator?

    func set(coordinator: MailboxCoordinator) {
        self.coordinator = coordinator
    }

    func set(viewModel: MailboxViewModel) {
        self.viewModel = viewModel
    }

    lazy var replacingEmails: [Email] = viewModel.allEmails

    var listEditing: Bool = false

    // MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Private constants
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds

    // MARK: TopActions
    @IBOutlet weak var topActionsView: UIView!
    @IBOutlet weak var updateTimeLabel: UILabel!
    @IBOutlet weak var unreadFilterButton: UIButton!
    @IBOutlet weak var unreadFilterButtonWidth: NSLayoutConstraint!

    // MARK: PMToolBarView
    @IBOutlet private var toolBar: PMToolBarView!

    // MARK: - Private attributes

    private var bannerContainer: UIView?
    private var bannerShowConstrain: NSLayoutConstraint?
    private var isInternetBannerPresented = false
    private var isHidingBanner = false

    private var fetchingOlder: Bool = false

    private var isCheckingHuman: Bool = false

    private var fetchingMessage: Bool = false
    private var fetchingStopped: Bool = true
    private var needToShowNewMessage: Bool = false
    private var newMessageCount = 0
    private var hasNetworking = true
    private var isFirstFetch = true
    private var isEditingMode = true

    // MAKR : - Private views
    private var refreshControl: UIRefreshControl!
    private var navigationTitleLabel = UILabel()

    // MARK: - Left bar button
    private var menuBarButtonItem: UIBarButtonItem!

    // MARK: - No result image and label
    @IBOutlet weak var noResultImage: UIImageView!
    @IBOutlet weak var noResultMainLabel: UILabel!
    @IBOutlet weak var noResultSecondaryLabel: UILabel!
    @IBOutlet weak var noResultFooterLabel: UILabel!
    
    private var lastNetworkStatus: ConnectionStatus? = nil
    
    private var shouldAnimateSkeletonLoading = false
    private var shouldKeepSkeletonUntilManualDismissal = false
    private var isShowingUnreadMessageOnly: Bool {
        return self.unreadFilterButton.isSelected
    }

    private let messageCellPresenter = NewMailboxMessageCellPresenter()
    private let mailListActionSheetPresenter = MailListActionSheetPresenter()
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()

    private var screenEdgeGestureRecognizer: UIScreenEdgePanGestureRecognizer?

    private var isSwipingCell = false

    private var notificationsAreScheduled = false

    /// Setting this value to `true` will schedule an user feedback sheet on the next view did appear call
    var scheduleUserFeedbackCallOnAppear = false

    private var inAppFeedbackScheduler: InAppFeedbackPromptScheduler?

    private var customUnreadFilterElement: UIAccessibilityElement?
    private var diffableDataSource: MailboxDataSource?
    private var isDiffableDataSourceEnabled: Bool = false

    let connectionStatusProvider = InternetConnectionStatusProvider()

    private let hapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

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

        inAppFeedbackScheduler?.markAsInForeground()
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
        self.reloadTableViewDataSource(animate: false)
    }

    override var prefersStatusBarHidden: Bool {
        false
    }

    // MARK: - UIViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(self.viewModel != nil)
        assert(self.coordinator != nil)
        emptyBackButtonTitleForNextView()

        self.isDiffableDataSourceEnabled = UserInfo.isDiffableDataSourceEnabled
        self.viewModel.viewModeIsChanged = { [weak self] in
            self?.handleViewModeIsChanged()
        }

        self.viewModel.sendHapticFeedback = { [weak self] in
            self?.hapticFeedbackGenerator.impactOccurred()
        }

        configureUnreadFilterButton()

        if [Message.Location.spam,
            Message.Location.archive,
            Message.Location.trash,
            Message.Location.sent].map(\.labelID).contains(viewModel.labelID)
            && viewModel.isCurrentUserSelectedUnreadFilterInInbox {
            unreadMessageFilterButtonTapped(unreadFilterButton as Any)
        }

        self.viewModel.setupFetchController(self,
                                            isUnread: viewModel.isCurrentUserSelectedUnreadFilterInInbox)

        self.setNavigationTitleText(viewModel.localizedNavigationTitle)

        SkeletonAppearance.default.renderSingleLineAsView = true

        self.tableView.separatorColor = ColorProvider.InteractionWeak
        self.tableView.register(NewMailboxMessageCell.self, forCellReuseIdentifier: NewMailboxMessageCell.defaultID())
        self.tableView.RegisterCell(MailBoxSkeletonLoadingCell.Constant.identifier)
        if #available(iOS 15.0, *) {
            self.tableView.isPrefetchingEnabled = false
        }

        self.addSubViews()
        if self.isDiffableDataSourceEnabled, #available(iOS 13, *) {
            self.loadDiffableDataSource()
        } else {
            self.tableView.dataSource = self
        }

        self.updateNavigationController(listEditing)

        #if DEBUG
        if CommandLine.arguments.contains("-skipTour") {
            userCachedStatus.resetTourValue()
        }
        #endif
        if let destination = self.viewModel.getOnboardingDestination() {
            userCachedStatus.resetTourValue()
            self.coordinator?.go(to: destination)
        }

        // Setup top actions
        self.topActionsView.backgroundColor = ColorProvider.BackgroundNorm
        self.topActionsView.layer.zPosition = tableView.layer.zPosition + 1
        self.updateTimeLabel.textColor = ColorProvider.TextHint

        self.updateUnreadButton()
        self.updateLastUpdateTimeLabel()

        self.viewModel.cleanReviewItems()
        generateAccessibilityIdentifiers()
        configureBannerContainer()

        SwipyCellConfig.shared.triggerPoints.removeValue(forKey: -0.75)
        SwipyCellConfig.shared.triggerPoints.removeValue(forKey: 0.75)

        refetchAllIfNeeded()

        setupScreenEdgeGesture()
        setupAccessibility()

        inAppFeedbackScheduler = makeInAppFeedbackPromptScheduler()

        connectionStatusProvider.registerConnectionStatus { [weak self] newStatus in
            self?.updateInterface(connectionStatus: newStatus)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !notificationsAreScheduled {
            notificationsAreScheduled = true
            scheduleNotifications()
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
        viewModel.user.undoActionManager.register(handler: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        notificationsAreScheduled = false
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if #available(iOS 13.0, *) {
            self.view.window?.windowScene?.title = self.title ?? LocalString._locations_inbox_title
        }

        guard viewModel.isHavingUser else {
            return
        }

        self.viewModel.processCachedPush()
        self.viewModel.checkStorageIsCloseLimit()

        self.updateInterface(connectionStatus: connectionStatusProvider.currentStatus)
        
        let selectedItem: IndexPath? = self.tableView.indexPathForSelectedRow as IndexPath?
        if let selectedItem = selectedItem {
            if self.viewModel.isInDraftFolder {
                // updated draft should either be deleted or moved to top, so all the rows in between should be moved 1 position down
                let rowsToMove = (0...selectedItem.row).map { IndexPath(row: $0, section: 0) }
                self.refreshCells(at: rowsToMove, animation: .top)
            } else {
                self.refreshCells(at: [selectedItem], animation: .fade)
                self.tableView.deselectRow(at: selectedItem, animated: true)
            }
        }

        FileManager.default.cleanCachedAttsLegacy()

        checkHuman()

        showFeedbackViewIfNeeded()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        inAppFeedbackScheduler?.cancelScheduledPrompt()
    }

    private func setupScreenEdgeGesture() {
        let screenEdgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.openMenu))
        screenEdgeGesture.edges = .left
        view.addGestureRecognizer(screenEdgeGesture)
        self.screenEdgeGestureRecognizer = screenEdgeGesture
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: true, completion: nil )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }

    private func scheduleNotifications() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(doEnterForeground),
                                                   name: UIWindowScene.willEnterForegroundNotification,
                                                   object: nil)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(doEnterBackground),
                                                   name: UIWindowScene.didEnterBackgroundNotification,
                                                   object: nil)
        } else {
            NotificationCenter.default.addObserver(self,
                                                    selector: #selector(doEnterForeground),
                                                    name: UIApplication.willEnterForegroundNotification,
                                                    object: nil)

            NotificationCenter.default.addObserver(self,
                                                    selector: #selector(doEnterBackground),
                                                    name: UIApplication.didEnterBackgroundNotification,
                                                    object: nil)
        }
    }

    @available(iOS 13.0, *)
    private func loadDiffableDataSource() {
        let cellConfigurator = { [weak self] (tableView: UITableView, indexPath: IndexPath) -> UITableViewCell in
            let cellIdentifier = self?.shouldAnimateSkeletonLoading == true ? MailBoxSkeletonLoadingCell.Constant.identifier : NewMailboxMessageCell.defaultID()
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

            if self?.shouldAnimateSkeletonLoading == true {
                cell.showAnimatedGradientSkeleton()
                cell.backgroundColor = ColorProvider.BackgroundNorm
            } else {
                self?.configure(cell: cell, indexPath: indexPath)
            }
            return cell
        }
        switch viewModel.locationViewMode {
        case .singleMessage:
            self.diffableDataSource = MailboxDiffableDataSource<MessageEntity>(viewModel: viewModel,
                                                                         tableView: self.tableView,
                                                                         shouldAnimateSkeletonLoading: shouldAnimateSkeletonLoading,
                                                                         cellProvider: { tableView, indexPath, _ in
                cellConfigurator(tableView, indexPath)
            })
        case .conversation:
            self.diffableDataSource = MailboxDiffableDataSource<ConversationEntity>(viewModel: viewModel,
                                                                              tableView: self.tableView,
                                                                              shouldAnimateSkeletonLoading: shouldAnimateSkeletonLoading,
                                                                              cellProvider: { tableView, indexPath, _ in
                cellConfigurator(tableView, indexPath)
            })
        }
    }

    private func addSubViews() {
        self.navigationTitleLabel.backgroundColor = UIColor.clear
        self.navigationTitleLabel.font = Fonts.h3.semiBold
        self.navigationTitleLabel.textAlignment = NSTextAlignment.center
        self.navigationTitleLabel.textColor = ColorProvider.TextNorm
        self.navigationTitleLabel.text = self.title ?? LocalString._locations_inbox_title
        self.navigationTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationTitleLabel

        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = .clear
        self.refreshControl.addTarget(self, action: #selector(pullDown), for: UIControl.Event.valueChanged)
        self.refreshControl.tintColor = ColorProvider.IconAccent
        self.refreshControl.tintColorDidChange()

        self.view.backgroundColor = ColorProvider.BackgroundNorm

        self.tableView.addSubview(self.refreshControl)
        self.tableView.delegate = self
        self.tableView.noSeparatorsBelowFooter()

        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)

        setupMenuButton()
        self.menuBarButtonItem = self.navigationItem.leftBarButtonItem
        self.menuBarButtonItem.tintColor = ColorProvider.IconNorm

        self.noResultMainLabel.textColor = ColorProvider.TextNorm
        self.noResultMainLabel.isHidden = true

        self.noResultSecondaryLabel.textColor = ColorProvider.TextWeak
        self.noResultSecondaryLabel.isHidden = true

        self.noResultFooterLabel.textColor = ColorProvider.TextHint
        self.noResultFooterLabel.isHidden = true
        let attridutes = FontManager.CaptionHint
        self.noResultFooterLabel.attributedText = NSAttributedString(string: LocalString._mailbox_footer_no_result, attributes: attridutes)

        self.noResultImage.isHidden = true
        self.navigationItem.assignNavItemIndentifiers()
    }

    private func setupAccessibility() {
        // The unread button in the inbox is causing the navigation issue of VoiceOver. Resolve this issue by adding a custom accessibility element.
        unreadFilterButton.isAccessibilityElement = false
        let newElement = UIAccessibilityElement(accessibilityContainer: unreadFilterButton as Any)
        newElement.accessibilityLabel = LocalString._unread_action
        let unreadAction = UIAccessibilityCustomAction(
            name: LocalString._indox_accessibility_switch_unread,
            target: self,
            selector: #selector(self.unreadMessageFilterButtonTapped))

        newElement.accessibilityCustomActions = [unreadAction]
        newElement.accessibilityFrame = unreadFilterButton.frame
        customUnreadFilterElement = newElement
        view.accessibilityElements = [updateTimeLabel as Any,
                                      newElement,
                                      bannerContainer as Any,
                                      tableView as Any]
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

    @objc func composeButtonTapped() {
        if checkHuman() {
            self.coordinator?.go(to: .composer)
        }
    }

    @objc func storageExceededButtonTapped() {
        LocalString._storage_exceeded.alertToastBottom()
    }

    @objc func searchButtonTapped() {
        self.coordinator?.go(to: .search)
    }

    @objc func cancelButtonTapped() {
        hideSelectionMode()
    }

    @objc func ellipsisMenuTapped(sender: UIBarButtonItem) {
        let action = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let composeAction = UIAlertAction(title: LocalString._compose_message,
                                          style: .default) { [weak self] _ in
            self?.composeButtonTapped()
        }
        let isTrashFolder = self.viewModel.labelID == LabelLocation.trash.labelID
        let title = isTrashFolder ? LocalString._empty_trash: LocalString._empty_spam
        let emptyAction = UIAlertAction(title: title,
                                        style: .default) { [weak self] _ in
            guard self?.isAllowedEmptyFolder() ?? false else { return }
            self?.clickEmptyFolderAction()
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_action, style: .cancel, handler: nil)
        action.addAction(composeAction)
        action.addAction(emptyAction)
        action.addAction(cancel)
        if let popover = action.popoverPresentationController {
            popover.barButtonItem = sender
        }
        self.present(action, animated: true, completion: nil)
    }

    func isAllowedEmptyFolder() -> Bool {
        guard self.viewModel.isTrashOrSpam else { return false }
        guard self.hasNetworking else {
            LocalString._cannot_empty_folder_now.toast(at: self.view)
            return false
        }
        return true
    }

    func clickEmptyFolderAction() {
        self.viewModel.updateListAndCounter { [weak self] count in
            guard let count = count else {
                if let self = self {
                    LocalString._cannot_empty_folder_now.toast(at: self.view)
                }
                return
            }
            self?.showEmptyFolderAlert(total: Int(count.total))
        }
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
            // update the predicate in fetch controller
            self.viewModel.setupFetchController(self, isUnread: true)

            if self.viewModel.countOfFetchedObjects == 0 {
                self.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: true, completion: nil)
            }
        } else {
            self.viewModel.setupFetchController(self, isUnread: false)
        }
        self.viewModel.isCurrentUserSelectedUnreadFilterInInbox = isSelected
        self.reloadTableViewDataSource(animate: false)
        self.updateUnreadButton()
        self.showNoResultLabelIfNeeded()
    }

    private func beginRefreshingManually(animated: Bool) {
        if animated {
            self.refreshControl.beginRefreshing()
        }
    }

    // MARK: - Private methods

    private func hideSelectionMode() {
        self.viewModel.removeAllSelectedIDs()
        self.hideCheckOptions()
        self.updateNavigationController(false)
        if viewModel.eventsService.status != .running {
            self.startAutoFetch(false)
        }
        self.hideActionBar()
        self.dismissActionSheet()
    }

    private func handleViewModeIsChanged() {
        // Cancel selected items
        hideSelectionMode()

        viewModel.setupFetchController(self,
                                       isUnread: viewModel.isCurrentUserSelectedUnreadFilterInInbox)
        if self.isDiffableDataSourceEnabled, #available(iOS 13, *) {
            self.loadDiffableDataSource()
        }
        self.reloadTableViewDataSource(animate: false)

        if viewModel.countOfFetchedObjects == 0 {
            viewModel.fetchMessages(time: 0,
                                    forceClean: false,
                                    isUnread: viewModel.isCurrentUserSelectedUnreadFilterInInbox,
                                    completion: nil)
        }

        updateUnreadButton()
        showNoResultLabelIfNeeded()
    }

    // MARK: Auto refresh methods
    private func startAutoFetch(_ run: Bool = true) {
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
            // show human check view with warning
            isCheckingHuman = true
            self.coordinator?.go(to: .humanCheck)
            return false
        }
        return true
    }

    private func checkDoh(_ error: NSError) -> Bool {
        guard DoHMail.default.errorIndicatesDoHSolvableProblem(error: error) else {
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
            guard let message = self.viewModel.item(index: indexPath) else {
                return
            }
            let viewModel = buildNewMailboxMessageViewModel(
                message: message,
                customFolderLabels: self.viewModel.customFolders,
                weekStart: viewModel.user.userinfo.weekStartValue
            )
            mailboxCell.id = message.messageID.rawValue
            mailboxCell.cellDelegate = self
            messageCellPresenter.present(viewModel: viewModel, in: mailboxCell.customView)
            if message.expirationTime != nil &&
                message.messageLocation != .draft {
                mailboxCell.startUpdateExpiration()
            }

            configureSwipeAction(mailboxCell, indexPath: indexPath, item: .message(message))
        case .conversation:
            guard let conversation = self.viewModel.itemOfConversation(index: indexPath) else {
                return
            }
            let viewModel = buildNewMailboxMessageViewModel(
                conversation: conversation,
                conversationTagViewModels: getTagViewModelFrom(conversation: conversation),
                customFolderLabels: self.viewModel.customFolders,
                weekStart: viewModel.user.userinfo.weekStartValue
            )
            mailboxCell.id = conversation.conversationID.rawValue
            mailboxCell.cellDelegate = self
            messageCellPresenter.present(viewModel: viewModel, in: mailboxCell.customView)
            configureSwipeAction(mailboxCell, indexPath: indexPath, item: .conversation(conversation))
        }
        #if DEBUG
            mailboxCell.generateCellAccessibilityIdentifiers(mailboxCell.customView.messageContentView.titleLabel.text!)
        #endif
        let accessibilityAction =
            UIAccessibilityCustomAction(name: LocalString._accessibility_list_view_custom_action_of_switch_editing_mode,
                                        target: self,
                                        selector: #selector(self.handleAccessibilityAction))
        inputCell?.accessibilityCustomActions = [accessibilityAction]
        inputCell?.isAccessibilityElement = true
    }

    // Temp: needs to refactor the code of generating TagViewModel
    private func getTagViewModelFrom(conversation: ConversationEntity) -> [TagViewModel] {
        guard let object = viewModel.coreDataContextProvider.mainContext.object(with: conversation.objectID.rawValue) as? Conversation else {
            return []
        }
        return object.createTags()
    }

    private func configureSwipeAction(_ cell: SwipyCell, indexPath: IndexPath, item: SwipeableItem) {
        cell.delegate = self

        var actions: [SwipyCellDirection: SwipeActionSettingType] = [:]
        actions[.left] = userCachedStatus.leftToRightSwipeActionType
        actions[.right] = userCachedStatus.rightToLeftSwipeActionType

        for (direction, action) in actions {
            let msgAction = viewModel.convertSwipeActionTypeToMessageSwipeAction(
                action,
                isStarred: item.isStarred,
                isUnread: item.isUnread(labelID: viewModel.labelID)
            )

            guard msgAction != .none && viewModel.isSwipeActionValid(msgAction, item: item) else {
                continue
            }

            let swipeView = makeSwipeView(messageSwipeAction: msgAction)
            cell.addSwipeTrigger(forState: .state(0, direction),
                                 withMode: .exit,
                                 swipeView: swipeView,
                                 swipeColor: msgAction.actionColor) { [weak self] (cell, trigger, state, mode) in
                guard let self = self else { return }
                self.isSwipingCell = true
                self.handleSwipeAction(on: cell, action: msgAction, item: item)
                delay(0.5) {
                    self.isSwipingCell = false
                }
            }
        }
    }

    private func handleSwipeAction(on cell: SwipyCell, action: MessageSwipeAction, item: SwipeableItem) {
        guard let indexPathOfCell = self.tableView.indexPath(for: cell) else {
            self.reloadTableViewDataSource(animate: false)
            return
        }

        guard self.viewModel.isSwipeActionValid(action, item: item) else {
            cell.swipeToOrigin {}
            return
        }

        let hasBeenMoved = self.processSwipeActions(action, indexPath: indexPathOfCell, itemID: item.itemID)

        guard !hasBeenMoved else {
            return
        }

        // Since the read action will try to swipe the cell to origin. It conflicts with the animation of removing the cell from tableView.
        // Here to prevent the cell swiping to origin to remove weird animation.
        guard !unreadFilterButton.isSelected && action != .read else {
            return
        }

        cell.swipeToOrigin {}
    }

    /// - returns: true if the message has been moved (trash, delete, spam)
    private func processSwipeActions(_ action: MessageSwipeAction, indexPath: IndexPath, itemID: String) -> Bool {
        /// UIAccessibility
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: action.description)
        // TODO: handle conversation
        switch action {
        case .none:
            break
        case .labelAs:
            labelAs(indexPath, itemID: itemID, isSwipeAction: true)
        case .moveTo:
            moveTo(indexPath, itemID: itemID, isSwipeAction: true)
        case .unread:
            self.unread(indexPath, itemID: itemID)
            return false
        case .read:
            self.read(indexPath, itemID: itemID)
            return false
        case .star:
            self.star(indexPath, itemID: itemID)
            return false
        case .unstar:
            self.unstar(indexPath, itemID: itemID)
            return false
        case .trash:
            self.delete(indexPath, itemID: itemID, isSwipeAction: true)
            return true
        case .archive:
            self.archive(indexPath, itemID: itemID, isSwipeAction: true)
            return true
        case .spam:
            self.spam(indexPath, itemID: itemID, isSwipeAction: true)
            return true
        }
        return false
    }

    private func labelAs(_ index: IndexPath, itemID: String, isSwipeAction: Bool = false) {
        guard viewModel.checkIsIndexPathMatch(with: itemID, indexPath: index) else {
            return
        }
        if let message = viewModel.item(index: index) {
            showLabelAsActionSheet(messages: [message],
                                   isFromSwipeAction: isSwipeAction)
        } else if let conversation = viewModel.itemOfConversation(index: index) {
            showLabelAsActionSheet(conversations: [conversation],
                                   isFromSwipeAction: isSwipeAction)
        }
    }

    private func moveTo(_ index: IndexPath, itemID: String, isSwipeAction: Bool = false) {
        guard viewModel.checkIsIndexPathMatch(with: itemID, indexPath: index) else {
            return
        }
        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        if let message = viewModel.item(index: index) {
            showMoveToActionSheet(messages: [message],
                                  isEnableColor: isEnableColor,
                                  isInherit: isInherit,
                                  isFromSwipeAction: isSwipeAction)
        } else if let conversation = viewModel.itemOfConversation(index: index) {
            showMoveToActionSheet(conversations: [conversation],
                                  isEnableColor: isEnableColor,
                                  isInherit: isInherit,
                                  isFromSwipeAction: isSwipeAction)
        }
    }

    private func archive(_ index: IndexPath, itemID: String, isSwipeAction: Bool = false) {
        guard viewModel.checkIsIndexPathMatch(with: itemID, indexPath: index) else {
            return
        }
        viewModel.archive(index: index, isSwipeAction: isSwipeAction)
        showMessageMoved(title: LocalString._inbox_swipe_to_archive_banner_title,
                         undoActionType: .archive)
    }

    private func delete(_ index: IndexPath, itemID: String, isSwipeAction: Bool = false) {
        guard viewModel.checkIsIndexPathMatch(with: itemID, indexPath: index),
              self.viewModel.labelID != Message.Location.trash.labelID else {
                  let cell = self.tableView.cellForRow(at: index) as? SwipyCell
                  cell?.swipeToOrigin { }
                  return
              }
        viewModel.delete(index: index, isSwipeAction: isSwipeAction)
        showMessageMoved(title: LocalString._inbox_swipe_to_trash_banner_title,
                         undoActionType: .trash)
    }

    private func spam(_ index: IndexPath, itemID: String, isSwipeAction: Bool = false) {
        guard viewModel.checkIsIndexPathMatch(with: itemID, indexPath: index) else {
            return
        }
        viewModel.spam(index: index, isSwipeAction: isSwipeAction)
        showMessageMoved(title: LocalString._inbox_swipe_to_spam_banner_title,
                         undoActionType: .spam)
    }

    private func star(_ indexPath: IndexPath, itemID: String) {
        guard viewModel.checkIsIndexPathMatch(with: itemID, indexPath: indexPath) else {
            return
        }
        if let message = self.viewModel.item(index: indexPath) {
            self.viewModel.label(msg: message, with: Message.Location.starred.labelID)
        } else if let conversation = viewModel.itemOfConversation(index: indexPath) {
            viewModel.labelConversations(conversationIDs: [conversation.conversationID],
                                         labelID: Message.Location.starred.labelID) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.viewModel.eventsService.fetchEvents(labelID: self.viewModel.labelId)
                }
            }
        }
    }

    private func unstar(_ indexPath: IndexPath, itemID: String) {
        guard viewModel.checkIsIndexPathMatch(with: itemID, indexPath: indexPath) else {
            return
        }
        if let message = self.viewModel.item(index: indexPath) {
            self.viewModel.label(msg: message, with: Message.Location.starred.labelID, apply: false)
        } else if let conversation = viewModel.itemOfConversation(index: indexPath) {
            viewModel.unlabelConversations(conversationIDs: [conversation.conversationID],
                                         labelID: Message.Location.starred.labelID) { [weak self] result in
                guard let self = self else { return }
                if let _ = try? result.get() {
                    self.viewModel.eventsService.fetchEvents(labelID: self.viewModel.labelId)
                }
            }
        }
    }

    private func unread(_ indexPath: IndexPath, itemID: String) {
        guard viewModel.checkIsIndexPathMatch(with: itemID, indexPath: indexPath) else {
            return
        }
        if let message = self.viewModel.item(index: indexPath) {
            self.viewModel.mark(messages: [message])
        } else if let conversation = viewModel.itemOfConversation(index: indexPath) {
            viewModel.markConversationAsUnread(conversationIDs: [conversation.conversationID],
                                               currentLabelID: viewModel.labelID,
                                               completion: nil)
        }
    }

    private func read(_ indexPath: IndexPath, itemID: String) {
        guard viewModel.checkIsIndexPathMatch(with: itemID, indexPath: indexPath) else {
            return
        }
        if let message = self.viewModel.item(index: indexPath) {
            self.viewModel.mark(messages: [message], unread: false)
        } else if let conversation = viewModel.itemOfConversation(index: indexPath) {
            viewModel.markConversationAsRead(conversationIDs: [conversation.conversationID],
                                             currentLabelID: viewModel.labelID,
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
        attribute[.foregroundColor] = ColorProvider.TextInverted
        label.attributedText = messageSwipeAction.description.apply(style: attribute)
        iconView.image = messageSwipeAction.icon
        iconView.tintColor = ColorProvider.TextInverted

        return stackView
    }

    private func showMessageMoved(title: String, undoActionType: UndoAction? = nil) {
        if let type = undoActionType {
            viewModel.user.undoActionManager.addTitleWithAction(title: title, action: type)
        }
        let banner = PMBanner(message: title, style: TempPMBannerNewStyle.info)
        banner.show(at: .bottom, on: self)
    }

    private func handleRequestError(_ error: NSError) {
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
        self.replacingEmails = self.viewModel.allEmails
        // to update used space, pull down will wipe event data
        // so the latest used space can't update by event api
        self.viewModel.user.fetchUserInfo()
        forceRefreshAllMessages()
        self.showNoResultLabelIfNeeded()
    }

    @objc private func goTroubleshoot() {
        self.coordinator?.go(to: .troubleShoot)
    }

    private func getLatestMessagesCompletion(res: [String: Any]?, showNoResultIfNeeded: Bool, error: NSError?, completeIsFetch: ((_ fetch: Bool) -> Void)?) {
        self.needToShowNewMessage = false
        self.newMessageCount = 0
        self.fetchingMessage = false

        if self.fetchingStopped == true {
            self.refreshControl?.endRefreshing()
            if showNoResultIfNeeded {
                self.showNoResultLabelIfNeeded()
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
                    self.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: false, completion: { [weak self] (_, _, _) in
                        self?.retry()
                        self?.retryCounter += 1
                    })
                }
            } else {
                completeIsFetch?(false)
                self.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: false, completion: { [weak self] (_, _, _) in
                    self?.retry()
                    self?.retryCounter += 1
                })
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                if showNoResultIfNeeded {
                    self.showNoResultLabelIfNeeded()
                }
            }

            self.retryCounter = 0
            if self.fetchingStopped == true {
                completeIsFetch?(false)
                return
            }

            _ = self.checkHuman()
            // temporary to check message status and fetch metadata
            self.viewModel.purgeOldMessages()

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
    private func getLatestMessages() {
        self.getLatestMessagesRaw { [weak self] _ in
            self?.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: false) { [weak self] _, res, error in
                self?.getLatestMessagesCompletion(res: res, showNoResultIfNeeded: true, error: error, completeIsFetch: nil)
            }

            self?.showNoResultLabelIfNeeded()
        }
    }

    private func getLatestMessagesRaw(_ completeIsFetch: ((_ fetch: Bool) -> Void)?) {
        if !fetchingMessage {
            fetchingMessage = true
            self.beginRefreshingManually(animated: self.viewModel.rowCount(section: 0) < 1 ? true : false)
            self.showRefreshController()
            if isFirstFetch && viewModel.isEventIDValid() {
                isFirstFetch = false
                if viewModel.currentViewMode == .conversation {
                    viewModel.fetchConversationCount(completion: nil)
                }
                viewModel.fetchMessages(time: 0, forceClean: false, isUnread: isShowingUnreadMessageOnly) { [weak self] _, res, error in
                    self?.getLatestMessagesCompletion(res: res, showNoResultIfNeeded: true, error: error, completeIsFetch: completeIsFetch)
                }
            } else {
                if viewModel.isEventIDValid() {
                    // fetch
                    self.needToShowNewMessage = true
                    viewModel.fetchEvents(notificationMessageID: self.viewModel.notificationMessageID) { [weak self] _, res, error in
                        self?.getLatestMessagesCompletion(res: res, showNoResultIfNeeded: false, error: error, completeIsFetch: completeIsFetch)
                    }
                } else {// this new
                    viewModel.fetchDataWithReset(time: 0, cleanContact: false, removeAllDraft: false, unreadOnly: false) { [weak self] _, res, error in
                        self?.getLatestMessagesCompletion(res: res, showNoResultIfNeeded: true, error: error, completeIsFetch: completeIsFetch)
                    }
                }
            }
            self.checkContact()
        }
    }

    private func forceRefreshAllMessages() {
        guard !self.fetchingMessage else { return }
        self.fetchingMessage = true
        self.shouldAnimateSkeletonLoading = true
        self.shouldKeepSkeletonUntilManualDismissal = true
        self.reloadTableViewDataSource(animate: false)
        stopAutoFetch()

        viewModel.fetchDataWithReset(time: 0, cleanContact: true, removeAllDraft: false, unreadOnly: isShowingUnreadMessageOnly) { [weak self] _, res, error in
            if self?.unreadFilterButton.isSelected == true {
                self?.viewModel.fetchMessages(time: 0, forceClean: false, isUnread: false, completion: nil)
            }
            delay(0.2) {
                self?.shouldAnimateSkeletonLoading = false
                self?.shouldKeepSkeletonUntilManualDismissal = false
                self?.reloadTableViewDataSource(animate: false)
            }
            self?.getLatestMessagesCompletion(res: res, showNoResultIfNeeded: true, error: error, completeIsFetch: nil)
            self?.startAutoFetch()
        }
    }

    fileprivate func showNoResultLabelIfNeeded() {
        delay(0.5) {
            {
                let count = self.viewModel.sectionCount() > 0 ? self.viewModel.rowCount(section: 0) : 0
                if count <= 0 && !self.fetchingMessage {
                    let isNotInInbox = self.viewModel.labelID != Message.Location.inbox.labelID
                    self.noResultImage.image = isNotInInbox ? UIImage(named: "mail_folder_no_result_icon") : UIImage(named: "mail_no_result_icon")
                    self.noResultImage.isHidden = false

                    let mainText = isNotInInbox ? LocalString._folder_no_message : LocalString._inbox_no_message
                    self.noResultMainLabel.attributedText = NSMutableAttributedString(string: mainText, attributes: FontManager.Headline)
                    self.noResultMainLabel.isHidden = false

                    let subText = isNotInInbox ? LocalString._folder_is_empty : LocalString._inbox_time_to_relax
                    self.noResultSecondaryLabel.attributedText = NSMutableAttributedString(string: subText, attributes: FontManager.DefaultWeak)
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
        serialQueue.sync { [weak self] in
            guard let self = self else { return true }
            let ret = self.messageTapped
            if ret == false {
                self.messageTapped = true
            }
            return ret
        }
    }
    private func updateTapped(status: Bool) {
        serialQueue.sync { [weak self] in
            self?.messageTapped = status
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
    
    private func tappedMessage(_ message: MessageEntity) {
        if getTapped() == false {
            guard viewModel.isInDraftFolder || message.isDraft else {
                self.coordinator?.go(to: .details)
                self.tableView.indexPathsForSelectedRows?.forEach {
                    self.tableView.deselectRow(at: $0, animated: true)
                }
                self.updateTapped(status: false)
                return
            }
            guard !message.messageID.rawValue.isEmpty else {
                if self.checkHuman() {
                    // TODO::QA
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

            guard connectionStatusProvider.currentStatus.isConnected else {
                defer {
                    self.updateTapped(status: false)
                }
                let objectID = message.objectID.rawValue
                if let messageObject = self.viewModel.object(by: objectID),
                   !messageObject.body.isEmpty {
                    openCachedDraft(messageObject)
                    return
                }
                let alert = LocalString._unable_to_edit_offline.alertController()
                alert.addOKAction()
                present(alert, animated: true, completion: nil)
                return
            }
            
            showProgressHud()
            self.viewModel.messageService.ForcefetchDetailForMessage(message, runInQueue: false) { [weak self] _, _, msg, error in
                self?.hideProgressHud()
                if error != nil {
                    let alert = LocalString._unable_to_edit_offline.alertController()
                    alert.addOKAction()
                    self?.present(alert, animated: true, completion: nil)
                    self?.tableView.indexPathsForSelectedRows?.forEach {
                        self?.tableView.deselectRow(at: $0, animated: true)
                    }
                    self?.updateTapped(status: false)
                    return
                }
                guard let objectId = msg?.objectID.rawValue else {
                    self?.tableView.indexPathsForSelectedRows?.forEach {
                        self?.tableView.deselectRow(at: $0, animated: true)
                    }
                    self?.updateTapped(status: false)
                    return
                }
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    guard let message = self?.viewModel.object(by: objectId),
                          message.body.isEmpty == false else { return }
                    timer.invalidate()
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
    }

    private func openCachedDraft(_ message: Message) {
        coordinator?.go(to: .composeShow, sender: message)
        tableView.indexPathsForSelectedRows?.forEach {
            tableView.deselectRow(at: $0, animated: true)
        }
        updateTapped(status: false)
    }

    private func setupLeftButtons(_ editingMode: Bool) {
        var leftButtons: [UIBarButtonItem]

        if !editingMode {
            leftButtons = [self.menuBarButtonItem]
        } else {
            leftButtons = []
        }

        self.navigationItem.setLeftBarButtonItems(leftButtons, animated: true)
    }

    private func setupNavigationTitle(showSelected: Bool) {
        if showSelected {
            let count = self.viewModel.selectedIDs.count
            self.setNavigationTitleText("\(count) " + LocalString._selected_navogationTitle)
        } else {
            self.setNavigationTitleText(viewModel.localizedNavigationTitle)
        }
    }

    private func hideCheckOptions() {
        guard listEditing else { return }
        self.listEditing = false
        if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
            self.refreshCells(at: indexPathsForVisibleRows, animation: .automatic)
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
        self.setupNavigationTitle(showSelected: editingMode)
        self.setupRightButtons(editingMode)
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
        let shouldShowUnreadFilter = unread != 0
        unreadFilterButton.backgroundColor = isInUnreadFilter ? ColorProvider.BrandNorm : ColorProvider.BackgroundSecondary
        unreadFilterButton.isHidden = isInUnreadFilter ? false : unread == 0
        customUnreadFilterElement?.isAccessibilityElement = shouldShowUnreadFilter
        let number = unread > 9999 ? " +9999" : "\(unread)"

        if isInUnreadFilter {
            var selectedAttributes = FontManager.CaptionStrong
            selectedAttributes[.foregroundColor] = ColorProvider.TextInverted

            unreadFilterButton.setAttributedTitle("\(number) \(LocalString._unread_action) ".apply(style: selectedAttributes),
                                                  for: .selected)
        } else {
            var normalAttributes = FontManager.CaptionStrong
            normalAttributes[.foregroundColor] = ColorProvider.BrandNorm

            unreadFilterButton.setAttributedTitle("\(number) \(LocalString._unread_action) ".apply(style: normalAttributes),
                                                  for: .normal)
        }
        customUnreadFilterElement?.accessibilityLabel = "\(number) \(LocalString._unread_action)"

        let titleWidth = unreadFilterButton.titleLabel?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width ?? 0.0
        let width = titleWidth + 16 + (isInUnreadFilter ? 16 : 0)
        unreadFilterButtonWidth.constant = width
    }

    private func updateLastUpdateTimeLabel() {
        if let status = self.lastNetworkStatus, status == .notConnected {
            var attribute = FontManager.CaptionHint
            attribute[.foregroundColor] = ColorProvider.NotificationError
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
        isScrolled ? topActionsView.layer.apply(shadow: .custom(y: 2, blur: 2)) : topActionsView.layer.clearShadow()
    }

    private func deleteExpiredMessages() {
        viewModel.user.messageService.deleteExpiredMessage(completion: nil)
    }
}

// MARK: - Action bar
extension MailboxViewController {
    private func refreshActionBarItems() {
        let actions = self.viewModel.getActionBarActions()
        var actionItems: [PMToolBarView.ActionItem] = []

        for action in actions {
            let actionHandler: () -> Void = { [weak self] in
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
                                                            selectedIDs: self.viewModel.selectedIDs)
                            self.showMessageMoved(title: LocalString._messages_has_been_deleted)
                        }
                    case .moveTo:
                        self.folderButtonTapped()
                    case .labelAs:
                        self.labelButtonTapped()
                    default:
                        self.viewModel.handleBarActions(action, selectedIDs: self.viewModel.selectedIDs)
                        if ![.markAsRead, .markAsUnread].contains(action) {
                            self.showMessageMoved(title: LocalString._messages_has_been_moved)
                            self.hideSelectionMode()
                        }
                    }
                }
            }

            let barItem = PMToolBarView.ActionItem(type: action, handler: actionHandler)
            actionItems.append(barItem)
        }
        self.toolBar.setUpActions(actionItems)
    }

    private func showActionBar() {
        self.setToolBarHidden(false)
    }

    private func hideActionBar() {
        self.setToolBarHidden(true)
    }

    private func setToolBarHidden(_ hidden: Bool) {
        /*
         http://www.openradar.me/25087688

         > isHidden seems to be cumulative in UIStackViews, so we have to ensure to not set it the same value twice.
         */
        guard self.toolBar.isHidden != hidden else {
            return
        }

        UIView.animate(withDuration: 0.25) {
            self.toolBar.isHidden = hidden
        }
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
            self?.hideSelectionMode()
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel)
        [yes, cancel].forEach(alert.addAction)
        present(alert, animated: true, completion: nil)
    }

    private func showEmptyFolderAlert(total: Int) {
        let isTrashFolder = self.viewModel.labelID == LabelLocation.trash.labelID
        let title = isTrashFolder ? LocalString._empty_trash_folder: LocalString._empty_spam_folder
        let message = self.viewModel.getEmptyFolderCheckMessage(count: total)
        let alert = UIAlertController(title: "\(title)?", message: message, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: LocalString._general_delete_action, style: .destructive) { [weak self] _ in
            self?.viewModel.emptyFolder()
        }
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_action, style: .cancel, handler: nil)
        [deleteAction, cancelAction].forEach(alert.addAction)
        self.present(alert, animated: true, completion: nil)
    }

    @objc
    private func handleAccessibilityAction() {
        listEditing.toggle()
        updateNavigationController(listEditing)
        if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows {
            self.refreshCells(at: indexPathsForVisibleRows, animation: .automatic)
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

    private func showLabelAsActionSheet(messages: [MessageEntity], isFromSwipeAction: Bool = false) {
        let labelAsViewModel = LabelAsActionSheetViewModelMessages(menuLabels: labelAsActionHandler.getLabelMenuItems(),
                                                                   messages: messages)

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                guard let self = self else { return }
                if self.allowToCreateLabels(existingLabels: labelAsViewModel.menuLabels.count) {
                    self.coordinator?.pendingActionAfterDismissal = { [weak self] in
                        self?.showLabelAsActionSheet(messages: messages)
                    }
                    self.coordinator?.go(to: .newLabel)
                } else {
                    self.showAlertLabelCreationNotAllowed()
                }
            }, selected: { [weak self] menuLabel, isOn in
                self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: menuLabel, isOn: isOn)
            }, cancel: { [weak self] isHavingUnsavedChanges in
                if isHavingUnsavedChanges {
                    self?.showDiscardAlert(handleDiscard: {
                        self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: nil, isOn: false)
                        self?.dismissActionSheet()
                    })
                } else {
                    self?.dismissActionSheet()
                }
            }, done: { [weak self] isArchive, currentOptionsStatus in
                let isAnyOptionSelected = self?.labelAsActionHandler.selectedLabelAsLabels.isEmpty == false
                self?.labelAsActionHandler
                    .handleLabelAsAction(messages: messages,
                                         shouldArchive: isArchive,
                                         currentOptionsStatus: currentOptionsStatus)
                if isFromSwipeAction && isAnyOptionSelected {
                    let title = String.localizedStringWithFormat(LocalString._inbox_swipe_to_label_banner_title,
                                                                 messages.count)
                    self?.showMessageMoved(title: title)
                }
                if isArchive {
                    let title = String.localizedStringWithFormat(LocalString._inbox_swipe_to_move_banner_title,
                                                                 messages.count,
                                                                 LocalString._menu_archive_title)
                    self?.showMessageMoved(title: title,
                                           undoActionType: .archive)
                }
                self?.dismissActionSheet()
            })
    }
    
    private func showLabelAsActionSheet(conversations: [ConversationEntity], isFromSwipeAction: Bool = false) {
        let labelAsViewModel = LabelAsActionSheetViewModelConversations(menuLabels: labelAsActionHandler.getLabelMenuItems(),
                                                                        conversations: conversations)

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                guard let self = self else { return }
                if self.allowToCreateLabels(existingLabels: labelAsViewModel.menuLabels.count) {
                    self.coordinator?.pendingActionAfterDismissal = { [weak self] in
                        self?.showLabelAsActionSheet(conversations: conversations)
                    }
                    self.coordinator?.go(to: .newLabel)
                } else {
                    self.showAlertLabelCreationNotAllowed()
                }
            }, selected: { [weak self] menuLabel, isOn in
                self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: menuLabel, isOn: isOn)
            }, cancel: { [weak self] isHavingUnsavedChanges in
                if isHavingUnsavedChanges {
                    self?.showDiscardAlert(handleDiscard: {
                        self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: nil, isOn: false)
                        self?.dismissActionSheet()
                    })
                } else {
                    self?.dismissActionSheet()
                }
            }, done: { [weak self] isArchive, currentOptionsStatus in
                let isAnyOptionSelected = self?.labelAsActionHandler.selectedLabelAsLabels.isEmpty == false
                self?.labelAsActionHandler
                    .handleLabelAsAction(conversations: conversations,
                                         shouldArchive: isArchive,
                                         currentOptionsStatus: currentOptionsStatus,
                                         completion: nil)
                if isFromSwipeAction && isAnyOptionSelected {
                    let title = String.localizedStringWithFormat(LocalString._inbox_swipe_to_label_conversation_banner_title,
                                                                 conversations.count)
                    self?.showMessageMoved(title: title)
                }
                if isArchive {
                    let title = String.localizedStringWithFormat(LocalString._inbox_swipe_to_move_banner_title,
                                                                 conversations.count,
                                                                 LocalString._menu_archive_title)
                    self?.showMessageMoved(title: title,
                                           undoActionType: .archive)
                }
                self?.dismissActionSheet()
            })
    }

    private func allowToCreateLabels(existingLabels: Int) -> Bool {
        let isFreeAccount = viewModel.user.userInfo.subscribed == 0
        if isFreeAccount {
            return existingLabels < Constants.FreePlan.maxNumberOfLabels
        }
        return true
    }

    private func showAlertLabelCreationNotAllowed() {
        let title = LocalString._creating_label_not_allowed
        let message = LocalString._upgrade_to_create_label
        showAlert(title: title, message: message)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addOKAction()
        self.present(alert, animated: true, completion: nil)
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

    private func showMoveToActionSheet(messages: [MessageEntity], isEnableColor: Bool, isInherit: Bool, isFromSwipeAction: Bool = false) {
        let moveToViewModel =
            MoveToActionSheetViewModelMessages(menuLabels: moveToActionHandler.getFolderMenuItems(),
                                               messages: messages,
                                               isEnableColor: isEnableColor,
                                               isInherit: isInherit)
        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                guard let self = self else { return }
                if self.allowToCreateFolders(existingFolders: self.viewModel.getCustomFolderMenuItems().count) {
                    self.coordinator?.pendingActionAfterDismissal = { [weak self] in
                        self?.showMoveToActionSheet(messages: messages, isEnableColor: isEnableColor, isInherit: isInherit)
                    }
                    self.coordinator?.go(to: .newFolder)
                } else {
                    self.showAlertFolderCreationNotAllowed()
                }
            }, selected: { [weak self] menuLabel, isOn in
                self?.moveToActionHandler.updateSelectedMoveToDestination(menuLabel: menuLabel, isOn: isOn)
            }, cancel: { [weak self] isHavingUnsavedChanges in
                if isHavingUnsavedChanges {
                    self?.showDiscardAlert(handleDiscard: {
                        self?.moveToActionHandler.updateSelectedMoveToDestination(menuLabel: nil, isOn: false)
                        self?.dismissActionSheet()
                    })
                } else {
                    self?.dismissActionSheet()
                }
            }, done: { [weak self] isHavingUnsavedChanges in
                defer {
                    self?.dismissActionSheet()
                    self?.hideSelectionMode()
                }
                guard isHavingUnsavedChanges,
                      let destination = self?.moveToActionHandler.selectedMoveToFolder else {
                    return
                }
                
                self?.moveToActionHandler
                    .handleMoveToAction(messages: messages, isFromSwipeAction: isFromSwipeAction)
                if isFromSwipeAction {
                    let title = String.localizedStringWithFormat(
                        LocalString._inbox_swipe_to_move_banner_title,
                        messages.count,
                        destination.name)
                    self?.showMessageMoved(
                        title: title,
                        undoActionType: .custom(destination.location.rawLabelID))
                }
            })
    }

    private func showMoveToActionSheet(conversations: [ConversationEntity], isEnableColor: Bool, isInherit: Bool, isFromSwipeAction: Bool = false) {
        let moveToViewModel =
            MoveToActionSheetViewModelConversations(menuLabels: moveToActionHandler.getFolderMenuItems(),
                                                    conversations: conversations,
                                                    isEnableColor: isEnableColor,
                                                    isInherit: isInherit)
        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                        guard let self = self else { return }
                        if self.allowToCreateFolders(existingFolders: self.viewModel.getCustomFolderMenuItems().count) {
                            self.coordinator?.pendingActionAfterDismissal = { [weak self] in
                                self?.showMoveToActionSheet(conversations: conversations, isEnableColor: isEnableColor, isInherit: isInherit)
                            }
                            self.coordinator?.go(to: .newFolder)
                        } else {
                            self.showAlertFolderCreationNotAllowed()
                        }
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
                            self?.hideSelectionMode()
                        }
                        guard isHavingUnsavedChanges,
                              let destination = self?.moveToActionHandler.selectedMoveToFolder else {
                            return
                        }

                        self?.moveToActionHandler
                    .handleMoveToAction(conversations: conversations, isFromSwipeAction: isFromSwipeAction, completion: nil)
                        if isFromSwipeAction {
                            let title = String.localizedStringWithFormat(LocalString._inbox_swipe_to_move_conversation_banner_title,
                                                                         conversations.count,
                                                                         destination.name)
                            self?.showMessageMoved(title: title,
                                                   undoActionType: .custom(destination.location.rawLabelID))
                        }
                     })
    }

    private func allowToCreateFolders(existingFolders: Int) -> Bool {
        let isFreeAccount = viewModel.user.userInfo.subscribed == 0
        if isFreeAccount {
            return existingFolders < Constants.FreePlan.maxNumberOfFolders
        }
        return true
    }

    private func showAlertFolderCreationNotAllowed() {
        let title = LocalString._creating_folder_not_allowed
        let message = LocalString._upgrade_to_create_folder
        showAlert(title: title, message: message)
    }

    private func handleActionSheetAction(_ action: MailListSheetAction) {
        switch action {
        case .dismiss:
            dismissActionSheet()
        case .remove, .moveToArchive, .moveToSpam, .moveToInbox:
            showMessageMoved(title: LocalString._messages_has_been_moved)
            hideSelectionMode()
        case .markRead, .markUnread, .star, .unstar:
            break
        case .delete:
            showDeleteAlert { [weak self] in
                guard let `self` = self else { return }
                self.viewModel.delete(IDs: self.viewModel.selectedIDs)
            }
        case .labelAs:
            labelButtonTapped()
        case .moveTo:
            folderButtonTapped()
        }
    }
}

// MARK: - MailboxCaptchaVCDelegate
extension MailboxViewController: MailboxCaptchaVCDelegate {

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
        banner.addButton(text: LocalString._retry) { [weak self] _ in
            banner.dismiss()
            self?.getLatestMessages()
        }
        banner.show(at: .top, on: self)
    }

    private func showNoInternetErrorMessage() {
        guard UIApplication.shared.applicationState == .active,
              !isInternetBannerPresented else {
                  return
              }
        let banner = PMBanner(message: LocalString._general_no_connectivity_detected, style: PMBannerNewStyle.error, dismissDuration: 5.0)
        banner.addButton(text: LocalString._retry) { [weak self] _ in
            banner.dismiss()
            self?.getLatestMessages()
        }
        banner.show(at: .top, on: self)
    }

    internal func showOfflineErrorMessage(_ error: NSError?) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(message: error?.localizedDescription ?? LocalString._general_pm_offline, style: PMBannerNewStyle.error, dismissDuration: 5.0)
        banner.addButton(text: LocalString._retry) { [weak self] _ in
            banner.dismiss()
            self?.getLatestMessages()
        }
        banner.show(at: .top, on: self)
    }

    private func show503ErrorMessage(_ error: NSError?) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(message: LocalString._general_api_server_not_reachable, style: PMBannerNewStyle.error, dismissDuration: 5.0)
        banner.addButton(text: LocalString._retry) { [weak self] _ in
            banner.dismiss()
            self?.getLatestMessages()
        }
        banner.show(at: .top, on: self)
    }

    private func showError(_ error: NSError) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(message: "We could not connect to the servers. Pull down to retry.", style: PMBannerNewStyle.error, dismissDuration: 5.0)
        banner.addButton(text: "Learn more") { [weak self] _ in
            banner.dismiss()
            self?.goTroubleshoot()
        }
        banner.show(at: .top, on: self)
    }

    private func showNewMessageCount(_ count: Int) {
        guard self.needToShowNewMessage, count > 0 else { return }
        self.needToShowNewMessage = false
        self.newMessageCount = 0
        let message = count == 1 ? LocalString._messages_you_have_new_email : String(format: LocalString._messages_you_have_new_emails_with, count)
        message.alertToastBottom()
    }

}

// MARK: - Handle Network status changed
extension MailboxViewController {
    private func updateInterface(connectionStatus: ConnectionStatus) {
        switch connectionStatus {
        case .notConnected:
            self.showNoInternetErrorMessage()
            self.hasNetworking = false
            self.showInternetConnectionBanner()
            self.hasNetworking = false
        default:
            self.hideInternetConnectionBanner()
            self.afterNetworkChange(status: connectionStatus)
            self.hasNetworking = true
        }
        lastNetworkStatus = connectionStatus
        
        self.updateLastUpdateTimeLabel()
    }
    
    private func afterNetworkChange(status: ConnectionStatus) {
        guard let oldStatus = lastNetworkStatus else {
            return
        }
        
        guard oldStatus == .notConnected else {
            return
        }
        
        if status == .connectedViaCellular || status == .connectedViaEthernet || status == .connectedViaWiFi {
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
            cell.backgroundColor = ColorProvider.BackgroundNorm
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
            self.reloadTableViewDataSource(animate: false)
            return
        }

        if controller == self.viewModel.unreadFetchedResult {
            self.updateUnreadButton()
            return
        }

        if shouldKeepSkeletonUntilManualDismissal {
            return
        }

        if !self.isDiffableDataSourceEnabled {
            self.tableView.endUpdates()
        } else {
            self.reloadTableViewDataSource(animate: false)
        }
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
        self.showNewMessageCount(self.newMessageCount)
        self.updateLastUpdateTimeLabel()
        self.showNoResultLabelIfNeeded()
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

            self.reloadTableViewDataSource(animate: false)
        }

        if !shouldKeepSkeletonUntilManualDismissal {
            if !self.isDiffableDataSourceEnabled {
                self.tableView.beginUpdates()
            }
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        if controller == self.viewModel.labelFetchedResults
            || controller == self.viewModel.unreadFetchedResult
            || shouldKeepSkeletonUntilManualDismissal {
            return
        }
        if self.isDiffableDataSourceEnabled, diffableDataSource != nil {
            self.reloadTableViewDataSource(animate: true)
        } else {
            switch type {
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
            }
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if controller == self.viewModel.labelFetchedResults
        || controller == self.viewModel.unreadFetchedResult
        || shouldKeepSkeletonUntilManualDismissal {
            return
        }

        defer {
            refreshActionBarItems()
        }

		guard !self.isDiffableDataSourceEnabled && diffableDataSource == nil else {
            return
        }

        switch type {
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            popPresentedItemIfNeeded(anObject)
            hideActionBarIfNeeded(anObject)
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .fade)
            guard self.needToShowNewMessage,
                  let newMsg = anObject as? Message,
                  let msgTime = newMsg.time, newMsg.unRead,
                  let updateTime = viewModel.lastUpdateTime(),
                  msgTime.compare(updateTime.startTime) != ComparisonResult.orderedAscending else { return }
            self.newMessageCount += 1
        case .update:
            if let indexPath = indexPath {
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
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
                if coordinator?.conversationCoordinator?.conversation.conversationID.rawValue == contextLabel.conversationID {
                    navigationController?.popViewController(animated: true)
                }
            }
            if let message = anObject as? Message {
                if coordinator?.singleMessageCoordinator?.message.messageID == MessageID(message.messageID) {
                    navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func hideActionBarIfNeeded(_ anObject: Any) {
        guard let _ = navigationController?.topViewController as? MailboxViewController else {
            return
        }
        var id: String = ""
        if let contextLabel = anObject as? ContextLabel {
            id = contextLabel.conversationID
        } else if let message = anObject as? Message {
            id = message.messageID
        }
        guard viewModel.selectedIDs.contains(id) else { return }
        viewModel.removeSelected(id: id)
        self.setupNavigationTitle(showSelected: self.listEditing)
        self.dismissActionSheet()
        if viewModel.selectedIDs.isEmpty {
            hideActionBar()
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
                // here need add a counter to check if tried too many times make one real call in case count not right
                if isNew || recordedCount > sectionCount {
                    guard connectionStatusProvider.currentStatus.isConnected else {
                        return
                    }
                    self.fetchingOlder = true
                    if !refreshControl.isRefreshing {
                        self.tableView.showLoadingFooter()
                    }
                    let unixTimt: Int = (endTime == Date.distantPast ) ? 0 : Int(endTime.timeIntervalSince1970)
                    self.viewModel.fetchMessages(time: unixTimt, forceClean: false, isUnread: self.isShowingUnreadMessageOnly, completion: { (_, _, _) -> Void in
                        DispatchQueue.main.async {
                            self.tableView.hideLoadingFooter()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.showNoResultLabelIfNeeded()
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

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? NewMailboxMessageCell {
            cell.gestureRecognizers?.filter({ $0 is UIPanGestureRecognizer }).forEach { gesture in
                // Cancel the existing pan gesture that user swipes the cell before the tableview reloads.
                gesture.isEnabled = false
                gesture.isEnabled = true
            }
        }
    }

    private func handleMessageSelection(indexPath: IndexPath) {
        guard let message = viewModel.item(index: indexPath) else { return }
        if listEditing {
            handleEditingDataSelection(of: message.messageID.rawValue, indexPath: indexPath)
        } else {
            self.tapped(at: indexPath)
        }
    }

    private func handleConversationSelection(indexPath: IndexPath) {
        guard let conversation = viewModel.itemOfConversation(index: indexPath) else { return }
        if listEditing {
            handleEditingDataSelection(of: conversation.conversationID.rawValue, indexPath: indexPath)
        } else {
            self.coordinator?.go(to: .details)
        }
    }

    private func handleEditingDataSelection(of id: String, indexPath: IndexPath) {
        let itemAlreadySelected = viewModel.selectionContains(id: id)
        let selectionAction = itemAlreadySelected ? viewModel.removeSelected : viewModel.select
        selectionAction(id)

        // update checkbox state
        if let mailboxCell = tableView.cellForRow(at: indexPath) as? NewMailboxMessageCell {
            messageCellPresenter.presentSelectionStyle(
                style: .selection(isSelected: !itemAlreadySelected),
                in: mailboxCell.customView
            )
        }

        tableView.deselectRow(at: indexPath, animated: true)
        setupNavigationTitle(showSelected: true)

        if viewModel.selectedIDs.isEmpty {
            hideSelectionMode()
        } else {
            refreshActionBarItems()
            showActionBar()
        }
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
        return expirationTime.countExpirationTime(processInfo: userCachedStatus)
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
        self.unreadFilterButton.setTitleColor(ColorProvider.BrandNorm, for: .normal)
        self.unreadFilterButton.setTitleColor(ColorProvider.TextInverted, for: .selected)
        // Use local icon to prevent UI glitch
        self.unreadFilterButton.setImage(Asset.mailLabelCrossIcon.image, for: .selected)
        self.unreadFilterButton.semanticContentAttribute = .forceRightToLeft
        self.unreadFilterButton.titleLabel?.isSkeletonable = true
        self.unreadFilterButton.titleLabel?.font = UIFont.systemFont(ofSize: 13.0)
        self.unreadFilterButton.translatesAutoresizingMaskIntoConstraints = false
        self.unreadFilterButton.layer.cornerRadius = self.unreadFilterButton.frame.height / 2
        self.unreadFilterButton.layer.masksToBounds = true
        self.unreadFilterButton.backgroundColor = ColorProvider.BackgroundSecondary
        self.unreadFilterButton.isSelected = viewModel.isCurrentUserSelectedUnreadFilterInInbox
        self.unreadFilterButton.imageView?.tintColor = ColorProvider.IconInverted
        self.unreadFilterButton.imageView?.contentMode = .scaleAspectFit
        self.unreadFilterButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    }
}

extension MailboxViewController: SkeletonTableViewDataSource {
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return MailBoxSkeletonLoadingCell.Constant.identifier
    }
}

extension MailboxViewController: EventsConsumer {
    func shouldCallFetchEvents() {
        deleteExpiredMessages()
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

        hapticFeedbackGenerator.prepare()
    }

    func swipyCellDidFinishSwiping(_ cell: SwipyCell, atState state: SwipyCellState, triggerActivated activated: Bool) {
        viewModel.swipyCellDidFinishSwiping()

        tableView.visibleCells.forEach { cell in
            if let swipyCell = cell as? SwipyCell {
                swipyCell.gestureRecognizers?.compactMap({ $0 as? UIPanGestureRecognizer }).forEach({ $0.isEnabled = true })
            }
        }
    }

    func swipyCell(_ cell: SwipyCell, didSwipeWithPercentage percentage: CGFloat, currentState state: SwipyCellState, triggerActivated activated: Bool) {
        viewModel.swipyCellDidSwipe(triggerActivated: activated)
    }
}

// MARK: Data Source Refresh
extension MailboxViewController {
    func refreshCells(at indexPaths: [IndexPath], animation: UITableView.RowAnimation) {
        let shouldAnimate: Bool
        switch animation {
        case .fade, .right, .left, .top, .bottom, .middle, .automatic:
            shouldAnimate = true
        case .none:
            shouldAnimate = false
        @unknown default:
            shouldAnimate = true
        }

        if self.isDiffableDataSourceEnabled, let diffableDataSource = diffableDataSource {
            diffableDataSource.refreshItems(at: indexPaths, animate: shouldAnimate)
        } else {
            self.tableView.reloadRows(at: indexPaths, with: animation)
        }
    }

    private func reloadTableViewDataSource(animate: Bool) {
        if self.isDiffableDataSourceEnabled, let diffableDataSource = diffableDataSource {
            diffableDataSource.reloadSnapshot(shouldAnimateSkeletonLoading: self.shouldAnimateSkeletonLoading,
                                              animate: animate)
            // Using diffable data source triggers an issue that make
            // refresh control dismiss only after a couple of seconds
            // so we dismiss it manually
            self.refreshControl.endRefreshing()
        } else {
            self.tableView.reloadData()
        }
    }
}

// MARK: InApp feedback related

extension MailboxViewController {
    private var inAppFeedbackStorage: InAppFeedbackStorageProtocol {
        UserDefaults.standard
    }

    private func makeInAppFeedbackPromptScheduler() -> InAppFeedbackPromptScheduler {
        let allowedHandler: InAppFeedbackPromptScheduler.PromptAllowedHandler = { [weak self] in
            guard let self = self else { return false }
            guard self.viewModel.user.inAppFeedbackStateService.isEnable else {
                return false
            }
            return self.navigationController?.topViewController == self
        }
        let showHandler: InAppFeedbackPromptScheduler.ShowPromptHandler = { [weak self] completionHandler in
            guard let self = self else { return }

            self.showFeedbackActionSheet { completed in
                completionHandler?(completed)
            }
        }
        let scheduler = InAppFeedbackPromptScheduler(
            storage: inAppFeedbackStorage,
            promptDelayTime: InAppFeedbackPromptScheduler.defaultPromptDelayTime,
            promptAllowedHandler: allowedHandler,
            showPromptHandler: showHandler)
        return scheduler
    }

    typealias UserFeedbackCompletedHandler = (/* Completed or not */ Bool) -> Void

    private func showFeedbackActionSheet(completedHandler: UserFeedbackCompletedHandler? = nil) {
        let delayTime = 0.1
        let viewModel = InAppFeedbackViewModel { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let userFeedback):
                // Submit the feedback
                let apiService = self.viewModel.user.apiService
                let feedbackService = UserFeedbackService(apiService: apiService)
                self.submit(userFeedback, service: feedbackService, successHandler: { [weak self] in
                    guard let self = self else { return }
                    completedHandler?(true)
                    let banner = PMBanner(message: LocalString._thank_you_feedback, style: PMBannerNewStyle.success)
                    banner.show(at: .bottom, on: self, ignoreKeyboard: true)
                }, failureHandler: {
                    completedHandler?(false)
                })
            default:
                completedHandler?(false)
                return
            }
        }
        let viewController = InAppFeedbackViewController(viewModel: viewModel)
        delay(delayTime) {
            self.present(viewController, animated: true, completion: nil)
        }
    }

    func showFeedbackViewIfNeeded(forceToShow: Bool = false) {
        if forceToShow {
            scheduleUserFeedbackCallOnAppear = true
        }
        if scheduleUserFeedbackCallOnAppear {
            scheduleUserFeedbackCallOnAppear = false
            self.showFeedbackActionSheet { [weak self] completed in
                guard let self = self else { return }
                self.inAppFeedbackScheduler?.markAsFeedbackSubmitted()
            }
        }
    }
}

extension MailboxViewController: UndoActionHandlerBase {

    func showUndoAction(token: UndoTokenData, title: String) {
        let banner = PMBanner(message: title, style: TempPMBannerNewStyle.info)
        banner.addButton(text: LocalString._messages_undo_action) { [weak self] _ in
            self?.viewModel.user.undoActionManager.sendUndoAction(token: token) { [weak self] isSuccess in
                if isSuccess {
                    self?.showActionRevertedBanner()
                }
            }
            banner.dismiss(animated: false)
        }
        banner.show(at: .bottom, on: self)
        // Dismiss other banner after the undo banner is shown
        delay(0.25) { [weak self] in
            self?.view.subviews
                .compactMap { $0 as? PMBanner }
                .filter { $0 != banner }
                .forEach({ $0.dismiss(animated: false) })
        }
    }

    func showActionRevertedBanner() {
        let banner = PMBanner(message: LocalString._inbox_action_reverted_title,
                              style: TempPMBannerNewStyle.info,
                              dismissDuration: 1)
        banner.show(at: .bottom, on: self)
    }

    var delaySendSeconds: Int {
        self.viewModel.user.userInfo.delaySendSeconds
    }
}
