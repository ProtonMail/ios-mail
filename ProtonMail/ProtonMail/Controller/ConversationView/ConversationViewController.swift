import MBProgressHUD
import ProtonCore_UIFoundations
import UIKit

class ConversationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
                                  UIScrollViewDelegate, ComposeSaveHintProtocol {

    let viewModel: ConversationViewModel
    let coordinator: ConversationCoordinatorProtocol
    private let applicationStateProvider: ApplicationStateProvider
    private(set) lazy var customView = ConversationView()
    private var selectedMessageID: MessageID?
    private let conversationNavigationViewPresenter = ConversationNavigationViewPresenter()
    private let conversationMessageCellPresenter = ConversationMessageCellPresenter()
    private let actionSheetPresenter = MessageViewActionSheetPresenter()
    private lazy var starBarButton = UIBarButtonItem.plain(target: self, action: #selector(starButtonTapped))
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()
    private let storedSizeHelper = ConversationStoredSizeHelper()
    private var cachedViewControllers: [IndexPath: ConversationExpandedMessageViewController] = [:]
    private(set) var shouldReloadWhenAppIsActive = false

    init(coordinator: ConversationCoordinatorProtocol,
         viewModel: ConversationViewModel,
         applicationStateProvider: ApplicationStateProvider = UIApplication.shared) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        self.applicationStateProvider = applicationStateProvider
        super.init(nibName: nil, bundle: nil)
        self.viewModel.conversationViewController = self
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpNavigationBar()
        setUpTableView()

        starButtonSetUp(starred: viewModel.conversation.starred)

        setupViewModel()

        conversationNavigationViewPresenter.present(viewType: viewModel.simpleNavigationViewType, in: navigationItem)
        customView.separator.isHidden = true

        viewModel.fetchConversationDetails(completion: ) { [weak self] in
            self?.viewModel.isInitialDataFetchCalled = true
            delay(0.5) { // wait a bit for the UI to update
                self?.viewModel.messagesDataSource
                    .compactMap {
                        $0.messageViewModel?.state.expandedViewModel?.messageContent
                    }.forEach { model in
                        if model.message.unRead {
                            self?.viewModel.messageIDsOfMarkedAsRead.append(model.message.messageID)
                        }
                        model.markReadIfNeeded()
                    }
                self?.displayConversationNoticeIfNeeded()
            }
        }

        viewModel.observeConversationUpdate()

        if !ProcessInfo.isRunningUnitTests {
            viewModel.observeConversationMessages(tableView: customView.tableView)
        }
        setUpToolBar()

        registerNotification()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.user.undoActionManager.register(handler: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !customView.tableView.visibleCells.isEmpty,
              !viewModel.isExpandedAtLaunch else { return }

        if viewModel.firstExpandedMessageIndex != nil {
            viewModel.setCellIsExpandedAtLaunch()
        } else if let targetID = self.viewModel.targetID {
            self.cellTapped(messageId: targetID)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.dismissActionSheet()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return viewModel.headerSectionDataSource.count
        case 1:
            return viewModel.messagesDataSource.count
        default:
            fatalError("Not supported section")
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        height(for: indexPath, estimated: false)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        height(for: indexPath, estimated: true)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let itemType = indexPath.section == 0 ?
            viewModel.headerSectionDataSource[indexPath.row] :
            viewModel.messagesDataSource[indexPath.row]
        switch itemType {
        case .trashedHint:
            let cell = tableView.dequeue(cellType: ConversationViewTrashedHintCell.self)
            cell.setup(isTrashFolder: self.viewModel.isTrashFolder,
                       useShowButton: self.viewModel.shouldTrashedHintBannerUseShowButton(),
                       delegate: self.viewModel)
            return cell
        case .header(let subject):
            return headerCell(tableView, indexPath: indexPath, subject: subject)
        case .message(let viewModel):
            if viewModel.isTrashed && self.viewModel.displayRule == .showNonTrashedOnly {
                return tableView.dequeue(cellType: UITableViewCell.self)
            } else if !viewModel.isTrashed && self.viewModel.displayRule == .showTrashedOnly {
                return tableView.dequeue(cellType: UITableViewCell.self)
            }
            return messageCell(tableView, indexPath: indexPath, viewModel: viewModel)
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let conversationExpandedMessageCell = cell as? ConversationExpandedMessageCell,
              let view = cell.contentView.subviews.first else { return }
        let viewController = children
            .compactMap { $0 as? ConversationExpandedMessageViewController }
            .first { $0.viewModel.message.messageID == conversationExpandedMessageCell.messageId &&
                $0.view == view
            }
        guard let controllerToUnembed = viewController else { return }
        cachedViewControllers[indexPath] = nil
        unembed(controllerToUnembed)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        viewModel.scrollViewDidScroll()

        self.checkNavigationTitle()
    }

    private func leaveFocusedMode() {
        // the idea is to keep the expanded cell in exactly the same spot after expansion
        // to ensure that, we add the difference in content size to the offset

        let contentHeightBeforeExpansion = customView.tableView.contentSize.height

        customView.tableView.reloadData()

        let contentHeightAfterExpansion = customView.tableView.contentSize.height
        let previouslyHiddenContentHeight = contentHeightAfterExpansion - contentHeightBeforeExpansion

        DispatchQueue.main.async {
            self.customView.tableView.contentOffset.y += previouslyHiddenContentHeight
        }
    }

    func attemptAutoScroll(to indexPath: IndexPath, position: UITableView.ScrollPosition) {
        if self.customView.tableView.indexPathExists(indexPath) {
            self.customView.tableView.scrollToRow(at: indexPath, at: position, animated: true)
        }
    }

    func cellTapped(messageId: MessageID) {
        guard let index = self.viewModel.messagesDataSource
                .firstIndex(where: { $0.message?.messageID == messageId }),
              let messageViewModel = self.viewModel.messagesDataSource[safe: index]?.messageViewModel else {
            return
        }

        if messageViewModel.isDraft {
            self.update(draft: messageViewModel.message)
        } else {
            let indexPath = IndexPath(row: index, section: 1)
            cachedViewControllers[indexPath] = nil
            messageViewModel.toggleState()
            customView.tableView.reloadRows(at: [.init(row: index, section: 1)], with: .automatic)
            checkNavigationTitle()
            messageViewModel.state.expandedViewModel?.messageContent.markReadIfNeeded()
        }
    }

    @objc
    private func tapBackButton() {
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func starButtonTapped() {
        viewModel.starTapped { [weak self] result in
            if let shouldStar = try? result.get() {
                self?.starButtonSetUp(starred: shouldStar)
            }
        }
    }

    private func starButtonSetUp(starred: Bool) {
        starBarButton.image = starred ?
            Asset.messageDeatilsStarActive.image : Asset.messageDetailsStarInactive.image
        starBarButton.tintColor = starred ? ColorProvider.NotificationWarning : ColorProvider.IconWeak
    }

    private func setUpNavigationBar() {
        navigationItem.backButtonTitle = .empty
        navigationItem.rightBarButtonItem = starBarButton
        let backButtonItem = UIBarButtonItem.backBarButtonItem(target: self, action: #selector(tapBackButton))
        navigationItem.backBarButtonItem = backButtonItem

        // Accessibility
        navigationItem.backBarButtonItem?.accessibilityLabel = LocalString._general_back_action
        starBarButton.isAccessibilityElement = true
        starBarButton.accessibilityLabel = LocalString._star_btn_in_message_view
    }

    private func setUpTableView() {
        customView.tableView.dataSource = self
        customView.tableView.delegate = self
        customView.tableView.register(cellType: ConversationViewHeaderCell.self)
        customView.tableView.register(cellType: ConversationMessageCell.self)
        customView.tableView.register(cellType: ConversationExpandedMessageCell.self)
        customView.tableView.register(cellType: UITableViewCell.self)
        customView.tableView.register(cellType: ConversationViewTrashedHintCell.self)
    }

    private func registerNotification() {
        if #available(iOS 13.0, *) {
            NotificationCenter.default
                .addObserver(self,
                             selector: #selector(willBecomeActive),
                             name: UIScene.willEnterForegroundNotification,
                             object: nil)
        } else {
            NotificationCenter.default
                .addObserver(self,
                             selector: #selector(willBecomeActive),
                             name: UIApplication.willEnterForegroundNotification,
                             object: nil)
        }
    }

    private func setupViewModel() {
        viewModel.refreshView = { [weak self] in
            guard let self = self else { return }
            self.refreshNavigationViewIfNeeded()
            self.starButtonSetUp(starred: self.viewModel.conversation.starred)
            let isNewMessageFloatyPresented = self.customView.subviews
                .contains(where: { $0 is ConversationNewMessageFloatyView })
            guard !isNewMessageFloatyPresented else { return }

            // Prevent the banner being covered by the action bar
            self.view.subviews.compactMap({ $0 as? PMBanner }).forEach({ self.view.bringSubviewToFront($0) })
        }

        viewModel.dismissView = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }

        viewModel.reloadRows = { [weak self] rows in
            DispatchQueue.main.async {
                self?.customView.tableView.reloadRows(at: rows, with: .automatic)
                self?.checkNavigationTitle()
            }
        }

        viewModel.leaveFocusedMode = { [weak self] in
            self?.leaveFocusedMode()
        }

        viewModel.dismissDeletedMessageActionSheet = { [weak self] messageID in
            guard messageID == self?.selectedMessageID else { return }
            self?.dismissActionSheet()
        }

        viewModel.showNewMessageArrivedFloaty = { [weak self] messageId in
            self?.showNewMessageFloatyView(messageId: messageId)
        }

        viewModel.startMonitorConnectionStatus { [weak self] in
            return self?.applicationStateProvider.applicationState == .active
        } reloadWhenAppIsActive: { [weak self] value in
            self?.shouldReloadWhenAppIsActive = value
        }

        viewModel.viewModeIsChanged = { [weak self] _ in
            self?.viewModel.messagesDataSource
                .compactMap {
                    $0.messageViewModel?.state.expandedViewModel?.messageContent
                }.filter {
                    self?.viewModel.messageIDsOfMarkedAsRead.contains($0.message.messageID) ?? false
                }.forEach {
                    $0.markUnreadIfNeeded()
                }

            self?.navigationController?.popViewController(animated: true)
        }
    }

    @objc
    private func willBecomeActive(_ notification: Notification) {
        if shouldReloadWhenAppIsActive {
            viewModel.fetchConversationDetails(completion: nil)
            shouldReloadWhenAppIsActive = false
        }
    }

    required init?(coder: NSCoder) { nil }
}

private extension ConversationViewController {
    private func presentActionSheet(for message: MessageEntity,
                                    isBodyDecrpytable: Bool,
                                    messageRenderStyle: MessageRenderStyle,
                                    shouldShowRenderModeOption: Bool) {
        let forbidden = [Message.Location.allmail.rawValue,
                          Message.Location.starred.rawValue,
                          Message.HiddenLocation.sent.rawValue,
                          Message.HiddenLocation.draft.rawValue]
        // swiftlint:disable sorted_first_last
        // Better to disable linter rule here keep it this way for readability
        guard let location = message.labels
                .sorted(by: { label1, label2 in
                    return label1.labelID.rawValue < label2.labelID.rawValue
                })
                .first(where: {
                    !forbidden.contains($0.labelID.rawValue)
                    && ($0.type == .folder || Int($0.labelID.rawValue) != nil)
                }) else { return }
        // swiftlint:enable sorted_first_last
        self.selectedMessageID = message.messageID
        let viewModel = MessageViewActionSheetViewModel(title: message.title,
                                                        labelID: location.labelID,
                                                        includeStarring: true,
                                                        isStarred: message.isStarred,
                                                        isBodyDecryptable: isBodyDecrpytable,
                                                        hasMoreThanOneRecipient: message.isHavingMoreThanOneContact,
                                                        messageRenderStyle: messageRenderStyle,
                                                        shouldShowRenderModeOption: shouldShowRenderModeOption)
        actionSheetPresenter.present(on: navigationController ?? self,
                                     listener: self,
                                     viewModel: viewModel) { [weak self] in
            self?.handleActionSheetAction($0, message: message)
        }
    }

    private func countHeightFor(viewType: ConversationViewItemType, estimated: Bool) -> CGFloat {
        guard let viewModel = viewType.messageViewModel else {
            return UITableView.automaticDimension
        }

        if viewModel.isTrashed && self.viewModel.displayRule == .showNonTrashedOnly {
            return 0
        } else if !viewModel.isTrashed && self.viewModel.displayRule == .showTrashedOnly {
            return 0
        }
        let isMessageExpanded = viewModel.state.isExpanded
        if !isMessageExpanded {
            // For smooth animation
            return 56
        }

        guard let storedHeightInfo = storedSizeHelper.getStoredSize(of: viewModel.message.messageID) else {
            return UITableView.automaticDimension
        }

        if estimated {
            return storedHeightInfo.height
        }
        return UITableView.automaticDimension
    }

    private func height(for indexPath: IndexPath, estimated: Bool) -> CGFloat {
        switch indexPath.section {
        case 0:
            guard headerShouldBeVisible(at: indexPath.row) else {
                return 0
            }

            return UITableView.automaticDimension
        case 1:
            guard messageShouldBeVisible(at: indexPath.row) else {
                return 0
            }

            guard let viewType = self.viewModel.messagesDataSource[safe: indexPath.row] else {
                return UITableView.automaticDimension
            }

            return countHeightFor(viewType: viewType, estimated: estimated)
        default:
            fatalError("Not supported section")
        }
    }

    private func headerShouldBeVisible(at index: Int) -> Bool {
        switch self.viewModel.headerSectionDataSource[index] {
        case .trashedHint:
            return !viewModel.focusedMode
        default:
            return true
        }
    }

    private func messageShouldBeVisible(at index: Int) -> Bool {
        guard viewModel.focusedMode, let firstExpandedMessageIndex = viewModel.firstExpandedMessageIndex else {
            return true
        }

        return index >= firstExpandedMessageIndex
    }

    private func headerCell(
        _ tableView: UITableView,
        indexPath: IndexPath,
        subject: String
    ) -> UITableViewCell {
        let cell = tableView.dequeue(cellType: ConversationViewHeaderCell.self)
        let style = FontManager.MessageHeader.alignment(.center)
        cell.customView.titleTextView.attributedText = subject.apply(style: style)
        return cell
    }

    private func messageCell(
        _ tableView: UITableView,
        indexPath: IndexPath,
        viewModel: ConversationMessageViewModel
    ) -> UITableViewCell {
        switch viewModel.state {
        case .collapsed(let collapsedViewModel):
            let cell = tableView.dequeue(cellType: ConversationMessageCell.self)
            cell.customView.tapAction = { [weak self] in
                self?.cellTapped(messageId: viewModel.message.messageID)
            }
            collapsedViewModel.reloadView = { [conversationMessageCellPresenter] model in
                conversationMessageCellPresenter.present(model: model, in: cell.customView)
            }
            cell.cellReuse = { [weak collapsedViewModel] in
                collapsedViewModel?.reloadView = nil
            }
            conversationMessageCellPresenter.present(model: collapsedViewModel.model, in: cell.customView)
            return cell
        case .expanded(let expandedViewModel):
            let cell = tableView.dequeue(cellType: ConversationExpandedMessageCell.self)
            let viewController: ConversationExpandedMessageViewController
            if let cachedViewController = cachedViewControllers[indexPath] {
                viewController = cachedViewController
            } else {
                viewController = embedController(viewModel: expandedViewModel, in: cell, indexPath: indexPath)
                cachedViewControllers[indexPath] = viewController
            }
            embed(viewController, inside: cell.container)
            viewController.customView.topArrowTapAction = { [weak self] in
                self?.cellTapped(messageId: viewModel.message.messageID)
            }

            cell.messageId = viewModel.message.messageID

            return cell
        }
    }

    private func embedController(
        viewModel: ConversationExpandedMessageViewModel,
        in cell: ConversationExpandedMessageCell,
        indexPath: IndexPath
    ) -> ConversationExpandedMessageViewController {
        cell.container.subviews.forEach { $0.removeFromSuperview() }
        let contentViewModel = viewModel.messageContent
        let singleMessageContentViewController = SingleMessageContentViewController(
            viewModel: contentViewModel,
            parentScrollView: customView.tableView,
            viewMode: .conversation,
            navigationAction: { [weak self] in self?.handleSingleMessageAction(action: $0) }
        )

        let viewController = ConversationExpandedMessageViewController(
            viewModel: .init(message: viewModel.message, messageContent: contentViewModel),
            singleMessageContentViewController: singleMessageContentViewController
        )

        viewModel.recalculateCellHeight = { [weak self] isLoaded in
            self?.recalculateHeight(
                for: cell,
                messageId: viewModel.message.messageID,
                isHeaderExpanded: viewModel.messageContent.isExpanded,
                isLoaded: isLoaded
            )
        }

        viewModel.resetLoadedHeight = { [weak self] in
            self?.storedSizeHelper.resetStoredSize(of: viewModel.message.messageID)
        }

        return viewController
    }

    private func recalculateHeight(
        for cell: ConversationExpandedMessageCell,
        messageId: MessageID,
        isHeaderExpanded: Bool,
        isLoaded: Bool
    ) {
        let height = cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        let newHeightInfo = HeightStoreInfo(height: height,
                                            isHeaderExpanded: isHeaderExpanded,
                                            loaded: isLoaded)
        if storedSizeHelper
            .updateStoredSizeIfNeeded(newHeightInfo: newHeightInfo, messageID: messageId) {
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
            UIView.setAnimationsEnabled(false)
            customView.tableView.beginUpdates()
            customView.tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        }
    }

    private func checkNavigationTitle() {
        let tableview = customView.tableView
        guard let cell = tableview.visibleCells.compactMap({ $0 as? ConversationViewHeaderCell }).first else {
            presentDetailedNavigationTitle()
            customView.separator.isHidden = false
            return
        }

        let headerLabelConvertedFrame = cell.convert(cell.customView.titleTextView.frame, to: customView.tableView)
        let shouldPresentDetailedNavigationTitle = tableview.contentOffset.y >= headerLabelConvertedFrame.maxY
        shouldPresentDetailedNavigationTitle ? presentDetailedNavigationTitle() : presentSimpleNavigationTitle()

        let separatorConvertedFrame = cell.convert(cell.customView.separator.frame, to: customView.tableView)
        let shouldShowSeparator = customView.tableView.contentOffset.y >= separatorConvertedFrame.maxY
        customView.separator.isHidden = !shouldShowSeparator

        cell.customView.topSpace = tableview.contentOffset.y < 0 ? tableview.contentOffset.y : 0
    }

    private func presentDetailedNavigationTitle() {
        conversationNavigationViewPresenter.present(viewType: viewModel.detailedNavigationViewType, in: navigationItem)
    }

    private func presentSimpleNavigationTitle() {
        conversationNavigationViewPresenter.present(viewType: viewModel.simpleNavigationViewType, in: navigationItem)
    }

    private func refreshNavigationViewIfNeeded() {
        // only reassign the titleView if needed
        if let titleView = navigationItem.titleView as? ConversationNavigationSimpleView {
            if titleView.titleLabel.attributedText?.string != viewModel.messagesTitle {
                navigationItem.titleView = viewModel.simpleNavigationViewType.titleView
            }
        } else if let titleView = navigationItem.titleView as? ConversationNavigationDetailView {
            if titleView.topLabel.attributedText?.string != viewModel.messagesTitle ||
                titleView.bottomLabel.attributedText?.string != viewModel.conversation.subject {
                navigationItem.titleView = viewModel.detailedNavigationViewType.titleView
            }
        }
    }

    private func update(draft: MessageEntity) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        guard !draft.isSending else {
            LocalString._mailbox_draft_is_uploading.alertToast()
            MBProgressHUD.hide(for: self.view, animated: true)
            return
        }
        self.viewModel.messageService
            .ForcefetchDetailForMessage(draft, runInQueue: false) { [weak self] _, _, container, error in
                guard let self = self else { return }
                if error != nil {
                    let alert = LocalString._unable_to_edit_offline.alertController()
                    alert.addOKAction()
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                guard let objectID = container?.objectID.rawValue else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    return
                }
                // The fetch API is saved on operationContext
                // But the fetchController is working on mainContext
                // It take sometime to sync data
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    guard let message = self.viewModel.message(by: objectID),
                          !message.body.isEmpty else { return }
                    timer.invalidate()
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.coordinator.handle(navigationAction: .draft(message: message))
                }
            }
    }

    private func displayConversationNoticeIfNeeded() {
        guard viewModel.shouldDisplayConversationNoticeView else {
            return
        }
        viewModel.conversationNoticeViewIsOpened()
        let view = ConversationViewNoticeView()
        view.presentAt(self.navigationController ?? self,
                       animated: true) {
            let link = DeepLink(String(describing: SettingsDeviceViewController.self))
            link.append(.accountSetting)
            link.append(.conversationMode)
            NotificationCenter.default.post(name: .switchView, object: link)
        }
    }
}

private extension Array where Element == ConversationViewItemType {

    func message(with id: MessageID) -> MessageEntity? {
        compactMap(\.message)
            .first(where: { $0.messageID == id })
    }

}

// MARK: - Tool Bar
private extension ConversationViewController {
    private func setUpToolBar() {
        customView.toolBar.setUpTrashAction(target: self, action: #selector(self.trashAction))
        customView.toolBar.setUpUnreadAction(target: self, action: #selector(self.unreadReadAction))
        customView.toolBar.setUpMoveToAction(target: self, action: #selector(self.moveToAction))
        customView.toolBar.setUpLabelAsAction(target: self, action: #selector(self.labelAsAction))
        customView.toolBar.setUpMoreAction(target: self, action: #selector(self.moreButtonTapped))
        customView.toolBar.setUpDeleteAction(target: self, action: #selector(self.deleteAction))

        if viewModel.labelId == Message.Location.spam.labelID || viewModel.labelId == Message.Location.trash.labelID {
            customView.toolBar.trashButtonView.removeFromSuperview()
        } else {
            customView.toolBar.deleteButtonView.removeFromSuperview()
        }
    }

    @objc
    private func deleteAction() {
        showDeleteAlert(deleteHandler: { [weak self] _ in
            self?.viewModel.handleToolBarAction(.delete)
            self?.navigationController?.popViewController(animated: true)
        })
    }

    @objc
    private func trashAction() {
        viewModel.handleToolBarAction(.trash)
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func unreadReadAction() {
        viewModel.handleToolBarAction(.readUnread)
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func moveToAction() {
        showMoveToActionSheet(dataSource: .conversation)
    }

    @objc
    private func labelAsAction() {
        showLabelAsActionSheet(dataSource: .conversation)
    }

    @objc
    private func moreButtonTapped() {
        guard let navigationVC = self.navigationController else { return }
        let isUnread = viewModel.conversation.isUnread(labelID: viewModel.labelId)
        let isStarred = viewModel.conversation.starred

        let messagesCountInTrash = viewModel.conversation.getNumMessages(labelID: Message.Location.trash.labelID)
        let isAllMessagesInTrash = messagesCountInTrash == viewModel.conversation.messageCount
        let actionSheetViewModel = ConversationActionSheetViewModel(title: viewModel.conversation.subject,
                                                                    labelID: viewModel.labelId,
                                                                    isUnread: isUnread,
                                                                    isStarred: isStarred,
                                                                    isAllMessagesInTrash: isAllMessagesInTrash)
        actionSheetPresenter.present(on: navigationVC,
                                     listener: self,
                                     viewModel: actionSheetViewModel) { [weak self] action in
            self?.handleActionSheetAction(action)
        }
    }

    private func showDeleteAlert(deleteHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: LocalString._warning,
                                      message: LocalString._messages_will_be_removed_irreversibly,
                                      preferredStyle: .alert)
        let yes = UIAlertAction(title: LocalString._general_delete_action, style: .destructive, handler: deleteHandler)
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel)
        [yes, cancel].forEach(alert.addAction)

        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Action Sheet Actions
private extension ConversationViewController {
    func handleActionSheetAction(_ action: MessageViewActionSheetAction) {
        switch action {
        case .reply, .replyAll, .forward:
            handleOpenComposerAction(action)
        case .labelAs:
            showLabelAsActionSheet(dataSource: .conversation)
        case .moveTo:
            showMoveToActionSheet(dataSource: .conversation)
        case .star, .unstar:
            starButtonTapped()
        case .dismiss:
            let actionSheet = navigationController?.view.subviews.compactMap { $0 as? PMActionSheet }.first
            actionSheet?.dismiss(animated: true)
        case .delete:
            showDeleteAlert(deleteHandler: { [weak self] _ in
                self?.viewModel.handleActionSheetAction(action, completion: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
            })
        default:
            viewModel.handleActionSheetAction(action, completion: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
        }
    }

    private func handleOpenComposerAction(_ action: MessageViewActionSheetAction) {
        guard let message = viewModel.messagesDataSource.newestMessage else { return }
        switch action {
        case .reply:
            coordinator.handle(navigationAction: .reply(message: message))
        case .replyAll:
            coordinator.handle(navigationAction: .replyAll(message: message))
        case .forward:
            coordinator.handle(navigationAction: .forward(message: message))
        default:
            return
        }
    }

    private func handleSingleMessageAction(action: SingleMessageNavigationAction) {
        switch action {
        case .reply(let messageId):
            guard let message = viewModel.messagesDataSource.message(with: messageId) else { return }
            coordinator.handle(navigationAction: .reply(message: message))
        case .replyAll(let messageId):
            guard let message = viewModel.messagesDataSource.message(with: messageId) else { return }
            coordinator.handle(navigationAction: .replyAll(message: message))
        case .compose(let contact):
            coordinator.handle(navigationAction: .composeTo(contact: contact))
        case .contacts(let contact):
            coordinator.handle(navigationAction: .addContact(contact: contact))
        case let .attachmentList(messageId, body):
            guard let message = viewModel.messagesDataSource.message(with: messageId) else { return }
            let cids = message.getCIDOfInlineAttachment(decryptedBody: body)
            coordinator.handle(navigationAction: .attachmentList(message: message, inlineCIDs: cids))
        case .more(let messageId):
            if let message = viewModel.messagesDataSource.message(with: messageId) {
                handleMoreAction(messageId: messageId, message: message)
            }
        case .url(let url):
            coordinator.handle(navigationAction: .url(url: url))
        case .inAppSafari(let url):
            coordinator.handle(navigationAction: .inAppSafari(url: url))
        case .mailToUrl(let url):
            coordinator.handle(navigationAction: .mailToUrl(url: url))
        case .forward(let messageId):
            guard let message = viewModel.messagesDataSource.message(with: messageId) else { return }
            coordinator.handle(navigationAction: .forward(message: message))
        case .viewCypher(url: let url):
            coordinator.handle(navigationAction: .viewCypher(url: url))
        default:
            break
        }
    }

    private func handleMoreAction(messageId: MessageID, message: MessageEntity) {
        let viewModel = viewModel.messagesDataSource.first(where: { $0.message?.messageID == messageId })
        let isBodyDecryptable = viewModel?.messageViewModel?.state.expandedViewModel?
            .messageContent.messageBodyViewModel.isBodyDecryptable ?? false
        let bodyViewModel = viewModel?.messageViewModel?.state
            .expandedViewModel?.messageContent
            .messageBodyViewModel
        let renderStyle = bodyViewModel?.currentMessageRenderStyle ?? .dark
        let shouldDisplayRenderModeOptions = bodyViewModel?.shouldDisplayRenderModeOptions ?? false
        presentActionSheet(for: message,
                           isBodyDecrpytable: isBodyDecryptable,
                           messageRenderStyle: renderStyle,
                           shouldShowRenderModeOption: shouldDisplayRenderModeOptions)
    }
}

enum ActionSheetDataSource {
    case message(_ message: MessageEntity)
    case conversation
}

extension ConversationViewController: LabelAsActionSheetPresentProtocol {
    var labelAsActionHandler: LabelAsActionSheetProtocol {
        return viewModel
    }

    private func showLabelAsActionSheetForConversation() {
        let labels = labelAsActionHandler.getLabelMenuItems()
        let convMessages = viewModel.messagesDataSource.compactMap(\.message)
        let labelAsViewModel = LabelAsActionSheetViewModelConversationMessages(menuLabels: labels,
                                                                               conversationMessages: convMessages)

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     listener: self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        guard let self = self else { return }
                        if self.allowToCreateLabels(existingLabels: labelAsViewModel.menuLabels.count) {
                            self.coordinator.pendingActionAfterDismissal = { [weak self] in
                                self?.showLabelAsActionSheetForConversation()
                            }
                            self.coordinator.handle(navigationAction: .addNewLabel)
                        } else {
                            self.showAlertLabelCreationNotAllowed()
                        }
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
                     done: { [weak self] isArchive, currentOptionsStatus  in
                        if let conversation = self?.viewModel.conversation {
                            self?.labelAsActionHandler
                                .handleLabelAsAction(conversations: [conversation],
                                                     shouldArchive: isArchive,
                                                     currentOptionsStatus: currentOptionsStatus,
                                                     completion: nil)
                        }
                        self?.dismissActionSheet()
                     }
            )
    }

    private func showLabelAsActionSheet(for message: MessageEntity) {
        let labelAsViewModel = LabelAsActionSheetViewModelMessages(menuLabels: labelAsActionHandler.getLabelMenuItems(),
                                                                   messages: [message])

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     listener: self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        guard let self = self else { return }
                        if self.allowToCreateLabels(existingLabels: labelAsViewModel.menuLabels.count) {
                            self.coordinator.pendingActionAfterDismissal = { [weak self] in
                                self?.showLabelAsActionSheet(for: message)
                            }
                            self.coordinator.handle(navigationAction: .addNewLabel)
                        } else {
                            self.showAlertLabelCreationNotAllowed()
                        }
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
                     done: { [weak self] isArchive, currentOptionsStatus  in
                        self?.labelAsActionHandler
                            .handleLabelAsAction(messages: [message],
                                                 shouldArchive: isArchive,
                                                 currentOptionsStatus: currentOptionsStatus)
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

    private func allowToCreateFolders(existingFolders: Int) -> Bool {
        let isFreeAccount = viewModel.user.userInfo.subscribed == 0
        if isFreeAccount {
            return existingFolders < Constants.FreePlan.maxNumberOfFolders
        }
        return true
    }

    private func showAlertLabelCreationNotAllowed() {
        let title = LocalString._creating_label_not_allowed
        let message = LocalString._upgrade_to_create_label
        showAlert(title: title, message: message)
    }

    private func showAlertFolderCreationNotAllowed() {
        let title = LocalString._creating_folder_not_allowed
        let message = LocalString._upgrade_to_create_folder
        showAlert(title: title, message: message)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addOKAction()
        self.present(alert, animated: true, completion: nil)
    }

    func showLabelAsActionSheet(dataSource: ActionSheetDataSource) {
        switch dataSource {
        case .conversation:
            showLabelAsActionSheetForConversation()
        case .message(let message):
            showLabelAsActionSheet(for: message)
        }
    }
}

extension ConversationViewController: MoveToActionSheetPresentProtocol {
    var moveToActionHandler: MoveToActionSheetProtocol {
        return viewModel
    }

    func showMoveToActionSheet(dataSource: ActionSheetDataSource) {
        switch dataSource {
        case .conversation:
            showMoveToActionSheetForConversation()
        case .message(let message):
            showMoveToActionSheet(for: message)
        }
    }

    private func showMoveToActionSheet(for message: MessageEntity) {
        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        let moveToViewModel = MoveToActionSheetViewModelMessages(
            menuLabels: viewModel.getFolderMenuItems(),
            messages: [message],
            isEnableColor: isEnableColor,
            isInherit: isInherit
        )

        moveToActionSheetPresenter.present(
            on: self.navigationController ?? self,
            listener: self,
            viewModel: moveToViewModel,
            addNewFolder: { [weak self] in
                guard let self = self else { return }
                if self.allowToCreateFolders(existingFolders: self.viewModel.getCustomFolderMenuItems().count) {
                    self.coordinator.pendingActionAfterDismissal = { [weak self] in
                        self?.showMoveToActionSheet(for: message)
                    }
                    self.coordinator.handle(navigationAction: .addNewFolder)
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
               }
               guard isHavingUnsavedChanges else {
                   return
               }
                self?.moveToActionHandler
                        .handleMoveToAction(messages: [message], isFromSwipeAction: false)
            }
        )
    }

    private func showMoveToActionSheetForConversation() {
        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        let messagesOfConversation = viewModel.messagesDataSource.compactMap({ $0.message })

        let moveToViewModel = MoveToActionSheetViewModelMessages(
            menuLabels: viewModel.getFolderMenuItems(),
            messages: messagesOfConversation,
            isEnableColor: isEnableColor,
            isInherit: isInherit
        )

        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     listener: self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                guard let self = self else { return }
                if self.allowToCreateFolders(existingFolders: self.viewModel.getCustomFolderMenuItems().count) {
                    self.coordinator.pendingActionAfterDismissal = { [weak self] in
                        self?.showMoveToActionSheetForConversation()
                    }
                    self.coordinator.handle(navigationAction: .addNewFolder)
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
                    self?.navigationController?.popViewController(animated: true)
                }
                guard isHavingUnsavedChanges, let conversation = self?.viewModel.conversation else {
                    return
                }
                self?.moveToActionHandler
                    .handleMoveToAction(conversations: [conversation],
                                        isFromSwipeAction: false,
                                        completion: nil)
            })
    }

}

// MARK: - New Message floaty view
extension ConversationViewController {
    private func showNewMessageFloatyView(messageId: MessageID) {

        let floatyView = customView.showNewMessageFloatyView(messageId: messageId, didHide: {})

        floatyView.handleTapAction { [weak self] in
            guard let index = self?.viewModel.messagesDataSource
                    .firstIndex(where: { $0.message?.messageID == messageId }),
                  let messageViewModel = self?.viewModel.messagesDataSource[safe: index]?.messageViewModel,
                  !messageViewModel.state.isExpanded else {
                return
            }

            self?.cellTapped(messageId: messageId)
            let indexPath = IndexPath(row: Int(index), section: 1)
            self?.attemptAutoScroll(to: indexPath, position: .top)
        }
    }

    func showMessage(of messageId: MessageID) {
        guard let index = viewModel.messagesDataSource
                .firstIndex(where: { $0.message?.messageID == messageId }) else {
            return
        }
        cellTapped(messageId: messageId)
        let indexPath = IndexPath(row: index, section: 1)
        self.attemptAutoScroll(to: indexPath, position: .top)
    }
}

extension ConversationViewController: PMActionSheetEventsListener {
    func willPresent() {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    func willDismiss() {}

    func didDismiss() {
        self.selectedMessageID = nil
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

extension ConversationViewController: UndoActionHandlerBase {

    func showUndoAction(token: UndoTokenData, title: String) { }

    func showActionRevertedBanner() { }

    var delaySendSeconds: Int {
        self.viewModel.user.userInfo.delaySendSeconds
    }
}
