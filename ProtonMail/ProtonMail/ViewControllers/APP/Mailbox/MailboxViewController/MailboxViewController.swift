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
import Combine
import CoreData
import LifetimeTracker
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCorePayments
import ProtonCoreServices
import ProtonCoreUIFoundations
import ProtonMailAnalytics
import ProtonMailUI
import QuickLook
import SkeletonView
import SwiftUI
import SwipyCell
import UIKit

class MailboxViewController: AttachmentPreviewViewController, ComposeSaveHintProtocol, ScheduledAlertPresenter, LifetimeTrackable {
    typealias Dependencies = HasPaymentsUIFactory
    & ReferralProgramPromptPresenter.Dependencies
    & HasMailboxMessageCellHelper
    & HasUserManager
    & HasUserDefaults
    & HasAddressBookService
    & HasUserCachedStatus

    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    let viewModel: MailboxViewModel
    private let dependencies: Dependencies
    private var cancellables = Set<AnyCancellable>()

    private weak var coordinator: (MailboxCoordinatorProtocol & SnoozeSupport)?

    func set(coordinator: MailboxCoordinatorProtocol & SnoozeSupport) {
        self.coordinator = coordinator
    }

    private lazy var replacingEmails: [EmailEntity] = viewModel.allEmails
    lazy var replacingEmailsMap: [String: EmailEntity] = {
        return generateEmailsMap()
    }()

    var mailboxMessageCellHelper: MailboxMessageCellHelper {
        dependencies.mailboxMessageCellHelper
    }

    // MARK: - View Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Private constants
    private let kLongPressDuration: CFTimeInterval = 0.60 // seconds

    // MARK: TopActions
    @IBOutlet weak var topActionsView: UIView!
    @IBOutlet weak var updateTimeLabel: UILabel!
    @IBOutlet weak var unreadFilterButton: UIButton!
    @IBOutlet weak var unreadFilterButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var selectAllButton: UIView!
    @IBOutlet weak var selectAllIcon: UIImageView!
    @IBOutlet weak var selectAllLabel: UILabel!
    
    // MARK: AlertBox
    @IBOutlet weak var alertContainerView: UIView!
    @IBOutlet weak var alertCardView: UIView!
    @IBOutlet weak var alertIcon: UIImageView!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var alertDescription: UILabel!
    @IBOutlet weak var alertDismissButton: UIButton!
    @IBOutlet weak var alertButton: UIButton!

    // MARK: PMToolBarView
    @IBOutlet private var toolBar: PMToolBarView!

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.set(text: nil, preferredFont: .body, weight: .bold)
        return titleLabel
    }()

    // MARK: - Private attributes

    private var bannerContainer: UIView?
    private var bannerShowConstrain: NSLayoutConstraint?
    private var isInternetBannerPresented = false
    private var isHidingBanner = false

    private var fetchingOlder: Bool = false

    private var needToShowNewMessage: Bool = false
    private var newMessageCount = 0
    private var previousMessageCount: Int?
    private var hasNetworking = true
    private var configuredActions: [SwipyCellDirection: SwipeActionSettingType] = [:]

    // MARK: - Private views
    private var refreshControl: UIRefreshControl!

    // MARK: - No result image and label
    @IBOutlet weak var noResultImage: UIImageView!
    @IBOutlet weak var noResultMainLabel: UILabel!
    @IBOutlet weak var noResultSecondaryLabel: UILabel!
    @IBOutlet weak var noResultFooterLabel: UILabel!

    private var lastNetworkStatus: ConnectionStatus? = nil

    var shouldAnimateSkeletonLoading = false {
        didSet {
            SystemLogger.log(
                message: "Placeholder cells \(shouldAnimateSkeletonLoading ? "on" : "off")",
                category: .mailboxRefresh
            )
            if shouldAnimateSkeletonLoading {
                viewModel.diffableDataSource?.animateSkeletonLoading()
            } else {
                reloadTableViewDataSource()
            }
        }
    }
    var isShowingUnreadMessageOnly: Bool {
        unreadFilterButton?.isSelected ?? false
    }

    private let messageCellPresenter = NewMailboxMessageCellPresenter()
    private let mailListActionSheetPresenter = MailListActionSheetPresenter()
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()
    private var referralProgramPresenter: ReferralProgramPromptPresenter?
    private var upsellCoordinator: UpsellCoordinator?

    private var isSwipingCell = false {
        didSet {
            let hasChangedFromTrueToFalse = oldValue && !isSwipingCell

            if
                hasChangedFromTrueToFalse,
                contentChangeOccurredDuringLastSwipeGesture
            {
                contentChangeOccurredDuringLastSwipeGesture = false
                reloadTableViewDataSource()
            }
        }
    }

    private var contentChangeOccurredDuringLastSwipeGesture = false

    private var notificationsAreScheduled = false

    private var customUnreadFilterElement: UIAccessibilityElement?
    let connectionStatusProvider = InternetConnectionStatusProvider.shared

    private let hapticFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    override var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    init(viewModel: MailboxViewModel, dependencies: Dependencies) {
        self.viewModel = viewModel
        self.dependencies = dependencies

        super.init(viewModel: viewModel)

        viewModel.uiDelegate = self
        trackLifetime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        viewModel.resetFetchedController()
        NotificationCenter.default.removeObserver(self)
    }

    @objc func doEnterForeground() {
        if viewModel.reloadTable() {
            resetTableView()
        }
        self.updateLastUpdateTimeLabel()
        self.updateUnreadButton(count: viewModel.unreadCount)

        refetchAllIfNeeded()
        startAutoFetch()
    }

    @objc func doEnterBackground() {
        stopAutoFetch()
    }

    private func refetchAllIfNeeded(caller: StaticString = #function) {
        if BackgroundTimer.shared.wasInBackgroundLongEnoughForDataToBecomeOutdated {
            SystemLogger.log(message: "refetchAllIfNeeded called by \(caller)", category: .mailboxRefresh)
            pullDown()
            BackgroundTimer.shared.updateLastForegroundDate()
        }
    }

    func resetTableView() {
        self.viewModel.resetFetchedController()
        self.viewModel.setupFetchController(self, isUnread: self.unreadFilterButton.isSelected)
        self.reloadTableViewDataSource()
    }

    override var prefersStatusBarHidden: Bool {
        false
    }

    // MARK: - UIViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(self.coordinator != nil)
        emptyBackButtonTitleForNextView()

        self.viewModel.viewModeIsChanged = { [weak self] in
            self?.handleViewModeIsChanged()
        }

        self.viewModel.sendHapticFeedback = { [weak self] in
            self?.hapticFeedbackGenerator.impactOccurred()
        }

        configureUnreadFilterButton()
        configureSelectAllButton()

        self.addSubViews()
        if [Message.Location.spam,
            Message.Location.archive,
            Message.Location.trash,
            Message.Location.sent].map(\.labelID).contains(viewModel.labelID)
            && viewModel.isCurrentUserSelectedUnreadFilterInInbox {
            unreadMessageFilterButtonTapped()
        }

        self.loadDiffableDataSource()
        self.viewModel.setupFetchController(self, isUnread: viewModel.isCurrentUserSelectedUnreadFilterInInbox)

        self.setNavigationTitleText(viewModel.localizedNavigationTitle)

        SkeletonAppearance.default.renderSingleLineAsView = true

        self.tableView.separatorStyle = .none
        self.tableView.register(NewMailboxMessageCell.self, forCellReuseIdentifier: NewMailboxMessageCell.defaultID())
        self.tableView.registerCell(MailBoxSkeletonLoadingCell.Constant.identifier)

        self.updateNavigationController(viewModel.listEditing)

        #if DEBUG
        if CommandLine.arguments.contains("-skipTour") {
            viewModel.resetTourValue()
        }
        #endif

        // Setup top actions
        self.topActionsView.backgroundColor = ColorProvider.BackgroundNorm
        self.topActionsView.layer.zPosition = tableView.layer.zPosition + 1
        setupAlertBox()

        self.updateUnreadButton(count: viewModel.unreadCount)
        self.updateLastUpdateTimeLabel()

        generateAccessibilityIdentifiers()
        configureBannerContainer()

        SwipyCellConfig.shared.triggerPoints.removeValue(forKey: -0.75)
        SwipyCellConfig.shared.triggerPoints.removeValue(forKey: 0.75)
        SwipyCellConfig.shared.shouldAnimateSwipeViews = false
        SwipyCellConfig.shared.shouldUseSpringAnimationWhileSwipingToOrigin = false

        refetchAllIfNeeded()

        setupScreenEdgeGesture()
        setupAccessibility()

        connectionStatusProvider.register(receiver: self)

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(tempNetworkError(_:)),
                         name: .tempNetworkError,
                         object: nil)

        viewModel.setupStorageObservation { [weak self] newValue in
            guard let self else { return }
            DispatchQueue.main.async {
                self.setupRightButtons(self.viewModel.listEditing, isStorageExceeded: newValue)
            }
        }

        viewModel.setupLockedStateObservation { [weak self] newValue in
            guard let self else { return }
            DispatchQueue.main.async {
                self.setupAlertBox()
            }
        }

        viewModel
            .reloadRightBarButtons
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in
                setupRightButtons(viewModel.listEditing, isStorageExceeded: viewModel.user.isStorageExceeded)
            }
            .store(in: &cancellables)
        
        viewModel.fetchUserPlan(completion: displayReminderModalIfNeeded(subscription:))
        
        viewModel.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !notificationsAreScheduled {
            notificationsAreScheduled = true
            addNotificationsObserver()
        }

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged,
                                 argument: self.navigationController?.view)
        }

        self.updateUnreadButton(count: viewModel.unreadCount)
        viewModel.deleteExpiredMessages()
        viewModel.user.undoActionManager.register(handler: self)
        reloadIfSwipeActionsDidChange()
        fetchEventInScheduledSend()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        notificationsAreScheduled = false
        NotificationCenter.default.removeObserver(self)
        
        PMBanner.dismissAll(on: self, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if Message.Location(viewModel.labelID) == .inbox {
            viewModel.user.appRatingService.preconditionEventDidOccur(.inboxNavigation)
        }
        guard !viewModel.isLoggingOut && viewModel.user.parentManager != nil else {
            viewModel.resetFetchedController()
            return
        }
        if viewModel.isNewEventLoopEnabled && viewModel.isFirstFetch {
            getLatestMessages()
        } 

        if !viewModel.isNewEventLoopEnabled {
            if viewModel.eventsService.status != .started {
                self.startAutoFetch()
            } else {
                viewModel.eventsService.resume()
                viewModel.eventsService.call()
            }
        }

        self.view.window?.windowScene?.title = self.title ?? LocalString._menu_inbox_title

        guard viewModel.isHavingUser else {
            return
        }

        self.viewModel.checkStorageIsCloseLimit()

        self.updateInterface(connectionStatus: connectionStatusProvider.status)

        if let selectedItem = self.tableView.indexPathForSelectedRow, !self.viewModel.isInDraftFolder {
            self.tableView.deselectRow(at: selectedItem, animated: true)
        }

        FileManager.default.cleanCachedAttsLegacy()

        updateReferralPresenterAndShowPromptIfNeeded()

        DispatchQueue.global().async { [weak self] in
            self?.viewModel.prefetchIfNeeded()
        }

        if let destination = self.viewModel.getOnboardingDestination() {
            viewModel.resetTourValue()
            self.coordinator?.go(to: destination, sender: nil)
        } else {
            if !ProcessInfo.isRunningUITests {
                showSpotlightIfNeeded()
            }
        }
    }

    @objc
    private func tempNetworkError(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let error = notification.object as? ConnectionFailedReason else { return }
            switch error {
            case .timeout:
                self.showTimeOutErrorMessage()
            case .internetIssue:
                self.showInternetConnectionBanner()
            }
        }
    }

    private func setupScreenEdgeGesture() {
        let screenEdgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.openMenu))
        screenEdgeGesture.edges = .left
        view.addGestureRecognizer(screenEdgeGesture)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: true, completion: nil )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.tableView.zeroMargin()
    }

    private func addNotificationsObserver() {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(doEnterForeground),
                                                   name: UIWindowScene.willEnterForegroundNotification,
                                                   object: nil)

            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(doEnterBackground),
                                                   name: UIWindowScene.didEnterBackgroundNotification,
                                                   object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timeZoneDidChange),
            name: .NSSystemTimeZoneDidChange,
            object: nil
        )
    }

    private func loadDiffableDataSource() {
        let cellConfigurator = { [weak self] (tableView: UITableView, indexPath: IndexPath, rowItem: MailboxRow) -> UITableViewCell in
            let cellIdentifier: String
            switch rowItem {
            case .real(_):
                cellIdentifier = NewMailboxMessageCell.defaultID()
            case .skeleton(_):
                cellIdentifier = MailBoxSkeletonLoadingCell.Constant.identifier
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
            self?.configure(cell: cell, rowItem: rowItem)
            return cell
        }

        viewModel.setupDiffableDataSource(
            tableView: tableView,
            cellConfigurator: cellConfigurator)
    }

    private func addSubViews() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl.backgroundColor = .clear
        self.refreshControl.addTarget(self, action: #selector(pullDown), for: UIControl.Event.valueChanged)
        self.refreshControl.tintColor = ColorProvider.IconAccent
        self.refreshControl.tintColorDidChange()

        self.view.backgroundColor = ColorProvider.BackgroundNorm
        self.tableView.backgroundColor = UIColor.clear

        self.tableView.addSubview(self.refreshControl)
        self.tableView.delegate = self
        self.tableView.noSeparatorsBelowFooter()

        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.minimumPressDuration = kLongPressDuration
        self.tableView.addGestureRecognizer(longPressGestureRecognizer)

        setUpNoResultView()
        navigationItem.titleView = UIView()
        self.navigationItem.assignNavItemIndentifiers()
    }

    private func setUpNoResultView() {
        let isNotInInbox = viewModel.labelID != Message.Location.inbox.labelID

        let mainText = isNotInInbox ? LocalString._folder_no_message : LocalString._inbox_no_message
        noResultMainLabel.set(text: mainText,
                              preferredFont: .title2)
        noResultMainLabel.isHidden = true

        let subText = isNotInInbox ? LocalString._folder_is_empty : LocalString._inbox_time_to_relax
        noResultSecondaryLabel.set(text: subText,
                                   preferredFont: .body,
                                   textColor: ColorProvider.TextWeak)
        noResultSecondaryLabel.isHidden = true

        noResultFooterLabel.set(text: LocalString._mailbox_footer_no_result,
                                preferredFont: .footnote,
                                textColor: ColorProvider.TextHint)
        noResultFooterLabel.isHidden = true

        noResultImage.image = isNotInInbox ? Asset.mailFolderNoResultIcon.image: Asset.mailNoResultIcon.image
        noResultImage.isHidden = true
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
        view.accessibilityElements = [alertContainerView as Any,
                                      updateTimeLabel as Any,
                                      newElement,
                                      bannerContainer as Any,
                                      tableView as Any,
                                      toolBar as Any,
                                      noResultMainLabel as Any,
                                      noResultImage as Any,
                                      noResultSecondaryLabel as Any]
    }

    private func updateReferralPresenterAndShowPromptIfNeeded() {
        #if DEBUG
        if ProcessInfo.hasLaunchArgument(.showReferralPromptView) {
            let referralPromptView = ReferralPromptView { _ in }
            referralPromptView.present(on: self.navigationController!.view)
            return
        }
        #endif
        guard !ProcessInfo.isRunningUITests,
              let referralProgram = self.viewModel.user.userInfo.referralProgram,
              let navController = navigationController else {
            return
        }
        if self.referralProgramPresenter == nil {
            self.referralProgramPresenter = ReferralProgramPromptPresenter(
                userID: self.viewModel.user.userID,
                referralProgram: referralProgram,
                featureFlagCache: dependencies.userCachedStatus,
                featureFlagService: viewModel.user.featureFlagsDownloadService,
                dependencies: dependencies
            )
        }
        self.referralProgramPresenter?.didShowMailbox()
        if self.referralProgramPresenter?.shouldShowReferralProgramPrompt() == true {
            self.referralProgramPresenter?.promptWasShown()
            let referralPromptView = ReferralPromptView { [weak self] promptView in
                promptView.dismiss()
                self?.coordinator?.go(to: .referAFriend, sender: nil)
            }
            referralPromptView.present(on: navController.view)
        }
    }

    // MARK: - Public methods
    func setNavigationTitleText(_ text: String?) {
        let animation = CATransition()
        animation.duration = 0.25
        animation.type = CATransitionType.fade
        self.navigationController?.navigationBar.layer.add(animation, forKey: "fadeText")
        self.title = text
    }

    func showNoEmailSelected(title: String) {
        let alert = UIAlertController(title: title, message: LocalString._message_list_no_email_selected, preferredStyle: .alert)
        alert.addOKAction()
        self.present(alert, animated: true, completion: nil)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        handleShadow(isScrolled: scrollView.contentOffset.y > 0)
    }

    func presentUpsellPage(entryPoint: UpsellPageEntryPoint, onDismiss: UpsellCoordinator.OnDismissCallback? = nil) {
        upsellCoordinator = dependencies.paymentsUIFactory.makeUpsellCoordinator(rootViewController: self)
        upsellCoordinator?.start(entryPoint: entryPoint, onDismiss: onDismiss)
    }

    // MARK: - Button Targets

    @objc
    func upsellButtonTapped() {
        presentUpsellPage(entryPoint: .header)
        viewModel.upsellButtonWasTapped()
        setupRightButtons(viewModel.listEditing, isStorageExceeded: viewModel.user.isStorageExceeded)
    }

    @objc func composeButtonTapped() {
        coordinator?.go(to: .composer, sender: nil)
    }

    @objc func storageExceededButtonTapped() {
        LocalString._storage_exceeded.alertToastBottom()
    }

    @objc func searchButtonTapped() {
        self.coordinator?.go(to: .search, sender: nil)
    }

    @objc func cancelButtonTapped() {
        hideSelectionMode()
    }

    @objc
    private func preferredContentSizeChanged() {
        // Somehow unreadFilterButton can't reflect font size change automatically
        // reset font again when user preferred font size changed
        unreadFilterButton.titleLabel?.font = .preferredFont(for: .footnote, weight: .semibold)
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
        showEmptyFolderAlert()
    }

    @objc internal func handleLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        self.showCheckOptions(longPressGestureRecognizer)
        updateNavigationController(viewModel.listEditing)

        // invalidate tiemr in multi-selected mode to prevent ui refresh issue
        if viewModel.isNewEventLoopEnabled {
            self.viewModel.stopNewEventLoop()
        } else {
            self.viewModel.eventsService.pause()
        }
    }

    @objc
    func unreadMessageFilterButtonTapped() {
        if viewModel.listEditing {
            hideSelectionMode()
        }
        self.unreadFilterButton.isSelected.toggle()
        let isSelected = self.unreadFilterButton.isSelected
        if isSelected {
            // update the predicate in fetch controller
            self.viewModel.setupFetchController(self, isUnread: true)
        } else {
            self.viewModel.setupFetchController(self, isUnread: false)
        }
        showRefreshController()
        viewModel.updateMailbox(
            showUnreadOnly: isSelected,
            isCleanFetch: false) { [weak self] error in
                DispatchQueue.main.async {
                    self?.handleRequestError(error as NSError)
                }
            } completion: { [weak self] in
                self?.checkContact()
                DispatchQueue.main.async {
                    self?.showNoResultLabelIfNeeded()
                    self?.endRefreshSpinner()
                    self?.tableView.isScrollEnabled = false
                    self?.tableView.setContentOffset(.zero, animated: false)
                    self?.tableView.isScrollEnabled = true
                    self?.updateLastUpdateTimeLabel()
                }
            }
        self.viewModel.isCurrentUserSelectedUnreadFilterInInbox = isSelected
        self.reloadTableViewDataSource()
        self.updateUnreadButton(count: viewModel.unreadCount)
    }

    // MARK: - Private methods

    private func handleViewModeIsChanged() {
        // Cancel selected items
        hideSelectionMode()

        viewModel.setupFetchController(self,
                                       isUnread: viewModel.isCurrentUserSelectedUnreadFilterInInbox)
        self.loadDiffableDataSource()
        self.reloadTableViewDataSource()

        if viewModel.countOfFetchedObjects == 0 {
            viewModel.fetchMessages(time: 0,
                                    isUnread: viewModel.isCurrentUserSelectedUnreadFilterInInbox) { _ in }
        }

        updateUnreadButton(count: viewModel.unreadCount)
        showNoResultLabelIfNeeded()
    }

    // MARK: Auto refresh methods
    private func startAutoFetch(_ run: Bool = true) {
        if viewModel.isNewEventLoopEnabled {
            viewModel.startNewEventLoop()
        } else {
            viewModel.eventsService.start()
            viewModel.eventsService.begin(subscriber: self)
            if run {
                self.viewModel.eventsService.call()
            }
        }
    }

    private func stopAutoFetch() {
        if viewModel.isNewEventLoopEnabled {
            viewModel.stopNewEventLoop()
        } else {
            viewModel.eventsService.pause()
        }
    }

    private func checkContact() {
        self.viewModel.fetchContacts()
    }

    private func checkDoh(_ error: NSError) -> Bool {
        guard BackendConfiguration.shared.doh.errorIndicatesDoHSolvableProblem(error: error) else {
            return false
        }
        self.showError()
        return true

    }

    // MARK: cell configuration methods
    private func configure(cell inputCell: UITableViewCell, rowItem: MailboxRow) {
        switch rowItem {
        case .real(let mailboxItem):
            guard let mailboxCell = inputCell as? NewMailboxMessageCell else {
                assertionFailure("NewMailboxMessageCell was expected for MailboxRow.real")
                return
            }
            mailboxCell.resetCellContent()

            mailboxCell.mailboxItem = mailboxItem
            mailboxCell.cellDelegate = self

            switch mailboxItem {
            case .message(let message):
                let viewModel = buildNewMailboxMessageViewModel(
                    message: message,
                    customFolderLabels: self.viewModel.customFolders,
                    weekStart: viewModel.user.userInfo.weekStartValue, 
                    canSelectMore: viewModel.canSelectMore()
                )
                messageCellPresenter.present(viewModel: viewModel, in: mailboxCell.customView)

                if message.expirationTime != nil &&
                    message.messageLocation != .draft {
                    mailboxCell.startUpdateExpiration()
                }
            case .conversation(let conversation):
                let viewModel = buildNewMailboxMessageViewModel(
                    conversation: conversation,
                    conversationTagUIModels: viewModel.tagUIModels(for: conversation),
                    customFolderLabels: self.viewModel.customFolders,
                    weekStart: viewModel.user.userInfo.weekStartValue, 
                    canSelectMore: viewModel.canSelectMore()
                )
                messageCellPresenter.present(viewModel: viewModel, in: mailboxCell.customView)
            }

            showSenderImageIfNeeded(in: mailboxCell, item: mailboxItem)

            configureSwipeAction(mailboxCell, item: mailboxItem)

#if DEBUG
            mailboxCell.generateCellAccessibilityIdentifiers(mailboxCell.customView.messageContentView.titleLabel.text!)
            mailboxCell.accessibilityValue = mailboxItem.isUnread(labelID: viewModel.labelID) ? "unread" : "read"
#endif
        case .skeleton:
            inputCell.updateAnimatedGradientSkeleton(animation: nil)
            inputCell.showAnimatedGradientSkeleton()
            inputCell.backgroundColor = ColorProvider.BackgroundNorm
            inputCell.accessibilityIdentifier = "SkeletonCell"
        }

        let accessibilityAction =
            UIAccessibilityCustomAction(name: LocalString._accessibility_list_view_custom_action_of_switch_editing_mode,
                                        target: self,
                                        selector: #selector(self.handleAccessibilityAction))
        inputCell.accessibilityCustomActions = [accessibilityAction]
        inputCell.isAccessibilityElement = true
    }

    private func showSenderImageIfNeeded(
        in cell: NewMailboxMessageCell,
        item: MailboxItem
    ) {
        viewModel.fetchSenderImageIfNeeded(
            item: item,
            isDarkMode: isDarkMode,
            scale: currentScreenScale
        ) { [weak self, weak cell] image in
            if let image = image, let cell = cell, cell.mailboxItem == item, self?.viewModel.listEditing == false {
                self?.messageCellPresenter.presentSenderImage(image, in: cell.customView)
            }
        }
    }

    private func showMessageMoved(title: String, undoActionType: UndoAction? = nil) {
        if var type = undoActionType {
            switch type {
            case .custom(Message.Location.archive.labelID):
                type = .archive
            case .custom(Message.Location.trash.labelID):
                type = .trash
            case .custom(Message.Location.spam.labelID):
                type = .spam
            default:
                break
            }
            viewModel.user.undoActionManager.addTitleWithAction(title: title, action: type)
        } else {
            let banner = PMBanner(message: title, style: PMBannerNewStyle.info, bannerHandler: PMBanner.dismiss)
            banner.show(at: .bottom, on: self)
        }
    }

    private func handleRequestError(_ error: NSError) {
        guard connectionStatusProvider.status.isConnected,
              checkDoh(error) == false else { return }

        let errorCode: Int
        let systemErrorsImportantForUser = [
            NSURLErrorTimedOut,
            NSURLErrorNotConnectedToInternet,
            NSURLErrorCannotConnectToHost,
            NSURLErrorBadServerResponse
        ]

        if let responseError = error as? ResponseError,
            !systemErrorsImportantForUser.contains(error.code) {
            errorCode = responseError.bestShotAtReasonableErrorCode
        } else {
            errorCode = error.code
        }

        switch errorCode {
        case NSURLErrorTimedOut, APIErrorCode.HTTP504, APIErrorCode.HTTP404:
            showTimeOutErrorMessage()
        case NSURLErrorNotConnectedToInternet, NSURLErrorCannotConnectToHost:
            showNoInternetErrorMessage()
        case APIErrorCode.API_offline:
            showOfflineErrorMessage(error)
        case APIErrorCode.HTTP503, NSURLErrorBadServerResponse:
            showTimeOutOrProtonUnreachableBanner()
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
            endRefreshSpinner()
            return
        }
        self.replacingEmails = self.viewModel.allEmails
        replacingEmailsMap = generateEmailsMap()
        // to update used space, pull down will wipe event data
        // so the latest used space can't update by event api
        Task {
            await self.viewModel.user.fetchUserInfo()
        }
        hideSelectionMode()
        forceRefreshAllMessages()
        self.viewModel.user.labelService.fetchV4Labels()
        self.showNoResultLabelIfNeeded()
    }

    @objc private func goTroubleshoot() {
        self.coordinator?.go(to: .troubleShoot, sender: nil)
    }

    private func getLatestMessages() {
        self.showRefreshController()
        if self.viewModel.isFirstFetch {
            self.needToShowNewMessage = true
        }

        self.viewModel.updateMailbox(showUnreadOnly: self.isShowingUnreadMessageOnly, isCleanFetch: false) { [weak self] error in
            DispatchQueue.main.async {
                self?.handleRequestError(error as NSError)
            }
        } completion: { [weak self] in
            self?.checkContact()
            DispatchQueue.main.async {
                self?.showNoResultLabelIfNeeded()
                self?.endRefreshSpinner()
                self?.updateLastUpdateTimeLabel()
            }
        }
    }

    private func forceRefreshAllMessages() {
        SystemLogger.log(message: "Will refresh all messages", category: .mailboxRefresh)

        guard !self.viewModel.isFetchingMessage else {
            SystemLogger.log(message: "Fetch already in progress", category: .mailboxRefresh)
            return
        }
        shouldAnimateSkeletonLoading = true

        stopAutoFetch()

        let startTime = Date()
        SystemLogger.log(message: "Refresh started", category: .mailboxRefresh)

        self.viewModel.updateMailbox(showUnreadOnly: self.isShowingUnreadMessageOnly, isCleanFetch: true) {  [weak self] error in
            SystemLogger.log(error: error, category: .mailboxRefresh)

            DispatchQueue.main.async {
                self?.handleRequestError(error as NSError)
            }
        } completion: { [weak self] in
            let timeElapsed = Date().timeIntervalSince(startTime)
            SystemLogger.log(message: "Refresh finished in \(timeElapsed)", category: .mailboxRefresh)

            delay(0.5) {
                self?.shouldAnimateSkeletonLoading = false

                self?.endRefreshSpinner()
                self?.showNoResultLabelIfNeeded()
                self?.updateLastUpdateTimeLabel()
                self?.startAutoFetch(false)
            }
        }
    }

    fileprivate func showNoResultLabelIfNeeded() {
        if viewModel.isFetchingMessage { return }
        delay(0.5) {
            {
                let count = self.viewModel.sectionCount() > 0 ? self.viewModel.rowCount(section: 0) : 0
                if count <= 0 {
                    let isNotInInbox = self.viewModel.labelID != Message.Location.inbox.labelID
                    let noResultImageAsset = isNotInInbox ? Asset.mailFolderNoResultIcon : Asset.mailNoResultIcon
                    self.noResultImage.image = noResultImageAsset.image
                    self.noResultImage.isHidden = false
                    self.noResultMainLabel.isHidden = false
                    self.noResultSecondaryLabel.isHidden = false
                    self.noResultFooterLabel.isHidden = false
                } else {
                    let isHidden = count > 0
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
                if message.contains(location: .scheduled),
                   let scheduledSendTime = message.time,
                   scheduledSendTime.timeIntervalSince(Date()) <= 0 {
                    // Prevent user trying to edit before receiving sent event
                    let alert = LocalString._scheduled_send_message_timeup.alertController()
                    alert.addOKAction()
                    self.present(alert, animated: true, completion: nil)
                    self.updateTapped(status: false)
                    return
                }

                self.coordinator?.go(to: .details, sender: nil)
                self.tableView.indexPathsForSelectedRows?.forEach {
                    self.tableView.deselectRow(at: $0, animated: true)
                }
                self.updateTapped(status: false)
                return
            }
            guard !message.messageID.rawValue.isEmpty else {
                coordinator?.go(to: .composeShow, sender: nil)
                self.updateTapped(status: false)
                return
            }

            guard !viewModel.hasMessageEnqueuedTasks(message.messageID) else {
                LocalString._mailbox_draft_is_uploading.alertToast()
                self.tableView.indexPathsForSelectedRows?.forEach {
                    self.tableView.deselectRow(at: $0, animated: true)
                }
                self.updateTapped(status: false)
                return
            }

            guard connectionStatusProvider.status.isConnected, !message.messageID.hasLocalFormat else {
                defer {
                    self.updateTapped(status: false)
                }
                if !message.body.isEmpty {
                    openCachedDraft(message)
                    return
                }
                let alert = LocalString._unable_to_edit_offline.alertController()
                alert.addOKAction()
                present(alert, animated: true, completion: nil)
                return
            }

            showProgressHud()
            viewModel.fetchMessageDetail(message: message) { [weak self] result in
                self?.hideProgressHud()
                switch result {
                case .failure(let error):
                    let alert = error.localizedDescription.alertController()
                    alert.addOKAction()
                    self?.present(alert, animated: true, completion: nil)
                    self?.tableView.indexPathsForSelectedRows?.forEach {
                        self?.tableView.deselectRow(at: $0, animated: true)
                    }
                    self?.updateTapped(status: false)
                case .success(let msg):
                    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                        guard msg.body.isEmpty == false else { return }
                        timer.invalidate()
                        self?.coordinator?.go(to: .composeShow, sender: msg)
                        self?.tableView.indexPathsForSelectedRows?.forEach {
                            self?.tableView.deselectRow(at: $0, animated: true)
                        }
                        self?.updateTapped(status: false)
                    }
                }
            }
        }
    }

    private func openCachedDraft(_ message: MessageEntity) {
        coordinator?.go(to: .composeShow, sender: message)
        tableView.indexPathsForSelectedRows?.forEach {
            tableView.deselectRow(at: $0, animated: true)
        }
        updateTapped(status: false)
    }

    private func setupLeftButtons(_ editingMode: Bool) {
        let menuButton = makeMenuButton(userInfo: dependencies.user.userInfo)
        menuButton.customView?.alpha = editingMode ? 0 : 1

        let titleItem = UIBarButtonItem(customView: titleLabel)

        let leftBarButtonItems: [UIBarButtonItem] = [
            menuButton,
            .fixedSpace(20),
            titleItem
        ]

        navigationItem.setLeftBarButtonItems(leftBarButtonItems, animated: true)
    }

    private func setupNavigationTitle(showSelected: Bool) {
        if showSelected {
            let count = self.viewModel.selectedIDs.count
            let title = String(format: LocalString._selected_navogationTitle, count)
            self.setNavigationTitleText(title)
        } else {
            self.setNavigationTitleText(viewModel.localizedNavigationTitle)
        }
    }

    private func updateNavigationController(_ editingMode: Bool) {
        self.setupLeftButtons(editingMode)
        self.setupNavigationTitle(showSelected: editingMode)
        self.setupRightButtons(
            editingMode,
            isStorageExceeded: viewModel.user.isStorageExceeded)
    }

    private func retry(delay: Double = 0) {
        // When network reconnect, the DNS data seems will miss at a short time
        // Delay 5 seconds to retry can prevent some relative error
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.getLatestMessages()
        }
    }

    private func updateLastUpdateTimeLabel() {
        if let status = self.lastNetworkStatus, status == .notConnected {
            updateTimeLabel.set(text: LocalString._mailbox_offline_text,
                                preferredFont: .footnote,
                                weight: .regular,
                                textColor: ColorProvider.NotificationError)
            return
        }

        if !viewModel.isFetchingMessage {
            // last update time only updated when all requests for messages have finished
            let timeText = viewModel.getLastUpdateTimeText()
            updateTimeLabel.set(
                text: timeText,
                preferredFont: .footnote,
                weight: .regular,
                textColor: ColorProvider.TextHint
            )
        }
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

        PMBanner.dismissAll(on: self)

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
        if viewModel.storageAlertVisibility != .hidden {
            isScrolled ? alertCardView.layer.apply(shadow: .custom(y: 2, blur: 2)) : alertCardView.layer.clearShadow()
        } else {
            isScrolled ? topActionsView.layer.apply(shadow: .custom(y: 2, blur: 2)) : topActionsView.layer.clearShadow()
        }
    }

    private func updateScheduledMessageTimeLabel() {
        guard viewModel.labelID.rawValue == Message.Location.scheduled.rawValue else {
            return
        }

            reloadTableViewDataSource()
    }

    private func fetchEventInScheduledSend() {
        guard viewModel.labelId == Message.Location.scheduled.labelID else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(15)) { [weak self] in
            guard let self = self else {
                return
            }
            if viewModel.isNewEventLoopEnabled {
                self.viewModel.fetchEventsWithNewEventLoop()
            } else {
                self.viewModel.eventsService.fetchEvents(labelID: self.viewModel.labelId)
            }
        }
    }

    private func generateEmailsMap() -> [String: EmailEntity] {
        return replacingEmails.reduce(into: [:], { partialResult, email in
            partialResult[email.email] = email
        })
    }

    private func reloadIfSwipeActionsDidChange() {
        if configuredActions.isEmpty,
           configuredActions[.left] == dependencies.userCachedStatus.leftToRightSwipeActionType,
           configuredActions[.right] == dependencies.userCachedStatus.rightToLeftSwipeActionType {
            return
        }
        tableView.reloadData()
    }

    private func showSpotlightIfNeeded() {
        if viewModel.shouldShowDynamicFontSizeSpotlight() {
            showDynamicFontSizeSpotlight()
        } else if viewModel.shouldShowSpotlight(for: .answerInvitation) {
            showAnswerInvitationSpotlight()
        } else if viewModel.shouldShowAutoImportContactsSpotlight() {
            showAutoImportContactsSpotlight()
        } else if viewModel.shouldShowSpotlight(for: .jumpToNextMessage) {
            showJumpToNextMessageSpotlight()
        }
    }

    private func showDynamicFontSizeSpotlight() {
        let spotlightView = DynamicFontSizeSpotlightView()
        let hosting = SheetLikeSpotlightViewController(rootView: spotlightView)
        spotlightView.config.hostingController = hosting
        navigationController?.present(hosting, animated: false)
        viewModel.hasSeenSpotlight(for: .dynamicFontSize)
    }

    private func showAnswerInvitationSpotlight() {
        let spotlightView = AnswerInvitationSpotlightView()
        let hosting = SheetLikeSpotlightViewController(rootView: spotlightView)
        spotlightView.config.hostingController = hosting
        navigationController?.present(hosting, animated: false)
        viewModel.hasSeenSpotlight(for: .answerInvitation)
    }

    private func showJumpToNextMessageSpotlight() {
        let spotlightView = JumpToNextSpotlightView(
            buttonTitle: L10n.NextMsgAfterMove.spotlightButtonTitle,
            message: L10n.NextMsgAfterMove.spotlightMessage,
            title: L10n.NextMsgAfterMove.spotlightTitle
        ) { [weak self] hostingVC, didTapActionButton in
            hostingVC?.dismiss(animated: false)
            if didTapActionButton {
                self?.showProgressHud()
                self?.viewModel.enableJumpToNextMessage() {
                    self?.hideProgressHud()
                }
            }
        }
        let hosting = SheetLikeSpotlightViewController(rootView: spotlightView)
        spotlightView.config.hostingController = hosting
        navigationController?.present(hosting, animated: false)
        viewModel.hasSeenSpotlight(for: .jumpToNextMessage)
    }

    private func showAutoImportContactsSpotlight() {
        let spotlightView = AutoImportContactsSpotlightView(
            buttonTitle: L10n.AutoImportContacts.spotlightButtonTitle,
            message: L10n.AutoImportContacts.spotlightMessage,
            title: L10n.AutoImportContacts.spotlightTitle
        ) { [weak self] hostingVC, didTapActionButton in
            hostingVC?.dismiss(animated: false)
            if didTapActionButton {
                self?.dependencies.addressBookService.requestAuthorizationWithCompletion { granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            self?.viewModel.enableAutoImportContact()
                        } else {
                            self?.showContactAccessIsDenied()
                        }
                    }
                }
            }
        }
        let hosting = SheetLikeSpotlightViewController(rootView: spotlightView)
        spotlightView.config.hostingController = hosting
        navigationController?.present(hosting, animated: false)
        viewModel.hasSeenAutoImportContactsSpotlight()
    }

    private func showContactAccessIsDenied() {
        let alert = UIAlertController(
            title: L10n.SettingsContacts.autoImportContacts,
            message: L10n.SettingsContacts.authoriseContactsInSettingsApp,
            preferredStyle: .alert
        )
        alert.addOKAction()
        present(alert, animated: true, completion: nil)
    }

    private func endRefreshSpinner() {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        updateUnreadButton(count: viewModel.unreadCount)
    }
}

// MARK: - Selection mode
extension MailboxViewController {
    private func enterListEditingMode(indexPath: IndexPath) {
        self.viewModel.listEditing = true
        updateSelectAllButton()
        updateTopBarItemDisplay()

        guard let visibleRowsIndexPaths = self.tableView.indexPathsForVisibleRows else { return }
        visibleRowsIndexPaths.forEach { visibleRowIndexPath in
            let visibleCell = self.tableView.cellForRow(at: visibleRowIndexPath)
            guard let messageCell = visibleCell as? NewMailboxMessageCell else { return }
            messageCellPresenter.presentSelectionStyle(
                style: .selection(isSelected: false, isAbleToBeSelected: viewModel.canSelectMore()),
                in: messageCell.customView
            )
            guard indexPath == visibleRowIndexPath else { return }
            tableView(tableView, didSelectRowAt: indexPath)
        }
    }

    private func hideSelectionMode() {
        self.hideCheckOptions()
        self.updateNavigationController(false)

        if viewModel.isNewEventLoopEnabled {
            viewModel.startNewEventLoop()
        } else {
            if viewModel.eventsService.status != .running {
                self.startAutoFetch(false)
            }
        }

        self.hideActionBar()
        self.dismissActionSheet()
    }

    private func hideCheckOptions() {
        guard viewModel.listEditing else { return }
        viewModel.listEditing = false
        updateTopBarItemDisplay()
        tableView.reloadData()
    }

    private func showCheckOptions(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        let point: CGPoint = longPressGestureRecognizer.location(in: self.tableView)
        let indexPath: IndexPath? = self.tableView.indexPathForRow(at: point)
        guard let touchedRowIndexPath = indexPath,
              longPressGestureRecognizer.state == .began && viewModel.listEditing == false else { return }
        enterListEditingMode(indexPath: touchedRowIndexPath)
    }

    private func updateTopBarItemDisplay() {
        updateTimeLabel.isHidden = viewModel.listEditing
        selectAllButton.isHidden = !viewModel.listEditing
        if viewModel.listEditing {
            unreadFilterButton.isHidden = true
        } else {
            unreadFilterButton.isHidden = viewModel.unreadCount == 0
        }
    }

    @objc
    private func tapSelectAllButton() {
        selectAllButton.backgroundColor = ColorProvider.BackgroundSecondary
        UIView.animate(withDuration: 0.25) {
            self.selectAllButton.backgroundColor = .clear
        }
        if selectAllLabel.text == L10n.MailBox.selectAll {
            selectAllMessages()
        } else {
            viewModel.removeAllSelectedIDs()
        }

        updateSelectAllButton()
        hapticFeedbackGenerator.impactOccurred()

        // update checkbox state
        updateCellBasedOnSelectionStatus()

        setupNavigationTitle(showSelected: true)
        PMBanner.dismissAll(on: self)
        refreshActionBarItems()
        showActionBar()
    }

    private func selectAllMessages() {
        let indexPaths = Array(0..<viewModel.rowCount(section: 0))
            .map { IndexPath(row: $0, section: 0) }
        let loadedIDs = indexPaths
            .compactMap { index -> (String, IndexPath)? in
                guard let item = viewModel.mailboxItem(at: index) else { return nil }
                return (item.itemID, index)
            }
        var pathsShouldBeUpdated: [IndexPath] = []
        for dataSet in loadedIDs {
            guard viewModel.select(id: dataSet.0) else { break }
            pathsShouldBeUpdated.append(dataSet.1)
            guard viewModel.canSelectMore() else { break }
        }
    }

    private func updateSelectAllButton() {
        switch (viewModel.canSelectMore(), viewModel.isAllLoadedMessagesSelected) {
        case (true, true):
            selectAllIcon.tintColor = ColorProvider.IconAccent
            selectAllIcon.image = Asset.icSquareChecked.image
            selectAllLabel.textColor = ColorProvider.TextAccent
            selectAllLabel.text = L10n.MailBox.unselectAll
            selectAllButton.isUserInteractionEnabled = true
        case (true, false):
            selectAllIcon.tintColor = ColorProvider.IconAccent
            selectAllIcon.image = Asset.icSquare.image
            selectAllLabel.textColor = ColorProvider.TextAccent
            selectAllLabel.text = L10n.MailBox.selectAll
            selectAllButton.isUserInteractionEnabled = true
        case (false, _):
            selectAllIcon.tintColor = ColorProvider.IconDisabled
            selectAllIcon.image = Asset.icSquare.image
            selectAllLabel.textColor = ColorProvider.TextDisabled
            selectAllLabel.text = L10n.MailBox.selectAll
            selectAllButton.isUserInteractionEnabled = false
        }
    }

    private func updateCellBasedOnSelectionStatus() {
        let indexPaths = Array(0..<viewModel.rowCount(section: 0))
            .map { IndexPath(row: $0, section: 0) }

        let loadedIDs = indexPaths
            .compactMap { index -> (Bool, IndexPath)? in
                guard let item = viewModel.mailboxItem(at: index) else { return nil }
                let isSelected = viewModel.selectionContains(id: item.itemID)
                return (isSelected, index)
            }

        for dataSet in loadedIDs {
            guard let cell = tableView.cellForRow(at: dataSet.1) as? NewMailboxMessageCell else { continue }
            messageCellPresenter.presentSelectionStyle(
                style: .selection(isSelected: dataSet.0, isAbleToBeSelected: viewModel.canSelectMore()),
                in: cell.customView
            )
        }
    }
}

// MARK: - Swipe action
extension MailboxViewController {
    private func configureSwipeAction(_ cell: NewMailboxMessageCell, item: MailboxItem) {
        cell.delegate = self

        var actions: [SwipyCellDirection: SwipeActionSettingType] = [:]
        actions[.left] = dependencies.userCachedStatus.leftToRightSwipeActionType
        actions[.right] = dependencies.userCachedStatus.rightToLeftSwipeActionType
        configuredActions[.left] = dependencies.userCachedStatus.leftToRightSwipeActionType
        configuredActions[.right] = dependencies.userCachedStatus.rightToLeftSwipeActionType

        cell.removeAllSwipeTriggers()

        for (direction, action) in actions {
            let msgAction = viewModel.convertSwipeActionTypeToMessageSwipeAction(
                action,
                isStarred: item.isStarred,
                isUnread: item.isUnread(labelID: viewModel.labelID)
            )

            guard msgAction != .none && viewModel.isSwipeActionValid(msgAction, item: item) else {
                continue
            }

            // without calling this, the cell cannot be swiped
            // `completion` is nil because the logic in SwipyCell is flawed
            // the only reason we use this library is for the animation and handling the gesture
            cell.addSwipeTrigger(
                forState: .state(0, direction),
                withMode: .exit,
                swipeView: makeSwipeView(messageSwipeAction: msgAction),
                swipeColor: msgAction.actionColor,
                completion: nil
            )

            cell.swipeActions[direction] = msgAction
        }
    }

    private func handleSwipeAction(on cell: SwipyCell, action: MessageSwipeAction, item: MailboxItem) {
        let continueAction = { [weak self] in
            defer {
                cell.swipeToOrigin {}
                self?.viewModel.removeAllSelectedIDs()
            }
            let hasBeenMoved = self?.processSwipeActions(action, item: item)

            guard hasBeenMoved == false else {
                return
            }

            // Since the read action will try to swipe the cell to origin. It conflicts with the animation of removing the cell from tableView.
            // Here to prevent the cell swiping to origin to remove weird animation.
            guard self?.unreadFilterButton.isSelected == false && action != .read else {
                return
            }
        }

        if item.isScheduledForSending && action == .trash {
            cell.swipeToOrigin {}
            displayScheduledAlert(scheduledNum: 1, continueAction: continueAction)
        } else {
            continueAction()
        }
    }

    private func processSwipeActions(_ action: MessageSwipeAction, item: MailboxItem) -> Bool {
        /// UIAccessibility
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: action.description)
        viewModel.removeAllSelectedIDs()
       _ = viewModel.select(id: item.itemID)
        switch action {
        case .none:
            return false
        case .labelAs:
            labelButtonTapped(isFromSwipeAction: true)
            return false
        case .moveTo:
            folderButtonTapped(isFromSwipeAction: true)
            return true
        case .unread, .read, .star, .unstar:
            viewModel.handleSwipeAction(action, on: item)
            return false
        case .trash:
            guard viewModel.labelID != Message.Location.trash.labelID else { return true }
            let message: String
            let undoAction: UndoAction?
            if item.isScheduledForSending {
                message = String(format: LocalString._message_moved_to_drafts, 1)
                undoAction = nil
            } else {
                message = LocalString._inbox_swipe_to_trash_banner_title
                undoAction = .trash
            }

            showMessageMoved(title: message, undoActionType: undoAction)
            viewModel.handleSwipeAction(.trash, on: item)
            return true
        case .archive:
            viewModel.handleSwipeAction(.archive, on: item)
            showMessageMoved(title: LocalString._inbox_swipe_to_archive_banner_title, undoActionType: .archive)
            return true
        case .spam:
            viewModel.handleSwipeAction(.spam, on: item)
            showMessageMoved(title: LocalString._inbox_swipe_to_spam_banner_title, undoActionType: .spam)
            return true
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
        attribute[.foregroundColor] = ColorProvider.TextInverted as UIColor
        label.attributedText = messageSwipeAction.description.apply(style: attribute)
        iconView.image = messageSwipeAction.icon
        iconView.tintColor = ColorProvider.TextInverted

        return stackView
    }
}

// MARK: - Action bar
extension MailboxViewController {
    func refreshActionBarItems() {
        let actions = self.viewModel.actionsForToolbar()
        var actionItems: [PMToolBarView.ActionItem] = []

        for action in actions {
            let actionHandler: () -> Void = { [weak self] in
                guard let self = self else { return }
                self.handle(action: action)
            }

            let barItem = PMToolBarView.ActionItem(type: action, handler: actionHandler)
            actionItems.append(barItem)
        }
        self.toolBar.setUpActions(actionItems)
    }

    // Actions from action bar or action sheet
    private func handle(action: MessageViewActionSheetAction) {
        if action != .more && viewModel.selectedIDs.isEmpty {
            self.showNoEmailSelected(title: LocalString._warning)
            return
        }

        switch action {
        case .archive, .spam, .inbox, .spamMoveToInbox:
            viewModel.handleBarActions(action) { [weak self] in
                self?.showMessageMoved(title: LocalString._messages_has_been_moved)
                self?.hideSelectionMode()
            }
        case .delete:
            self.showDeleteAlert { [weak self] in
                guard let `self` = self else { return }
                self.viewModel.deleteSelectedIDs()
                self.showMessageMoved(title: LocalString._messages_has_been_deleted)
            }
        case .dismiss:
            dismissActionSheet()
        case .labelAs:
            labelButtonTapped()
        case .markRead, .markUnread, .star, .unstar:
            viewModel.handleBarActions(action, completion: nil)
        case .snooze:
            clickSnoozeActionButton()
        case .moveTo:
            folderButtonTapped()
        case .trash:
            var scheduledSendNum: Int?
            let continueAction: () -> Void = { [weak self] in
                self?.fetchingOlder = true
                self?.viewModel.handleBarActions(action) {
                    self?.hideSelectionMode()
                    let title: String
                    if let num = scheduledSendNum {
                        title = String(format: LocalString._message_moved_to_drafts, num)
                    } else {
                        title = LocalString._messages_has_been_moved
                    }
                    self?.showMessageMoved(title: title)
                    self?.fetchingOlder = false
                }
            }
            viewModel.searchForScheduled(
                swipeSelectedID: [],
                displayAlert: { [weak self] selectedNum in
                    scheduledSendNum = selectedNum
                    self?.displayScheduledAlert(scheduledNum: selectedNum, continueAction: continueAction)
                },
                continueAction: continueAction
            )
        case .toolbarCustomization:
            let allActions = viewModel.toolbarCustomizationAllAvailableActions()
            let currentActions = viewModel.actionsForToolbarCustomizeView().replaceReplyAndReplyAllAction()
            coordinator?.presentToolbarCustomizationView(
                allActions: allActions,
                currentActions: currentActions
            )
        case .more:
            moreButtonTapped()
        case .reply, .replyAll, .forward, .print, .viewHTML, .reportPhishing,
                .viewInDarkMode, .viewInLightMode, .replyOrReplyAll, .saveAsPDF,
                .replyInConversation, .forwardInConversation, .replyOrReplyAllInConversation,
                .replyAllInConversation, .viewHeaders:
            // These options won't be included in action bar and action sheet
            break
        }
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
        let message = String(format: LocalString._messages_delete_confirmation_alert_message, messagesCount)
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

    private func showEmptyFolderAlert() {
        let isTrashFolder = self.viewModel.labelID == LabelLocation.trash.labelID
        let title = isTrashFolder ? LocalString._empty_trash_folder: LocalString._empty_spam_folder

        guard let labelLocation = LabelLocation.allCases.first(where: { $0.labelID == viewModel.labelID }) else {
            return
        }

        let message = viewModel.getEmptyFolderCheckMessage(folder: labelLocation)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: LocalString._general_delete_action, style: .destructive) { [weak self] _ in
            self?.viewModel.emptyFolder()
        }
        let cancelAction = UIAlertAction(title: LocalString._general_cancel_action, style: .cancel, handler: nil)
        [deleteAction, cancelAction].forEach(alert.addAction)
        self.present(alert, animated: true, completion: nil)
    }

    @objc
    private func handleAccessibilityAction() {
        viewModel.listEditing.toggle()
        updateNavigationController(viewModel.listEditing)
    }

    func moreButtonTapped() {
        mailListActionSheetPresenter.present(
            on: navigationController ?? self,
            viewModel: viewModel.actionSheetViewModel,
            action: { [weak self] in
                self?.handle(action: $0)
            }
        )
    }
}

extension MailboxViewController {
    var labelAsActionHandler: LabelAsActionSheetProtocol {
        return viewModel
    }

    func labelButtonTapped(isFromSwipeAction: Bool = false) {
        guard !viewModel.selectedIDs.isEmpty else {
            showNoEmailSelected(title: LocalString._apply_labels)
            return
        }
        switch viewModel.locationViewMode {
        case .conversation:
            showLabelAsActionSheet(conversations: viewModel.selectedConversations, isFromSwipeAction: isFromSwipeAction)
        case .singleMessage:
            showLabelAsActionSheet(messages: viewModel.selectedMessages, isFromSwipeAction: isFromSwipeAction)
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
                    self.coordinator?.go(to: .newLabel, sender: nil)
                } else {
                    self.presentUpsellPage(entryPoint: .labels) { [weak self] in
                        self?.showLabelAsActionSheet(messages: messages, isFromSwipeAction: isFromSwipeAction)
                    }
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
                    self.coordinator?.go(to: .newLabel, sender: nil)
                } else {
                    self.presentUpsellPage(entryPoint: .labels) { [weak self] in
                        self?.showLabelAsActionSheet(conversations: conversations, isFromSwipeAction: isFromSwipeAction)
                    }
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
        let isFreeAccount = viewModel.user.userInfo.subscribed.isEmpty
        if isFreeAccount {
            return existingLabels < Constants.FreePlan.maxNumberOfLabels
        }
        return true
    }
}

extension MailboxViewController {
    func folderButtonTapped(isFromSwipeAction: Bool = false) {
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
                                  isInherit: isInherit,
                                  isFromSwipeAction: isFromSwipeAction
            )
        } else if !conversations.isEmpty {
            showMoveToActionSheet(conversations: conversations,
                                  isEnableColor: isEnableColor,
                                  isInherit: isInherit,
                                  isFromSwipeAction: isFromSwipeAction
            )
        }
    }

    private func showMoveToActionSheet(
        messages: [MessageEntity],
        isEnableColor: Bool,
        isInherit: Bool,
        isFromSwipeAction: Bool = false
    ) {
        var menuLabels = viewModel.getFolderMenuItems()
        if viewModel.messageLocation == .sent {
            menuLabels.removeAll(where: { $0.location == .inbox })
        }
        let moveToViewModel = MoveToActionSheetViewModelMessages(
            menuLabels: menuLabels,
            isEnableColor: isEnableColor,
            isInherit: isInherit
        )
        moveToActionSheetPresenter.present(
            on: self.navigationController ?? self,
            viewModel: moveToViewModel,
            addNewFolder: { [weak self] in
                guard let self = self else { return }
                if self.allowToCreateFolders(existingFolders: self.viewModel.getCustomFolderMenuItems().count) {
                    self.coordinator?.pendingActionAfterDismissal = { [weak self] in
                        self?.showMoveToActionSheet(
                            messages: messages,
                            isEnableColor: isEnableColor,
                            isInherit: isInherit
                        )
                    }
                    self.coordinator?.go(to: .newFolder, sender: nil)
                } else {
                    self.presentUpsellPage(entryPoint: .folders) { [weak self] in
                        self?.showMoveToActionSheet(
                            messages: messages,
                            isEnableColor: isEnableColor,
                            isInherit: isInherit,
                            isFromSwipeAction: isFromSwipeAction
                        )
                    }
                }
            },
            selected: { [weak self] menuLabel, isSelected in
                guard isSelected else { return }
                self?.didSelectFolderToMoveToForMessages(
                    folder: menuLabel,
                    messages: messages,
                    isSwipeAction: isFromSwipeAction
                )
            },
            cancel: { [weak self] in
                self?.dismissActionSheet()
            }
        )
    }

    private func didSelectFolderToMoveToForMessages(folder: MenuLabel, messages: [MessageEntity], isSwipeAction: Bool) {
        defer {
            dismissActionSheet()
            hideSelectionMode()
        }

        var scheduledSendNum: Int?
        let continueAction: () -> Void = { [weak self] in
            self?.viewModel.handleMoveToAction(messages: messages, to: folder)
            if isSwipeAction {
                let title: String
                if let num = scheduledSendNum {
                    title = String(format: LocalString._message_moved_to_drafts, num)
                } else {
                    title = String.localizedStringWithFormat(
                        LocalString._inbox_swipe_to_move_banner_title,
                        messages.count,
                        folder.name
                    )
                }
                self?.showMessageMoved(title: title, undoActionType: .custom(folder.location.labelID))
            }
        }

        if folder.location == .trash {
            viewModel.searchForScheduled(
                swipeSelectedID: messages.map { $0.messageID.rawValue },
                displayAlert: { [weak self] selectedNum in
                    scheduledSendNum = selectedNum
                    self?.displayScheduledAlert(scheduledNum: selectedNum, continueAction: continueAction)
                },
                continueAction: continueAction)
        } else {
            continueAction()
        }
    }

    private func showMoveToActionSheet(
        conversations: [ConversationEntity],
        isEnableColor: Bool,
        isInherit: Bool,
        isFromSwipeAction: Bool = false
    ) {
        let moveToViewModel = MoveToActionSheetViewModelConversations(
            menuLabels: viewModel.getFolderMenuItems(),
            isEnableColor: isEnableColor,
            isInherit: isInherit
        )
        moveToActionSheetPresenter.present(
            on: self.navigationController ?? self,
            viewModel: moveToViewModel,
            addNewFolder: { [weak self] in
                guard let self = self else { return }
                if self.allowToCreateFolders(existingFolders: self.viewModel.getCustomFolderMenuItems().count) {
                    self.coordinator?.pendingActionAfterDismissal = { [weak self] in
                        self?.showMoveToActionSheet(
                            conversations: conversations,
                            isEnableColor: isEnableColor,
                            isInherit: isInherit
                        )
                    }
                    self.coordinator?.go(to: .newFolder, sender: nil)
                } else {
                    self.presentUpsellPage(entryPoint: .folders) { [weak self] in
                        self?.showMoveToActionSheet(
                            conversations: conversations,
                            isEnableColor: isEnableColor,
                            isInherit: isInherit,
                            isFromSwipeAction: isFromSwipeAction
                        )
                    }
                }
            },
            selected: { [weak self] menuLabel, isSelected in
                guard isSelected else { return }
                self?.didSelectFolderToMoveToForConversations(
                    folder: menuLabel,
                    conversations: conversations,
                    isSwipeAction: isFromSwipeAction
                )
            },
            cancel: { [weak self] in
                self?.dismissActionSheet()
            }
        )
    }

    private func didSelectFolderToMoveToForConversations(
        folder: MenuLabel,
        conversations: [ConversationEntity],
        isSwipeAction: Bool
    ) {
        defer {
            dismissActionSheet()
            hideSelectionMode()
        }

        var scheduledSendNum: Int?
        let continueAction: () -> Void = { [weak self] in
            self?.viewModel.handleMoveToAction(
                conversations: conversations,
                to: folder,
                completion: nil
            )
            if isSwipeAction {
                let title: String
                if let num = scheduledSendNum {
                    title = String(format: LocalString._message_moved_to_drafts, num)
                } else {
                    title = String.localizedStringWithFormat(
                        LocalString._inbox_swipe_to_move_conversation_banner_title,
                        conversations.count,
                        folder.name
                    )
                }
                self?.showMessageMoved(title: title, undoActionType: .custom(folder.location.labelID))
            }
        }

        if folder.location == .trash {
            viewModel.searchForScheduled(
                swipeSelectedID: conversations.map { $0.conversationID.rawValue },
                displayAlert: { [weak self] selectedNum in
                    scheduledSendNum = selectedNum
                    self?.displayScheduledAlert(scheduledNum: selectedNum, continueAction: continueAction)
                },
                continueAction: continueAction
            )
        } else {
            continueAction()
        }
    }

    private func allowToCreateFolders(existingFolders: Int) -> Bool {
        let isFreeAccount = viewModel.user.userInfo.subscribed.isEmpty
        if isFreeAccount {
            return existingFolders < Constants.FreePlan.maxNumberOfFolders
        }
        return true
    }
}

// MARK: - Show banner or alert
extension MailboxViewController {

    private func setupAlertBox() {
        viewModel.setupAlertBox()
        guard viewModel.storageAlertVisibility != .hidden || viewModel.lockedStateAlertVisibility != .hidden else {
            alertContainerView.isHidden = true
            return
        }
        alertContainerView.isHidden = false
        alertContainerView.layer.zPosition = tableView.layer.zPosition + 1
        alertCardView.backgroundColor = ColorProvider.BackgroundSecondary
        alertCardView.layer.cornerRadius = 8
        alertIcon.image = IconProvider.exclamationCircleFilled

        alertLabel.textColor = ColorProvider.TextNorm
        alertDescription.textColor = ColorProvider.TextNorm
        alertDescription.numberOfLines = 0
        alertDismissButton.setTitle(L10n.AlertBox.alertBoxDismissButtonTitle, for: .normal)
        alertButton.layer.cornerRadius = 8
        alertButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        if (viewModel.lockedStateAlertVisibility != .hidden) {
            setupLockedStateAlertBox()
        } else if (viewModel.storageAlertVisibility != .hidden) {
            setupStorageAlertBox()
        }
    }

    private func setupLockedStateAlertBox() {
        alertIcon.tintColor = ColorProvider.NotificationError
        alertDismissButton.isHidden = true
        
        alertLabel.text = viewModel.lockedStateAlertVisibility.mailboxBannerTitle
        alertDescription.text = viewModel.lockedStateAlertVisibility.mailboxBannerDescription
        alertButton.setTitle(viewModel.lockedStateAlertVisibility.mailBoxBannerButtonTitle, for: .normal)
        alertButton.addTarget(
            self,
            action: #selector(lockedStateBannerTapped),
            for: .touchUpInside
        )
    }

    private func setupStorageAlertBox() {
        alertLabel.text = viewModel.storageAlertVisibility.mailboxBannerTitle
        switch viewModel.storageAlertVisibility {
        case .mail(let value) where value < StorageAlertVisibility.fullThreshold,
             .drive(let value) where value < StorageAlertVisibility.fullThreshold:
            alertDismissButton.isHidden = false
            alertDescription.isHidden = true
            alertIcon.tintColor = ColorProvider.NotificationWarning
        case .mail, .drive:
            alertDismissButton.isHidden = true
            alertDescription.isHidden = false
            alertIcon.tintColor = ColorProvider.NotificationError
        case .hidden:
            break
        }
        
        alertDescription.text = L10n.AlertBox.alertBoxDescription
        alertButton.setTitle(L10n.AlertBox.alertBoxButtonTitle, for: .normal)
        alertButton.addTarget(
            self,
            action: #selector(getMoreStorageTapped),
            for: .touchUpInside
        )
        alertDismissButton.addTarget(
            self,
            action: #selector(dismissStorageAlertTapped),
            for: .touchUpInside
        )
    }
    
    @objc private func lockedStateBannerTapped() {
        guard let urlString = viewModel.lockedStateAlertVisibility.mailBoxBannerButtonUrl,
              let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func getMoreStorageTapped() {
        self.coordinator?.go(to: .subscriptions, sender: nil)
    }

    @objc private func dismissStorageAlertTapped() {
        viewModel.onStorageAlertDismissed()
        alertContainerView.isHidden = true
    }

    private func showErrorMessage(_ error: NSError) {
        guard UIApplication.shared.applicationState == .active else { return }
        var message = error.localizedDescription
        if let responseError = error as? ResponseError {
            message = responseError.localizedDescription
        }
        let banner = PMBanner(
            message: message,
            style: PMBannerNewStyle.error,
            dismissDuration: .infinity,
            bannerHandler: PMBanner.dismiss
        )
        banner.show(at: .top, on: self)
    }

    private func showTimeOutErrorMessage() {
        showRetryBanner(message: LocalString._general_request_timed_out)
    }

    private func showNoInternetErrorMessage() {
        guard !isInternetBannerPresented else {
            return
        }
        showRetryBanner(message: LocalString._general_no_connectivity_detected)
    }

    internal func showOfflineErrorMessage(_ error: NSError) {
        showRetryBanner(message: error.localizedDescription)
    }

    private func showRetryBanner(message: String) {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(
            message: message,
            style: PMBannerNewStyle.error,
            dismissDuration: 5.0,
            bannerHandler: PMBanner.dismiss
        )
        banner.addButton(text: LocalString._retry) { [weak self] _ in
            banner.dismiss()
            self?.getLatestMessages()
        }
        banner.show(at: .top, on: self)
    }

    private func showError() {
        guard UIApplication.shared.applicationState == .active else {
            return
        }
        let banner = PMBanner(
            message: "We could not connect to the servers. Pull down to retry.",
            style: PMBannerNewStyle.error,
            dismissDuration: 5.0,
            bannerHandler: PMBanner.dismiss
        )
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

    private func showTimeOutOrProtonUnreachableBanner() {
        viewModel.isProtonUnreachable { [weak self] isProtonUnreachable in
            guard let self else { return }
            if isProtonUnreachable {
                PMBanner.showProtonUnreachable(on: self)
            } else {
                self.showTimeOutErrorMessage()
            }
        }
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

        updateLastUpdateTimeLabel()
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

// MARK: - NSFetchedResultsControllerDelegate

extension MailboxViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let remappedSnapshot = remapToNewSnapshot(controller: controller, snapshot: snapshot)
        removeDeletedIDFromSelectedItem(snapshot: remappedSnapshot)
        if shouldAnimateSkeletonLoading {
            viewModel.diffableDataSource?.cacheSnapshot(remappedSnapshot)
            return
        }
        if isSwipingCell {
            viewModel.diffableDataSource?.cacheSnapshot(remappedSnapshot)
            contentChangeOccurredDuringLastSwipeGesture = true
            return
        }

        fetchOlderMessageWhenNeeded(remappedSnapshot: remappedSnapshot)

        reloadTableViewDataSource(
            snapshot: remappedSnapshot
        ) {
            DispatchQueue.main.async {
                self.updateTitle()
                self.updateSelectAllButton()
                self.refreshActionBarItems()
                self.showNewMessageCount(self.newMessageCount)
            }
        }
    }

    private func remapToNewSnapshot(controller: NSFetchedResultsController<NSFetchRequestResult>, snapshot: NSDiffableDataSourceSnapshotReference) -> NSDiffableDataSourceSnapshot<Int, MailboxRow> {
        let viewMode = viewModel.locationViewMode
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        var newSnapshot = NSDiffableDataSourceSnapshot<Int, MailboxRow>()
        for (index, section) in snapshot.sectionIdentifiers.enumerated() {
            let items = snapshot.itemIdentifiers(inSection: section)
            var mailboxRows = items.compactMap { objectID in
                let object = controller.managedObjectContext.object(with: objectID)
                switch viewMode {
                case .singleMessage:
                    if let message = object as? Message {
                        return MailboxRow.real(.message(.init(message)))
                    }
                case .conversation:
                    if let contextLabel = object as? ContextLabel,
                       let conversation = contextLabel.conversation {
                        return MailboxRow.real(.conversation(.init(conversation)))
                    }
                }
                return nil
            }

            if viewModel.labelID == Message.Location.inbox.labelID {
                mailboxRows.sort { row1, row2 in
                    guard
                        case .real(let item1) = row1,
                        case .real(let item2) = row2,
                        case .message(let message1) = item1,
                        case .message(let message2) = item2
                    else { return false }

                    let date1 = message1.snoozeTime ?? message1.time ?? .distantFuture
                    let date2 = message2.snoozeTime ?? message2.time ?? .distantFuture
                    return date1 > date2
                }
            }

            newSnapshot.appendSections([index])
            newSnapshot.appendItems(mailboxRows, toSection: index)
        }
        return newSnapshot
    }

    private func removeDeletedIDFromSelectedItem(snapshot: NSDiffableDataSourceSnapshot<Int, MailboxRow>) {
        let existingIDs = Set(snapshot.itemIdentifiers(inSection: 0).compactMap { row -> String? in
            guard case .real(let mailboxItem) = row else { return nil }
            return mailboxItem.itemID
        })
        viewModel.removeDeletedIDFromSelectedItem(existingIDs: existingIDs)
    }

    // When current messages/ conversations are moved or deleted, need to fetch older data
    private func fetchOlderMessageWhenNeeded(remappedSnapshot: NSDiffableDataSourceSnapshot<Int, MailboxRow>) {
        DispatchQueue.main.async {
            defer { self.previousMessageCount = remappedSnapshot.numberOfItems }
            let indexPath = IndexPath(row: self.viewModel.rowCount(section: 0) - 1, section: 0)
            guard
                let previousMessageCount = self.previousMessageCount,
                previousMessageCount != 0,
                remappedSnapshot.numberOfItems == 0,
                !self.viewModel.isLoggingOut,
                let item = self.viewModel.mailboxItem(at: indexPath),
                let date = item.time(labelID: self.viewModel.labelID)
            else { return }
            guard !self.fetchingOlder else {
                self.showNoResultLabelIfNeeded()
                return
            }
            self.tableView.showLoadingFooter()
            self.viewModel.fetchMessages(
                time: Int(date.timeIntervalSince1970),
                isUnread: self.isShowingUnreadMessageOnly
            ) { error in
                DispatchQueue.main.async {
                    self.tableView.hideLoadingFooter()
                    if let error = error {
                        self.handleRequestError(error as NSError)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showNoResultLabelIfNeeded()
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension MailboxViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.headerBanner != nil {
            return UITableView.automaticDimension
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        bannerHeaderView()
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if viewModel.labelID == LabelLocation.scheduled.labelID {
            // 1. The limitation of scheduled messages is 100
            // The API maximum return is 100
            // Scheduled send doesn't need to load more
            // 2. For inbox folder, time order is now, now - 1, ..., now - n
            // For schedule folder, time order is now, now + 1, ..., now + n
            // In scheduled folder, the different time order calls load more API by every scroll
            return
        }
        if let updateTime = viewModel.lastUpdateTime(), let currentTime = viewModel.getTimeOfItem(at: indexPath) {

            let endTime = self.isShowingUnreadMessageOnly ? updateTime.unreadEndTime : updateTime.endTime
            let totalMessage = self.isShowingUnreadMessageOnly ? Int(updateTime.unread) : Int(updateTime.total)
            let isNew = self.isShowingUnreadMessageOnly ? updateTime.isUnreadNew : updateTime.isNew

            let isOlderMessage = endTime.compare(currentTime) == ComparisonResult.orderedDescending
            let loadMore = self.viewModel.loadMore(index: indexPath)
            if  (isOlderMessage || loadMore) && !self.fetchingOlder && !isSwipingCell {
                let sectionCount = self.viewModel.rowCount(section: indexPath.section)
                let recordedCount = totalMessage
                // here need add a counter to check if tried too many times make one real call in case count not right
                if isNew || recordedCount > sectionCount {
                    guard connectionStatusProvider.status.isConnected else {
                        return
                    }
                    self.fetchingOlder = true
                    if !refreshControl.isRefreshing {
                        self.tableView.showLoadingFooter()
                    }
                    let unixTimt: Int = (endTime == Date.distantPast ) ? 0 : Int(endTime.timeIntervalSince1970)
                    self.viewModel.fetchMessages(
                        time: unixTimt,
                        isUnread: self.isShowingUnreadMessageOnly
                    ) { error in
                        DispatchQueue.main.async {
                            self.tableView.hideLoadingFooter()
                            if let error = error {
                                self.handleRequestError(error as NSError)
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.showNoResultLabelIfNeeded()
                        }
                        self.fetchingOlder = false
                    }
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

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        hapticFeedbackGenerator.prepare()
        return indexPath
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
        if viewModel.listEditing {
            handleEditingDataSelection(of: message.messageID.rawValue, indexPath: indexPath)
        } else {
            self.tapped(at: indexPath)
        }
    }

    private func handleConversationSelection(indexPath: IndexPath) {
        guard let conversation = viewModel.itemOfConversation(index: indexPath) else { return }
        if viewModel.listEditing {
            handleEditingDataSelection(of: conversation.conversationID.rawValue, indexPath: indexPath)
        } else {
            self.coordinator?.go(to: .details, sender: nil)
        }
    }

    private func handleEditingDataSelection(of id: String, indexPath: IndexPath) {
        let itemAlreadySelected = viewModel.selectionContains(id: id)
        if itemAlreadySelected {
            viewModel.removeSelected(id: id)
        } else {
            let isAllowed = viewModel.select(id: id)
            guard isAllowed else { return }
        }

        hapticFeedbackGenerator.impactOccurred()

        // update checkbox state
        if let mailboxCell = tableView.cellForRow(at: indexPath) as? NewMailboxMessageCell {
            messageCellPresenter.presentSelectionStyle(
                style: .selection(isSelected: !itemAlreadySelected, isAbleToBeSelected: viewModel.canSelectMore()),
                in: mailboxCell.customView
            )
        }

        tableView.deselectRow(at: indexPath, animated: true)
        setupNavigationTitle(showSelected: true)

        if viewModel.selectedIDs.isEmpty {
            hideSelectionMode()
        } else {
            PMBanner.dismissAll(on: self)
            refreshActionBarItems()
            showActionBar()
        }
    }
}

extension MailboxViewController: NewMailboxMessageCellDelegate {

    func didSelectButtonStatusChange(cell: NewMailboxMessageCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        if !viewModel.listEditing {
            self.enterListEditingMode(indexPath: indexPath)
            updateNavigationController(viewModel.listEditing)
        } else {
            tableView(self.tableView, didSelectRowAt: indexPath)
        }
    }

    func didSelectAttachment(cell: NewMailboxMessageCell, index: Int) {
        guard !viewModel.listEditing else { return }
        guard let indexPath = tableView.indexPath(for: cell) else {
            PMAssertionFailure("IndexPath should match MailboxItem")
            return
        }
        showAttachmentPreviewBanner(at: indexPath, index: index)
    }
}

extension MailboxViewController {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if refreshControl.isRefreshing {
            self.pullDown()
        }
    }

    private func configureUnreadFilterButton() {
        self.unreadFilterButton.titleLabel?.set(text: nil,
                                                preferredFont: .footnote,
                                                weight: .semibold)
        self.unreadFilterButton.setTitleColor(ColorProvider.BrandNorm, for: .normal)
        self.unreadFilterButton.setTitleColor(ColorProvider.TextInverted, for: .selected)
        // Use local icon to prevent UI glitch
        self.unreadFilterButton.setImage(Asset.mailLabelCrossIcon.image, for: .selected)
        self.unreadFilterButton.semanticContentAttribute = .forceRightToLeft
        self.unreadFilterButton.titleLabel?.isSkeletonable = true
        self.unreadFilterButton.translatesAutoresizingMaskIntoConstraints = false
        self.unreadFilterButton.layer.cornerRadius = self.unreadFilterButton.frame.height / 2
        self.unreadFilterButton.layer.masksToBounds = true
        self.unreadFilterButton.backgroundColor = ColorProvider.BackgroundSecondary
        self.unreadFilterButton.isSelected = viewModel.isCurrentUserSelectedUnreadFilterInInbox
        self.unreadFilterButton.imageView?.tintColor = ColorProvider.IconInverted
        self.unreadFilterButton.imageView?.contentMode = .scaleAspectFit
        self.unreadFilterButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        self.unreadFilterButton.addTarget(
            self,
            action: #selector(self.unreadMessageFilterButtonTapped),
            for: .touchUpInside
        )
    }

    private func configureSelectAllButton() {
        selectAllIcon.tintColor = ColorProvider.IconAccent
        // TODO use ImageProvider when core library contains this image
        selectAllIcon.image = Asset.icSquare.image
        selectAllLabel.set(text: L10n.MailBox.selectAll, preferredFont: .subheadline, textColor: ColorProvider.TextAccent)

        selectAllButton.roundCorner(12)
        selectAllButton.backgroundColor = .clear

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapSelectAllButton))
        selectAllButton.addGestureRecognizer(tapGesture)
    }
}

extension MailboxViewController: EventsConsumer {
    func shouldCallFetchEvents() {
        viewModel.deleteExpiredMessages()
        updateScheduledMessageTimeLabel()
        guard self.hasNetworking, !self.viewModel.isFetchingMessage else { return }
        getLatestMessages()
    }
}

extension MailboxViewController: SwipyCellDelegate {
    func swipyCellDidStartSwiping(_ cell: SwipyCell) {
        isSwipingCell = true
        tableView.visibleCells.filter({ $0 != cell }).forEach { cell in
            if let swipyCell = cell as? SwipyCell {
                swipyCell.gestureRecognizers?.compactMap({ $0 as? UIPanGestureRecognizer }).forEach({ $0.isEnabled = false })
            }
        }

        hapticFeedbackGenerator.prepare()
    }

    func swipyCellDidFinishSwiping(_ cell: SwipyCell, atState state: SwipyCellState, triggerActivated activated: Bool) {
        tableView.visibleCells.forEach { cell in
            if let swipyCell = cell as? SwipyCell {
                swipyCell.gestureRecognizers?.compactMap({ $0 as? UIPanGestureRecognizer }).forEach({ $0.isEnabled = true })
            }
        }

        guard let mailboxCell = cell as? NewMailboxMessageCell, let mailboxItem = mailboxCell.mailboxItem else {
            assertionFailure("Invalid cell configuration")
            isSwipingCell = false
            return
        }

        delay(0.25) {
            if activated {
                let action: MessageSwipeAction?

                switch state {
                case .none:
                    action = nil
                case .state(_, let direction):
                    action = mailboxCell.swipeActions[direction]
                }

                if let action = action {
                    self.handleSwipeAction(on: cell, action: action, item: mailboxItem)
                }
            }

            self.isSwipingCell = false
        }
    }

    func swipyCell(_ cell: SwipyCell, didSwipeWithPercentage percentage: CGFloat, currentState state: SwipyCellState, triggerActivated activated: Bool) {
        viewModel.swipyCellDidSwipe(triggerActivated: activated)
    }
}

// MARK: System changes

extension MailboxViewController {

    @objc
    private func timeZoneDidChange() {
        reloadTableViewDataSource(forceReload: true)
    }
}

// MARK: Data Source Refresh
extension MailboxViewController {
    private func reloadTableViewDataSource(
        snapshot: NSDiffableDataSourceSnapshot<Int, MailboxRow>? = nil,
        forceReload: Bool = false,
        completion: (() -> Void)? = nil
    ) {
        viewModel.diffableDataSource?.reloadSnapshot(
            snapshot: snapshot,
            forceReload: forceReload,
            completion: { [weak self] in
                DispatchQueue.main.async {
                    if let view = self?.tableView.subviews
                        .first(where: { $0 is AutoDeleteInfoHeaderView }) as? AutoDeleteInfoHeaderView {
                        let count = self?.viewModel.rowCount(section: 0) ?? 0
                        view.toggleEmptyButton(shouldEnable: count > 0)
                    }
                }
                completion?()
            }
        )
    }
}

// MARK: - Auto-Delete Banners

extension MailboxViewController {
    func bannerHeaderView() -> UIView? {
        switch viewModel.headerBanner {
        case .upsellBanner:
            let headerView = AutoDeleteUpsellHeaderView()
            headerView.learnMoreButtonAction = { [weak self] in
                guard let self else { return }
                presentUpsellPage(entryPoint: .autoDelete) { [weak self] in
                    self?.reloadTableViewDataSource(forceReload: true)
                }
            }
            return headerView
        case .promptBanner:
            let promptBanner = AutoDeletePromptHeaderView()
            promptBanner.enableButtonAction = { [weak self] in
                guard let self else { return }
                let alert = self.viewModel.alertToConfirmEnabling { [weak self] error in
                    if let error {
                        PMAssertionFailure(error)
                    } else {
                        self?.viewModel.user.isAutoDeleteEnabled = true
                        self?.tableView.reloadData()
                    }
                }
                self.present(alert, animated: true)
            }
            promptBanner.noThanksButtonAction = { [weak self] in
                guard let self else { return }
                self.viewModel.updateAutoDeleteSetting(to: false, 
                                                       for: self.viewModel.user,
                                                       completion: { [weak self] error in
                    if let error {
                        PMAssertionFailure(error)
                    } else {
                        self?.viewModel.user.isAutoDeleteEnabled = false
                        self?.tableView.reloadData()
                    }
                })
            }
            return promptBanner
        case .infoBanner(.spam):
            let infoBanner = AutoDeleteSpamInfoHeaderView()
            infoBanner.emptyButtonAction = { [weak self] in
                self?.clickEmptyFolderAction()
            }
            let count = self.viewModel.sectionCount() > 0 ? self.viewModel.rowCount(section: 0) : 0
            infoBanner.toggleEmptyButton(shouldEnable: count > 0)
            return infoBanner
        case .infoBanner(.trash):
            let infoBanner = AutoDeleteTrashInfoHeaderView()
            infoBanner.emptyButtonAction = { [weak self] in
                self?.clickEmptyFolderAction()
            }
            let count = self.viewModel.sectionCount() > 0 ? self.viewModel.rowCount(section: 0) : 0
            infoBanner.toggleEmptyButton(shouldEnable: count > 0)
            return infoBanner
        case .none:
            return nil
        }
    }
}

extension MailboxViewController: UndoActionHandlerBase {
    var undoActionManager: UndoActionManagerProtocol? {
        viewModel.user.undoActionManager
    }

    var delaySendSeconds: Int {
        self.viewModel.user.userInfo.delaySendSeconds
    }

    var composerPresentingVC: UIViewController? {
        self
    }
}

// MARK: - ConnectionStatusReceiver
extension MailboxViewController: ConnectionStatusReceiver {
    func connectionStatusHasChanged(newStatus: ConnectionStatus) {
        updateInterface(connectionStatus: newStatus)
    }
}

extension MailboxViewController: MailboxViewModelUIProtocol {
    var isUsingDefaultSizeCategory: Bool {
        view.traitCollection.preferredContentSizeCategory == .large
    }

    func updateTitle() {
        setupNavigationTitle(showSelected: viewModel.listEditing)
    }

    func updateUnreadButton(count: Int) {
        let unread = count
        let isInUnreadFilter = unreadFilterButton.isSelected
        let shouldShowUnreadFilter = unread != 0
        unreadFilterButton.backgroundColor = isInUnreadFilter ? ColorProvider.BrandNorm : ColorProvider.BackgroundSecondary
        if viewModel.listEditing {
            unreadFilterButton.isHidden = true
        } else {
            unreadFilterButton.isHidden = isInUnreadFilter ? false : unread == 0
        }
        customUnreadFilterElement?.isAccessibilityElement = shouldShowUnreadFilter
        let number = unread > 9999 ? " +9999" : "\(unread)"

        if isInUnreadFilter {
            unreadFilterButton.setTitle("\(number) \(LocalString._unread_action) ", for: .selected)
        } else {
            unreadFilterButton.setTitle("\(number) \(LocalString._unread_action) ", for: .normal)
        }
        customUnreadFilterElement?.accessibilityLabel = "\(number) \(LocalString._unread_action)"

        let titleWidth = unreadFilterButton.titleLabel?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width ?? 0.0
        let width = titleWidth + 16 + (isInUnreadFilter ? 16 : 0)
        unreadFilterButtonWidth.constant = width
        self.unreadFilterButton.layer.cornerRadius = self.unreadFilterButton.frame.height / 2
    }

    func selectionDidChange() {
        guard viewModel.listEditing else { return }
        updateSelectAllButton()
        updateCellBasedOnSelectionStatus()

        if !viewModel.canSelectMore() {
            L10n.MailBox.maximumSelectionReached.alertToastBottom()
        }
    }

    @MainActor
    func clickSnoozeActionButton() {
        coordinator?.presentSnoozeConfigSheet(on: self, current: Date())
    }
}

extension MailboxViewController: ComposeContainerViewControllerDelegate {
    func composerVillDismiss() {
        getLatestMessages()
    }
}

extension MailboxViewController {
    private func displayReminderModalIfNeeded(subscription: CurrentPlan.Subscription) {
        guard viewModel.shouldShowReminderModal(),
              let planName = subscription.name,
              let periodEnd = subscription.periodEnd else { return }
        let endSubscriptionDate = Date(timeIntervalSince1970: TimeInterval(periodEnd))
        if let planUpsellModel = PlanUpsell(planName: planName) {
            let reminderView = ReminderView(periodEnd: endSubscriptionDate.formatLongDate(), perks: planUpsellModel.perks, markAsSeen: viewModel.markRemindersAsSeen, reactivateSubscription: viewModel.reactivateSubscription(completion:), displayReactivationBanner: displayReactivationBanner(error:))
            let hostVC = SheetLikeSpotlightViewController(rootView: reminderView)
            navigationController?.present(hostVC, animated: false)
        }
    }
    
    private func displayReactivationBanner(error: Error?) {
        let banner = PMBanner(
            message: error == nil ? L10n.ReminderModal.successMessage : L10n.ReminderModal.errorMessage,
            style: error == nil ? PMBannerNewStyle.info : PMBannerNewStyle.error,
            bannerHandler: PMBanner.dismiss
        )
        banner.show(at: .bottom, on: self, ignoreKeyboard: true)
    }
}

