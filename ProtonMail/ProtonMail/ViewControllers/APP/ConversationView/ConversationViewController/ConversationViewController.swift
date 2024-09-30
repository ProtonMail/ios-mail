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

import LifetimeTracker
import MBProgressHUD
import ProtonCoreDataModel
import protocol ProtonCoreServices.APIService
import ProtonCoreUIFoundations
import ProtonMailAnalytics
import ProtonMailUI
import UIKit

// swiftlint:disable:next type_body_length
final class ConversationViewController: UIViewController, ComposeSaveHintProtocol,
    LifetimeTrackable, ScheduledAlertPresenter {
    typealias Dependencies = SingleMessageContentViewController.Dependencies & HasPaymentsUIFactory

    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 3)
    }

    let viewModel: ConversationViewModel

    private let dependencies: Dependencies
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
    private var _snoozeDateConfigReceiver: SnoozeDateConfigReceiver?
    private var upsellCoordinator: UpsellCoordinator?

    // the purpose of this timer is to uncover the conversation even if the viewModel does not call `conversationIsReadyToBeDisplayed` for whatever reason
    // this is to avoid making the view unusable
    private var conversationIsReadyToBeDisplayedTimer: Timer?
    var isInPageView: Bool {
        if ProcessInfo.isRunningUnitTests {
            return true
        } else {
            return (self.parent as? PagesViewController<ConversationID, ConversationEntity, ContextLabel>) != nil
        }
    }

    init(
        dependencies: Dependencies,
        viewModel: ConversationViewModel,
        applicationStateProvider: ApplicationStateProvider = UIApplication.shared
    ) {
        self.dependencies = dependencies
        self.viewModel = viewModel
        self.applicationStateProvider = applicationStateProvider

        super.init(nibName: nil, bundle: nil)

        self.viewModel.conversationViewController = self

        trackLifetime()
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpTableView()

        starButtonSetUp(starred: viewModel.conversation.starred)

        setupViewModel()

        conversationNavigationViewPresenter.present(viewType: viewModel.simpleNavigationViewType, in: navigationItem)
        customView.separator.isHidden = true

        viewModel.fetchConversationDetails { [weak self] in
            self?.viewModel.isInitialDataFetchCalled = true
        }

        registerNotification()

        hideConversationUntilItIsReady()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpNavigationBar()
        setUpToolBarIfNeeded()

        if !ProcessInfo.isRunningUnitTests {
            viewModel.observeConversationMessages(tableView: customView.tableView)
        }
        viewModel.observeConversationUpdate()
        self.viewModel.user.undoActionManager.register(handler: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        conversationIsReadyToBeDisplayedTimer = .scheduledTimer(
            withTimeInterval: 0.25,
            repeats: false
        ) { [weak self] _ in
            self?.displayConversation()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.backBarButtonItem = nil
        viewModel.stopObserveConversationAndMessages()
        self.dismissActionSheet()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if !customView.tableView.frame.isEmpty, let headerView = customView.tableView.tableHeaderView {
            // Apparently setting the frame and setting the tableViewHeader property again is needed
            // https://stackoverflow.com/questions/16471846/is-it-possible-to-use-autolayout-with-uitableviews-tableheaderview
            headerView.frame.size = headerView.systemLayoutSizeFitting(
                CGSize(width: customView.tableView.frame.width, height: 0)
            )
            customView.tableView.tableHeaderView = headerView
        }
    }

    private func leaveFocusedMode() {
        // the idea is to keep the expanded cell in exactly the same spot after expansion
        // to ensure that, we add the difference in content size to the offset

        let contentHeightBeforeExpansion = customView.tableView.contentSize.height

        customView.tableView.reloadData()

        let contentHeightAfterExpansion = customView.tableView.contentSize.height
        let previouslyHiddenContentHeight = contentHeightAfterExpansion - contentHeightBeforeExpansion

        // the 1/60 second (based on 60 FPS) makes the leaving animation much smoother
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 60) {
            self.customView.tableView.contentOffset.y += previouslyHiddenContentHeight
        }
    }

    func attemptAutoScroll(to indexPath: IndexPath, position: UITableView.ScrollPosition) {
        if self.customView.tableView.indexPathExists(indexPath) {
            self.customView.tableView.scrollToRow(at: indexPath, at: position, animated: true)
        }
    }

    func cellTapped(
        messageId: MessageID,
        reloadCompletion: (() -> Void)? = nil
    ) {
        guard !viewModel.tableViewIsUpdating else {
            PMAssertionFailure("Cell tapped while the table view is updating")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.cellTapped(messageId: messageId, reloadCompletion: reloadCompletion)
            }

            return
        }

        viewModel.cellTapped()

        guard let index = self.viewModel.messagesDataSource
            .firstIndex(where: { $0.message?.messageID == messageId }),
            let messageViewModel = self.viewModel.messagesDataSource[safe: index]?.messageViewModel else {
            return
        }

        if messageViewModel.isDraft {
            self.update(draft: messageViewModel.message)
        } else {
            let indexPath = IndexPath(row: index, section: 1)
            if let cachedVC = cachedViewControllers[indexPath] {
                unembed(cachedVC)
            }
            cachedViewControllers[indexPath] = nil
            messageViewModel.toggleState()
            customView.tableView.reloadRows(
                at: [.init(row: index, section: 1)],
                with: .automatic,
                completion: { reloadCompletion?() }
            )
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
            IconProvider.starFilled : IconProvider.star
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
        customView.tableView.register(cellType: ConversationMessageCell.self)
        customView.tableView.register(cellType: ConversationExpandedMessageCell.self)
        customView.tableView.register(cellType: UITableViewCell.self)
        customView.tableView.register(cellType: ConversationViewTrashedHintCell.self)
        customView.tableView.register(cellType: ConversationSkeletonCell.self)

        let headerView = ConversationViewHeaderView()
        let subject = viewModel.conversation.subject
            .keywordHighlighting
            .asAttributedString(keywords: viewModel.highlightedKeywords)
        headerView.titleTextView.set(text: subject, preferredFont: .title3)
        headerView.titleTextView.textAlignment = .center
        customView.tableView.tableHeaderView = headerView
    }

    private func registerNotification() {
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(willBecomeActive),
                         name: UIScene.willEnterForegroundNotification,
                         object: nil)
    }

    // swiftlint:disable:next function_body_length
    private func setupViewModel() {
        viewModel.conversationIsReadyToBeDisplayed = { [weak self] in
             self?.displayConversation()
        }

        viewModel.refreshView = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.refreshNavigationViewIfNeeded()
                self.starButtonSetUp(starred: self.viewModel.conversation.starred)
                let isNewMessageFloatyPresented = self.customView.subviews
                    .contains(where: { $0 is ConversationNewMessageFloatyView })
                guard !isNewMessageFloatyPresented else { return }

                self.setUpToolBarIfNeeded()
                // Prevent the banner being covered by the action bar
                self.view.subviews.compactMap { $0 as? PMBanner }.forEach { self.view.bringSubviewToFront($0) }

            	if !self.viewModel.messagesDataSource.isEmpty {
                	self.openSpecificMessageIfNeeded()
				}
            }
        }

        viewModel.dismissView = { [weak self] in
            DispatchQueue.main.async {
                if self?.viewModel.user.shouldMoveToNextMessageAfterMove == true {
                    // Dismiss view only triggered when the message count is zero.
                    // When the MoveToNextMessage feature is on, it will bring you to next conversation.
                    return
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
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
        } reloadWhenAppIsActive: { [weak self] in
            self?.shouldReloadWhenAppIsActive = true
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

        viewModel.reloadTableView = { [weak self] in
            guard let self = self else { return }
            self.customView.tableView.reloadData()
        }
    }

    private func openSpecificMessageIfNeeded() {
        if let targetID = viewModel.targetID {
            cellTapped(messageId: targetID)
            viewModel.targetID = nil
        }

        if let draftID = viewModel.draftID {
            cellTapped(messageId: draftID)
            viewModel.draftID = nil
        }
    }

    @objc
    private func willBecomeActive(_: Notification) {
        if shouldReloadWhenAppIsActive {
            viewModel.fetchConversationDetails(completion: nil)
            shouldReloadWhenAppIsActive = false
        }
    }

    required init?(coder: NSCoder) { nil }

    private func hideConversationUntilItIsReady() {
        customView.tableView.alpha = 0
    }

    private func displayConversation() {
        conversationIsReadyToBeDisplayedTimer = nil

        if Int(customView.tableView.alpha) < 1 {
            UIView.animate(withDuration: 0.25) {
                self.customView.tableView.alpha = 1
            }
        }
    }

    private func presentUpsellPage(
        entryPoint: UpsellPageEntryPoint,
        onDismiss: @escaping UpsellCoordinator.OnDismissCallback
    ) {
        upsellCoordinator = dependencies.paymentsUIFactory.makeUpsellCoordinator(rootViewController: self)
        upsellCoordinator?.start(entryPoint: entryPoint, onDismiss: onDismiss)
    }
}

extension ConversationViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        viewModel.scrollViewDidScroll()

        self.checkNavigationTitle()
    }
}

extension ConversationViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.isShowingSkeletonView {
            return 1
        } else {
            return 2
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !viewModel.isShowingSkeletonView else {
            return 1
        }
        switch section {
        case 0:
            return viewModel.headerSectionDataSource.count
        case 1:
            return viewModel.messagesDataSource.count
        default:
            fatalError("Not supported section")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !viewModel.isShowingSkeletonView else {
            return customView.tableView.dequeue(cellType: ConversationSkeletonCell.self)
        }
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
        case .message(let viewModel):
            if (viewModel.isTrashed && self.viewModel.displayRule == .showNonTrashedOnly) ||
                (!viewModel.isTrashed && self.viewModel.displayRule == .showTrashedOnly) {
                return tableView.dequeue(cellType: UITableViewCell.self)
            } else {
                return messageCell(tableView, indexPath: indexPath, viewModel: viewModel)
            }
        }
    }
}

extension ConversationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        height(for: indexPath, estimated: false)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        height(for: indexPath, estimated: true)
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
}

private extension ConversationViewController {
    private func presentActionSheet(for message: MessageEntity,
                                    isBodyDecrpytable: Bool,
                                    messageRenderStyle: MessageRenderStyle,
                                    shouldShowRenderModeOption: Bool,
                                    body: String?) {
        let forbidden = [Message.Location.allmail.rawValue,
                         Message.Location.starred.rawValue,
                         Message.HiddenLocation.sent.rawValue,
                         Message.HiddenLocation.draft.rawValue]
        // Better to disable linter rule here keep it this way for readability
        guard let location = message.labels
            .sorted(by: { label1, label2 in
                label1.labelID.rawValue < label2.labelID.rawValue
            })
            .first(where: {
                !forbidden.contains($0.labelID.rawValue)
                    && ($0.type == .folder || Int($0.labelID.rawValue) != nil)
            }) else { return }
        self.selectedMessageID = message.messageID
        let viewModel = MessageViewActionSheetViewModel(title: message.title,
                                                        labelID: location.labelID,
                                                        isStarred: message.isStarred,
                                                        isBodyDecryptable: isBodyDecrpytable,
                                                        messageRenderStyle: messageRenderStyle,
                                                        shouldShowRenderModeOption: shouldShowRenderModeOption,
                                                        isScheduledSend: message.isScheduledSend,
                                                        shouldShowSnooze: false)
        actionSheetPresenter.present(on: navigationController ?? self,
                                     listener: self,
                                     viewModel: viewModel) { [weak self] in
            self?.handleActionSheetAction($0, message: message, body: body)
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
        guard !viewModel.isShowingSkeletonView else {
            return UITableView.automaticDimension
        }
        switch indexPath.section {
        case 0:
            switch viewModel.headerCellVisibility(at: indexPath.row) {
            case .full:
                return UITableView.automaticDimension
            case .partial:
                return 24
            case .hidden:
                return 0
            }

        case 1:
            switch viewModel.messageCellVisibility(at: indexPath.row) {
            case .full:
                let viewType = viewModel.messagesDataSource[indexPath.row]
                return countHeightFor(viewType: viewType, estimated: estimated)
            case .partial:
                return 24
            case .hidden:
                return 0
            }
        default:
            fatalError("Not supported section")
        }
    }

    private func messageCell(
        _ tableView: UITableView,
        indexPath: IndexPath,
        viewModel: ConversationMessageViewModel
    ) -> UITableViewCell {
        switch viewModel.state {
        case .collapsed(let collapsedViewModel):
            let cell = tableView.dequeue(cellType: ConversationMessageCell.self)
            let messageID = viewModel.message.messageID
            cell.customView.tapAction = { [weak self] in
                self?.cellTapped(messageId: messageID)
            }
            let customView = cell.customView
            collapsedViewModel.reloadView = { [weak self] model in
                self?.conversationMessageCellPresenter.present(
                    model: model,
                    in: customView,
                    highlightedKeywords: self?.viewModel.highlightedKeywords ?? []
                )
            }
            cell.cellReuse = { [weak collapsedViewModel] in
                collapsedViewModel?.reloadView = nil
            }
            let model = collapsedViewModel.model(customFolderLabels: self.viewModel.customFolders)
            conversationMessageCellPresenter.present(
                model: model,
                in: cell.customView,
                highlightedKeywords: viewModel.highlightedKeywords
            )
            showSenderImageIfNeeded(in: cell, message: viewModel.message)
            return cell
        case .expanded(let expandedViewModel):
            let cell = tableView.dequeue(cellType: ConversationExpandedMessageCell.self)
            let viewController: ConversationExpandedMessageViewController
            if let cachedViewController = cachedViewControllers[indexPath] {
                viewController = cachedViewController
            } else {
                viewController = embedController(viewModel: expandedViewModel, in: cell)
                cachedViewControllers[indexPath] = viewController
            }
            embed(viewController, inside: cell.container)
            let messageID = viewModel.message.messageID
            viewController.customView.topArrowTapAction = { [weak self] in
                self?.cellTapped(messageId: messageID)
            }

            cell.messageId = viewModel.message.messageID

            return cell
        }
    }

    private func embedController(
        viewModel: ConversationExpandedMessageViewModel,
        in cell: ConversationExpandedMessageCell
    ) -> ConversationExpandedMessageViewController {
        cell.container.subviews.forEach { $0.removeFromSuperview() }
        let contentViewModel = viewModel.messageContent
        let singleMessageContentViewController = SingleMessageContentViewController(
            viewModel: contentViewModel,
            dependencies: dependencies,
            parentScrollView: customView.tableView,
            viewMode: .conversation,
            navigationAction: { [weak self] in self?.handleSingleMessageAction(action: $0) }
        )

        let viewController = ConversationExpandedMessageViewController(
            viewModel: viewModel,
            singleMessageContentViewController: singleMessageContentViewController
        )

        let messageID = viewModel.message.messageID
        viewModel.recalculateCellHeight = { [weak self, weak viewModel] _ in
            let isExpanded = viewModel?.messageContent.isExpanded ?? false
            self?.recalculateHeight(
                for: cell,
                messageId: messageID,
                isHeaderExpanded: isExpanded
            )
        }

        viewModel.resetLoadedHeight = { [weak self] in
            self?.storedSizeHelper.resetStoredSize(of: messageID)
        }

        return viewController
    }

    private func recalculateHeight(
        for cell: ConversationExpandedMessageCell,
        messageId: MessageID,
        isHeaderExpanded: Bool
    ) {
        let height = cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        let newHeightInfo = HeightStoreInfo(
            height: height,
            isHeaderExpanded: isHeaderExpanded,
            loaded: true
        )
        if self.storedSizeHelper
            .updateStoredSizeIfNeeded(newHeightInfo: newHeightInfo, messageID: messageId) {
            cell.setNeedsLayout()
            DispatchQueue.main.async {
                UIView.setAnimationsEnabled(false)
                self.customView.tableView.beginUpdates()
                self.customView.tableView.endUpdates()
                UIView.setAnimationsEnabled(true)
            }
        }
    }

    private func checkNavigationTitle() {
        let tableView = customView.tableView

        guard let headerView = tableView.tableHeaderView as? ConversationViewHeaderView else {
            return
        }

        let headerLabelConvertedFrame = headerView.convert(headerView.titleTextView.frame, to: tableView)
        let shouldPresentDetailedNavigationTitle = tableView.contentOffset.y >= headerLabelConvertedFrame.maxY

        if shouldPresentDetailedNavigationTitle {
            presentDetailedNavigationTitle()
        } else {
            presentSimpleNavigationTitle()
        }

        let separatorConvertedFrame = headerView.convert(headerView.separator.frame, to: tableView)
        let shouldShowSeparator = tableView.contentOffset.y >= separatorConvertedFrame.maxY
        customView.separator.isHidden = !shouldShowSeparator

        headerView.topSpace = tableView.contentOffset.y < 0 ? tableView.contentOffset.y : 0
    }

    private func presentDetailedNavigationTitle() {
        conversationNavigationViewPresenter.present(viewType: viewModel.detailedNavigationViewType, in: navigationItem)
    }

    private func presentSimpleNavigationTitle() {
        conversationNavigationViewPresenter.present(viewType: viewModel.simpleNavigationViewType, in: navigationItem)
    }

    private func refreshNavigationViewIfNeeded(forceUpdate: Bool = false) {
        // only reassign the titleView if needed
        if let titleView = navigationItem.titleView as? ConversationNavigationSimpleView {
            if titleView.titleLabel.attributedText?.string != viewModel.messagesTitle || forceUpdate {
                navigationItem.titleView = viewModel.simpleNavigationViewType.titleView
            }
        } else if let titleView = navigationItem.titleView as? ConversationNavigationDetailView {
            if titleView.topLabel.attributedText?.string != viewModel.messagesTitle ||
                titleView.bottomLabel.attributedText?.string != viewModel.conversation.subject ||
                forceUpdate {
                navigationItem.titleView = viewModel.detailedNavigationViewType.titleView
            }
        }
    }

    private func update(draft: MessageEntity) {
        MBProgressHUD.showAdded(to: self.view, animated: true)

        guard !viewModel.hasMessageEnqueuedTasks(draft.messageID) else {
            LocalString._mailbox_draft_is_uploading.alertToast()
            MBProgressHUD.hide(for: self.view, animated: true)
            return
        }
        viewModel.fetchMessageDetail(message: draft) { result in
            switch result {
            case .failure:
                let alert = LocalString._unable_to_edit_offline.alertController()
                alert.addOKAction()
                self.present(alert, animated: true, completion: nil)
            case .success(let draft):
                let objectID = draft.objectID.rawValue
                // The fetch API is saved on rootSavingContext
                // But the fetchController is working on mainContext
                // It take sometime to sync data
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                    guard let self = self,
                          let message = self.viewModel.message(by: objectID),
                          !message.body.isEmpty else { return }
                    timer.invalidate()
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.viewModel.handleNavigationAction(.draft(message: message))
                }
            }
        }
    }

    private func showMessageMoved(title: String, undoActionType: UndoAction? = nil) {
        guard !viewModel.user.shouldMoveToNextMessageAfterMove else {
            return
        }
        if var type = undoActionType {
            switch type {
            case .custom(let labelID) where labelID == Message.Location.archive.labelID:
                type = .archive
            case .custom(let labelID) where labelID == Message.Location.trash.labelID:
                type = .trash
            case .custom(let labelID) where labelID == Message.Location.spam.labelID:
                type = .spam
            default:
                break
            }
            viewModel.user.undoActionManager.addTitleWithAction(title: title, action: type)
        }
        let banner = PMBanner(message: title, style: PMBannerNewStyle.info, bannerHandler: PMBanner.dismiss)
        banner.show(at: PMBanner.onTopOfTheBottomToolBar, on: self.navigationController ?? self)
    }

    private func showSenderImageIfNeeded(in cell: ConversationMessageCell, message: MessageEntity) {
        viewModel.fetchSenderImageIfNeeded(
            message: message,
            isDarkMode: isDarkMode,
            scale: currentScreenScale
        ) { [weak self, weak cell] image in
            if let image = image, let cell = cell {
                self?.conversationMessageCellPresenter.present(senderImage: image, in: cell.customView)
            }
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

extension ConversationViewController {
    func setUpToolBarIfNeeded() {
        let actions = calculateToolBarActions()
        guard customView.toolbar.types != actions.map(\.type) else {
            return
        }
        customView.toolbar.setUpActions(actions)
    }

    func showToolbarCustomizeSpotlightIfNeeded() {
        guard viewModel.shouldShowToolbarCustomizeSpotlight(),
              let targetRect = customView.toolbarCGRect(),
              let navView = navigationController?.view,
              !navView.subviews.contains(where: { $0 is ToolbarCustomizeSpotlightView })
        else {
            return
        }
        let convertedRect = customView.convert(targetRect, to: self.navigationController?.view)
        let spotlight = ToolbarCustomizeSpotlightView()
        spotlight.presentOn(
            view: navView,
            targetFrame: convertedRect
        )
        spotlight.navigateToToolbarCustomizeView = { [weak self] in
            self?.viewModel.handleNavigationAction(.toolbarSettingView)
        }
        viewModel.setToolbarCustomizeSpotlightViewIsShown()
    }

    private func calculateToolBarActions() -> [PMToolBarView.ActionItem] {
        let types = viewModel.toolbarActionTypes()
        let result: [PMToolBarView.ActionItem] = types.compactMap { type in
            PMToolBarView.ActionItem(type: type,
                                     handler: { [weak self] in
                                         self?.handleActionSheetAction(type)
                                     })
        }
        return result
    }

    private func deleteAction(completion: (() -> Void)? = nil) {
        showDeleteAlert(
            deleteHandler: { [weak self] _ in
                self?.viewModel.sendSwipeNotificationIfNeeded(isInPageView: self?.isInPageView ?? false)
                self?.viewModel.handleActionSheetAction(.delete, completion: {})
                self?.showMessageMoved(title: LocalString._messages_has_been_deleted)
                guard self?.isInPageView ?? false else {
                    self?.navigationController?.popViewController(animated: true)
                    return
                }
            },
            completion: completion
        )
    }

    @objc
    private func unreadReadAction() {
        guard viewModel.messagesAreLoaded else { return }
        viewModel.handleActionSheetAction(.markUnread, completion: {})
        navigationController?.popViewController(animated: true)
    }

    @objc
    private func moveToAction() {
        showMoveToActionSheet(dataSource: .conversation)
    }

    @objc
    private func moreButtonTapped() {
        guard let navigationVC = self.navigationController,
              let messageToApplyAction = viewModel.findLatestMessageForAction()
        else { return }
        let isUnread = viewModel.conversation.isUnread(labelID: viewModel.labelId)
        let isStarred = viewModel.conversation.starred
        let isScheduleSend = messageToApplyAction.isScheduledSend
        let foldersSupportingSnooze = [
            Message.Location.snooze.labelID,
            Message.Location.inbox.labelID
        ]
        let isSupportSnooze = foldersSupportingSnooze.contains(viewModel.labelId)

        let actionSheetViewModel = ConversationActionSheetViewModel(
            title: viewModel.conversation.subject,
            isUnread: isUnread,
            isStarred: isStarred,
            isScheduleSend: isScheduleSend,
            isSupportSnooze: isSupportSnooze,
            areAllMessagesIn: { [weak self] location in
                self?.viewModel.areAllMessagesIn(location: location) ?? false
            }
        )
        actionSheetPresenter.present(
            on: navigationVC,
            listener: self,
            viewModel: actionSheetViewModel,
            action: { [weak self] action in
                self?.handleActionSheetAction(action)
            }
        )
    }

    private func showDeleteAlert(deleteHandler: ((UIAlertAction) -> Void)?,
                                 completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: LocalString._warning,
                                      message: LocalString._messages_will_be_removed_irreversibly,
                                      preferredStyle: .alert)
        let yes = UIAlertAction(title: LocalString._general_delete_action, style: .destructive, handler: deleteHandler)
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel)
        [yes, cancel].forEach(alert.addAction)

        self.present(alert, animated: true, completion: completion)
    }
}

// MARK: - Action Sheet Actions

extension ConversationViewController {
    func handleActionSheetAction(
        _ action: MessageViewActionSheetAction,
        alertShownCompletion: (() -> Void)? = nil
    ) {
        switch action {
        case .reply, .replyAll, .forward, .replyInConversation, .forwardInConversation,
                .replyOrReplyAllInConversation, .replyAllInConversation:
            handleOpenComposerAction(action, message: viewModel.findLatestMessageForAction())
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
            deleteAction(completion: alertShownCompletion)
        case .toolbarCustomization:
            viewModel.handleNavigationAction(
                .toolbarCustomization(
                    currentActions: viewModel.actionsForToolbarCustomizeView(),
                    allActions: viewModel.toolbarCustomizationAllAvailableActions()
                )
            )
        case .markUnread, .markRead:
            unreadReadAction()
        case .more:
            moreButtonTapped()
        case .trash:
            let continueAction: () -> Void = { [weak self] in
                self?.viewModel.sendSwipeNotificationIfNeeded(isInPageView: self?.isInPageView ?? false)
                self?.viewModel.handleActionSheetAction(action, completion: { [weak self] in
                    guard self?.isInPageView ?? false else {
                        self?.navigationController?.popViewController(animated: true)
                        return
                    }
                })
            }
            viewModel.searchForScheduled(displayAlert: { [weak self] scheduledNum in
                self?.displayScheduledAlert(scheduledNum: scheduledNum) { [weak self] in
                    self?.showMessageMoved(title: LocalString._message_moved_to_drafts)
                    continueAction()
                }
            }, continueAction: { [weak self] in
                self?.showMessageMoved(title: LocalString._messages_has_been_moved, undoActionType: .trash)
                continueAction()
            })
        case .archive, .spam, .inbox, .spamMoveToInbox:
            viewModel.sendSwipeNotificationIfNeeded(isInPageView: isInPageView)
            viewModel.handleActionSheetAction(action, completion: { [weak self] in
                guard self?.isInPageView ?? false else {
                    self?.navigationController?.popViewController(animated: true)
                    return
                }
            })
        case .viewHeaders, .viewHTML, .reportPhishing, .viewInDarkMode,
                .viewInLightMode, .replyOrReplyAll:
            // Actions here are applied to single message, not conversation.
            handleActionForLastMessageInConversation(action: action)
        case .print:
            handlePrintActionOnToolbar()
        case .saveAsPDF:
            handleExportPDFOnToolbar()
        case .snooze:
            presentSnoozeConfigSheet(on: self, current: Date())
        }
    }

    func handleOpenComposerAction(_ action: MessageViewActionSheetAction, message: MessageEntity?) {
        guard
            let message,
            let messageVM = viewModel.messagesDataSource.first(where: { $0.message?.messageID == message.messageID }),
            let singleMessageVM = messageVM.messageViewModel?.state.expandedViewModel?.messageContent
        else { return }

        let infoProvider = singleMessageVM.messageInfoProvider
        let remoteContentPolicy = infoProvider.remoteContentPolicy
        let embeddedContentPolicy = infoProvider.embeddedContentPolicy

        switch action {
        case .reply, .replyInConversation:
            viewModel.handleNavigationAction(
                .reply(
                    message: message,
                    remoteContentPolicy: remoteContentPolicy,
                    embeddedContentPolicy: embeddedContentPolicy
                )
            )
        case .replyAll, .replyAllInConversation:
            viewModel.handleNavigationAction(
                .replyAll(
                    message: message,
                    remoteContentPolicy: remoteContentPolicy,
                    embeddedContentPolicy: embeddedContentPolicy
                )
            )
        case .forward, .forwardInConversation:
            viewModel.handleNavigationAction(
                .forward(
                    message: message,
                    remoteContentPolicy: remoteContentPolicy,
                    embeddedContentPolicy: embeddedContentPolicy
                )
            )
        default:
            return
        }
    }

    private func handleSingleMessageAction(action: SingleMessageNavigationAction) {
        switch action {
        case let .reply(messageId, remoteContentPolicy, embeddedContentPolicy):
            guard let message = viewModel.messagesDataSource.message(with: messageId) else { return }
            viewModel.handleNavigationAction(
                .reply(
                    message: message,
                    remoteContentPolicy: remoteContentPolicy,
                    embeddedContentPolicy: embeddedContentPolicy
                )
            )
        case let .replyAll(messageId, remoteContentPolicy, embeddedContentPolicy):
            guard let message = viewModel.messagesDataSource.message(with: messageId) else { return }
            viewModel.handleNavigationAction(
                .replyAll(
                    message: message,
                    remoteContentPolicy: remoteContentPolicy,
                    embeddedContentPolicy: embeddedContentPolicy
                )
            )
        case .compose(let contact):
            viewModel.handleNavigationAction(.composeTo(contact: contact))
        case .contacts(let contact):
            viewModel.handleNavigationAction(.addContact(contact: contact))
        case let .attachmentList(messageId, body, attachments):
            guard let message = viewModel.messagesDataSource.message(with: messageId) else { return }
            let cids = message.getCIDOfInlineAttachment(decryptedBody: body)
            viewModel.handleNavigationAction(.attachmentList(inlineCIDs: cids, attachments: attachments))
        case .more(let messageId):
            if let message = viewModel.messagesDataSource.message(with: messageId) {
                handleMoreAction(messageId: messageId, message: message)
            }
        case .url(let url):
            viewModel.handleNavigationAction(.url(url: url))
        case .inAppSafari(let url):
            viewModel.handleNavigationAction(.inAppSafari(url: url))
        case .mailToUrl(let url):
            viewModel.handleNavigationAction(.mailToUrl(url: url))
        case let .forward(messageId, remoteContentPolicy, embeddedContentPolicy):
            guard let message = viewModel.messagesDataSource.message(with: messageId) else { return }
            viewModel.handleNavigationAction(
                .forward(
                    message: message,
                    remoteContentPolicy: remoteContentPolicy,
                    embeddedContentPolicy: embeddedContentPolicy
                )
            )
        case .viewCypher(url: let url):
            viewModel.handleNavigationAction(.viewCypher(url: url))
        default:
            break
        }
    }

    private func handleMoreAction(messageId: MessageID, message: MessageEntity) {
        let viewModel = viewModel.messagesDataSource.first(where: { $0.message?.messageID == messageId })
        let isBodyDecryptable = viewModel?.messageViewModel?.state.expandedViewModel?
            .messageContent.messageInfoProvider.isBodyDecryptable ?? false

        let singleMessageVM = viewModel?.messageViewModel?.state.expandedViewModel?.messageContent
        let infoProvider = singleMessageVM?.messageInfoProvider
        let renderStyle = infoProvider?.currentMessageRenderStyle ?? .dark
        let shouldDisplayRenderModeOptions = infoProvider?.shouldDisplayRenderModeOptions ?? false

        presentActionSheet(for: message,
                           isBodyDecrpytable: isBodyDecryptable,
                           messageRenderStyle: renderStyle,
                           shouldShowRenderModeOption: shouldDisplayRenderModeOptions,
                           body: infoProvider?.bodyParts?.originalBody)
    }

    private func handlePrintActionOnToolbar() {
        prepareForPrinting(completion: { [weak self] renderer, subject in
            guard let renderer = renderer, let subject = subject else {
                return
            }
            self?.presentPrintController(renderer: renderer,
                                         jobName: subject)
        })
    }

    private func handleExportPDFOnToolbar() {
        prepareForPrinting(completion: { [weak self] renderer, subject in
            guard let renderer = renderer,
                  let subject = subject,
                  let toolbar = self?.customView.toolbar else {
                return
            }
            self?.exportPDF(
                renderer: renderer,
                fileName: "\(subject).pdf",
                sourceView: toolbar
            )
        })
    }

    private func prepareForPrinting(completion: @escaping (ConversationPrintRenderer?, String?) -> Void) {
        guard let message = viewModel.findLatestMessageForAction() else {
            completion(nil, nil)
            return
        }

        if !viewModel.isCellExpanded(messageID: message.messageID) {
            cellTapped(
                messageId: message.messageID,
                reloadCompletion: { [weak self] in
                    self?.expandedMessageAndShowPrintProgress(message: message, completion: completion)
                }
            )
        } else {
            expandedMessageAndShowPrintProgress(message: message, completion: completion)
        }
    }

    private func expandedMessageAndShowPrintProgress(
        message: MessageEntity,
        completion: @escaping (ConversationPrintRenderer?, String?) -> Void
    ) {
        viewModel.expandHistoryIfNeeded(
            messageID: message.messageID,
            completion: { [weak self] in
                guard let contentsController = self?.contentController(for: message),
                      let subject = self?.viewModel.conversation.subject else {
                    completion(nil, nil)
                    return
                }
                self?.showProgressHud()
                if contentsController.messageBodyViewController.isLoading {
                    contentsController.messageBodyViewController.webViewIsLoaded = { [weak contentsController] in
                        defer {
                            self?.hideProgressHud()
                            contentsController?.messageBodyViewController.webViewIsLoaded = nil
                        }
                        guard let contentsController = contentsController else {
                            completion(nil, nil)
                            return
                        }
                        let renderer = ConversationPrintRenderer([contentsController])
                        completion(renderer, subject)
                    }
                } else {
                    self?.hideProgressHud()
                    let renderer = ConversationPrintRenderer([contentsController])
                    completion(renderer, subject)
                }
            }
        )
    }

    private func handleActionForLastMessageInConversation(action: MessageViewActionSheetAction) {
        guard let message = viewModel.findLatestMessageForAction() else {
            return
        }
        let body = viewModel.getMessageBodyBy(messageID: message.messageID)
        handleActionSheetAction(action, message: message, body: body)
    }
}

enum ActionSheetDataSource {
    case message(_ message: MessageEntity)
    case conversation
}

extension ConversationViewController: ContentPrintable {}

extension ConversationViewController {
    var labelAsActionHandler: LabelAsActionSheetProtocol {
        return viewModel
    }

    private func showLabelAsActionSheetForConversation() {
        let labels = labelAsActionHandler.getLabelMenuItems()
        let convMessages = viewModel.messagesDataSource.compactMap(\.message)
        let labelAsViewModel = LabelAsActionSheetViewModelConversationMessages(menuLabels: labels,
                                                                               conversationMessages: convMessages)

        labelAsActionSheetPresenter.present(
            on: self.navigationController ?? self,
            listener: self,
            viewModel: labelAsViewModel,
            addNewLabel: { [weak self] in
                guard let self = self else { return }
                if self.allowToCreateLabels(existingLabels: labelAsViewModel.menuLabels.count) {
                    self.viewModel.coordinator.pendingActionAfterDismissal = { [weak self] in
                        self?.showLabelAsActionSheetForConversation()
                    }
                    self.viewModel.handleNavigationAction(.addNewLabel)
                } else {
                    self.presentUpsellPage(entryPoint: .labels) { [weak self] in
                        self?.showLabelAsActionSheetForConversation()
                    }
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
            done: { [weak self] isArchive, currentOptionsStatus in
                if isArchive {
                    self?.showMessageMoved(title: LocalString._messages_has_been_moved, undoActionType: .archive)
                    self?.viewModel.sendSwipeNotificationIfNeeded(isInPageView: self?.isInPageView ?? false)
                }
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
                             self.viewModel.coordinator.pendingActionAfterDismissal = { [weak self] in
                                 self?.showLabelAsActionSheet(for: message)
                             }
                             self.viewModel.handleNavigationAction(.addNewLabel)
                         } else {
                             self.presentUpsellPage(entryPoint: .labels) { [weak self] in
                                 self?.showLabelAsActionSheet(for: message)
                             }
                         }
                     },
                     selected: { [weak self] menuLabel, isOn in
                         self?.labelAsActionHandler.updateSelectedLabelAsDestination(menuLabel: menuLabel, isOn: isOn)
                     },
                     cancel: { [weak self] isHavingUnsavedChanges in
                         if isHavingUnsavedChanges {
                             self?.showDiscardAlert(handleDiscard: {
                                 self?.labelAsActionHandler.updateSelectedLabelAsDestination(
                                    menuLabel: nil,
                                    isOn: false
                                 )
                                 self?.dismissActionSheet()
                             })
                         } else {
                             self?.dismissActionSheet()
                         }
                     },
                     done: { [weak self] isArchive, currentOptionsStatus in
                        if isArchive {
                            self?.viewModel.sendSwipeNotificationIfNeeded(isInPageView: self?.isInPageView ?? false)
                        }
                         self?.labelAsActionHandler
                             .handleLabelAsAction(messages: [message],
                                                  shouldArchive: isArchive,
                                                  currentOptionsStatus: currentOptionsStatus)
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

    private func allowToCreateFolders(existingFolders: Int) -> Bool {
        let isFreeAccount = viewModel.user.userInfo.subscribed.isEmpty
        if isFreeAccount {
            return existingFolders < Constants.FreePlan.maxNumberOfFolders
        }
        return true
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

extension ConversationViewController {
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
        var menuLabels = viewModel.getFolderMenuItems()
        if message.isSent {
            menuLabels.removeAll(where: { $0.location == .inbox })
        }
        let moveToViewModel = MoveToActionSheetViewModelMessages(
            menuLabels: menuLabels,
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
                    self.viewModel.coordinator.pendingActionAfterDismissal = { [weak self] in
                        self?.showMoveToActionSheet(for: message)
                    }
                    self.viewModel.handleNavigationAction(.addNewFolder)
                } else {
                    self.presentUpsellPage(entryPoint: .folders) { [weak self] in
                        self?.showMoveToActionSheet(for: message)
                    }
                }
            },
            selected: { [weak self] menuLabel, isSelected in
                guard isSelected else { return }
                self?.didSelectFolderToMoveToForMessage(folder: menuLabel, message: message)
            },
            cancel: { [weak self] in
                self?.dismissActionSheet()
            }
        )
    }

    private func didSelectFolderToMoveToForMessage(folder: MenuLabel, message: MessageEntity) {
        viewModel.sendSwipeNotificationIfNeeded(isInPageView: isInPageView)
        viewModel.handleMoveToAction(messages: [message], to: folder)

        dismissActionSheet()
        if !isInPageView {
            navigationController?.popViewController(animated: true)
        }
    }

    private func showMoveToActionSheetForConversation() {
        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor

        let moveToViewModel = MoveToActionSheetViewModelMessages(
            menuLabels: viewModel.getFolderMenuItems(),
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
                    self.viewModel.coordinator.pendingActionAfterDismissal = { [weak self] in
                        self?.showMoveToActionSheetForConversation()
                    }
                    self.viewModel.handleNavigationAction(.addNewFolder)
                } else {
                    self.presentUpsellPage(entryPoint: .folders) { [weak self] in
                        self?.showMoveToActionSheetForConversation()
                    }
                }
            },
            selected: { [weak self] menuLabel, isSelected in
                guard isSelected else { return }
                self?.didSelectFolderToMoveToForConversation(folder: menuLabel)
            },
            cancel: { [weak self] in
                self?.dismissActionSheet()
            }
        )
    }

    private func didSelectFolderToMoveToForConversation(folder: MenuLabel) {
        defer {
            dismissActionSheet()
            if !isInPageView {
                navigationController?.popViewController(animated: true)
            }
        }

        let conversation = viewModel.conversation
        let continueAction: () -> Void = { [weak self] in
            self?.viewModel.handleMoveToAction(
                conversations: [conversation],
                to: folder
            )
            self?.showMessageMoved(
                title: LocalString._messages_has_been_moved,
                undoActionType: .custom(folder.location.labelID)
            )
        }

        viewModel.sendSwipeNotificationIfNeeded(isInPageView: isInPageView)
        if folder.location == .trash {
            viewModel.searchForScheduled(
                conversation: conversation,
                displayAlert: { [weak self] scheduledNum in
                    self?.displayScheduledAlert(scheduledNum: scheduledNum, continueAction: continueAction)
                },
                continueAction: continueAction
            )
        } else {
            continueAction()
        }
    }
}

// MARK: - New Message floaty view

extension ConversationViewController {
    private func showNewMessageFloatyView(messageId: MessageID) {
        let floatyView = customView.showNewMessageFloatyView(didHide: {})

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
    var undoActionManager: UndoActionManagerProtocol? {
        viewModel.user.undoActionManager
    }

    var delaySendSeconds: Int {
        self.viewModel.user.userInfo.delaySendSeconds
    }

    var composerPresentingVC: UIViewController? {
        self
    }

    func showUndoAction(undoTokens: [String], title: String) {}
}

private extension UITableView {
    func reloadRows(at indexPaths: [IndexPath],
                    with animation: UITableView.RowAnimation,
                    completion: @escaping () -> Void) {
        UIView.animate(
            withDuration: 0,
            animations: {
                self.reloadRows(at: indexPaths, with: animation)
            },
            completion: { _ in
                completion()
            }
        )
    }
}

extension ConversationViewController: SnoozeSupport {
    var conversationDataService: ConversationDataServiceProxy { viewModel.user.conversationService }

    var calendar: Calendar { LocaleEnvironment.calendar }

    var isPaidUser: Bool { viewModel.user.hasPaidMailPlan }

    var presentingView: UIView { navigationController?.view ?? self.view }

    var snoozeConversations: [ConversationID] { [viewModel.conversation.conversationID] }

    var snoozeDateConfigReceiver: SnoozeDateConfigReceiver {
        let receiver = _snoozeDateConfigReceiver ?? SnoozeDateConfigReceiver(
            saveDate: { [weak self] date in
                self?.willSnooze()
                self?.snooze(on: date)
                self?._snoozeDateConfigReceiver = nil
            }, cancelHandler: { [weak self] in
                self?._snoozeDateConfigReceiver = nil
            }, showSendInTheFutureAlertHandler: {
                L10n.Snooze.selectTimeInFuture.alertToastBottom()
            }
        )
        _snoozeDateConfigReceiver = receiver
        return receiver
    }

    var weekStart: WeekStart { viewModel.user.userInfo.weekStartValue }

    @MainActor
    func showSnoozeSuccessBanner(on date: Date) {
        let dateStr = PMDateFormatter.shared.stringForSnoozeTime(from: date)

        let title = String(format: L10n.Snooze.bannerTitle, dateStr)
        let banner = PMBanner(message: title, style: PMBannerNewStyle.info)
        if viewModel.shouldMoveToNextMessageAfterMove {
            // PageVC
            guard let viewController = parent else { return }
            banner.show(at: PMBanner.onTopOfTheBottomToolBar, on: viewController)
        } else {
            // MailboxVC
            guard let viewController = navigationController?.viewControllers.first else { return }
            navigationController?.popViewController(animated: true)
            banner.show(at: .bottom, on: viewController)
        }
    }

    func presentPaymentView() {
        presentUpsellPage(entryPoint: .snooze) { [weak self] in
            guard let self else { return }

            self.presentSnoozeConfigSheet(on: self, current: Date())
        }
    }

    func willSnooze() {
        viewModel.sendSwipeNotificationIfNeeded(isInPageView: isInPageView)
    }
}
