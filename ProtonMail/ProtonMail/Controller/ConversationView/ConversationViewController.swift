import ProtonCore_UIFoundations
import UIKit

class ConversationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate,
                                  UIScrollViewDelegate, ComposeSaveHintProtocol {

    private var actionBar: PMActionBar?
    let viewModel: ConversationViewModel
    let coordinator: ConversationCoordinator
    private(set) lazy var customView = ConversationView()
    private var storedSize: [String: HeightStoreInfo] = [:]
    private let conversationNavigationViewPresenter = ConversationNavigationViewPresenter()
    private let conversationMessageCellPresenter = ConversationMessageCellPresenter()
    private let actionSheetPresenter = MessageViewActionSheetPresenter()
    private lazy var starBarButton = UIBarButtonItem.plain(target: self, action: #selector(starButtonTapped))
    private lazy var moveToActionSheetPresenter = MoveToActionSheetPresenter()
    private lazy var labelAsActionSheetPresenter = LabelAsActionSheetPresenter()

    init(coordinator: ConversationCoordinator, viewModel: ConversationViewModel) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        emptyBackButtonTitleForNextView()
        setUpTableView()
        navigationItem.backButtonTitle = .empty
        navigationItem.rightBarButtonItem = starBarButton
        starButtonSetUp(starred: viewModel.conversation.starred)

        viewModel.refreshView = { [weak self] in
            guard let self = self else { return }
            self.refreshNavigationViewIfNeeded()
            self.starButtonSetUp(starred: self.viewModel.conversation.starred)
        }

        viewModel.showNewMessageArrivedFloaty = { [weak self] messageId in
            self?.showNewMessageFloatyView(messageId: messageId)
        }

        conversationNavigationViewPresenter.present(viewType: viewModel.simpleNavigationViewType, in: navigationItem)
        customView.separator.isHidden = true

        viewModel.fetchConversationDetails()
        showActionBar()
        viewModel.observeConversationMessages(tableView: customView.tableView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !customView.tableView.visibleCells.isEmpty && // tableview finish reloading
                !viewModel.isExpandedAtLaunch,
              let row = viewModel.messagesDataSource
                .firstIndex(where: { $0.messageViewModel?.state.isExpanded ?? false }) else { return }
        viewModel.setCellIsExpandedAtLaunch()
        let indexPath = IndexPath(row: row, section: 1)
        customView.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
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
        height(for: indexPath)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        height(for: indexPath)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let itemType = indexPath.section == 0 ?
            viewModel.headerSectionDataSource[indexPath.row] :
            viewModel.messagesDataSource[indexPath.row]
        switch itemType {
        case .trashedHint:
            let cell = tableView.dequeue(cellType: ConversationViewTrashedHintCell.self)
            cell.setup(isTrashedHidden: self.viewModel.isTrashedMessageHidden, delegate: self.viewModel)
            return cell
        case .header(let subject):
            return headerCell(tableView, indexPath: indexPath, subject: subject)
        case .message(let viewModel):
            if viewModel.isTrashed && self.viewModel.isTrashedMessageHidden {
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
        unembed(controllerToUnembed)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let cell = customView.tableView.visibleCells.compactMap({ $0 as? ConversationViewHeaderCell }).first {
            let headerLabelConvertedFrame = cell.convert(cell.customView.titleLabel.frame, to: customView.tableView)
            let shouldPresentDetailedNavigationTitle = scrollView.contentOffset.y >= headerLabelConvertedFrame.maxY
            shouldPresentDetailedNavigationTitle ? presentDetailedNavigationTitle() : presentSimpleNavigationTitle()

            let separatorConvertedFrame = cell.convert(cell.customView.separator.frame, to: customView.tableView)
            let shouldShowSeparator = customView.tableView.contentOffset.y >= separatorConvertedFrame.maxY
            customView.separator.isHidden = !shouldShowSeparator

            cell.customView.topSpace = scrollView.contentOffset.y < 0 ? scrollView.contentOffset.y : 0
        } else {
            presentDetailedNavigationTitle()
            customView.separator.isHidden = false
        }
    }

    private func refreshNavigationViewIfNeeded() {
        if navigationItem.titleView is ConversationNavigationSimpleView {
            navigationItem.titleView = viewModel.simpleNavigationViewType.titleView
        }

        if navigationItem.titleView is ConversationNavigationDetailView {
            navigationItem.titleView = viewModel.detailedNavigationViewType.titleView
        }
    }

    private func cellTapped(messageId: String) {
        guard let index = self.viewModel.messagesDataSource
                .firstIndex(where: { $0.message?.messageID == messageId }),
              let messageViewModel = self.viewModel.messagesDataSource[safe: index]?.messageViewModel else {
            return
        }
        if messageViewModel.isDraft {
            coordinator.handle(navigationAction: .draft(message: messageViewModel.message))
        } else {
            messageViewModel.toggleState()
            customView.tableView.reloadRows(at: [.init(row: index, section: 1)], with: .automatic)
        }
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
        starBarButton.tintColor = starred ? UIColorManager.NotificationWarning : UIColorManager.IconWeak
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

    required init?(coder: NSCoder) {
        nil
    }

    private func presentActionSheet(for message: Message) {
        let forbidden = [Message.Location.allmail.rawValue,
                          Message.Location.starred.rawValue]
        guard let labels = message.labels.allObjects as? [Label],
              let location = labels
                .first(where: {
                        !forbidden.contains($0.labelID)
                    && ($0.type.intValue == 3 || Int($0.labelID) != nil)
                }) else { return }
        let viewModel = MessageViewActionSheetViewModel(title: message.subject,
                                                        labelID: location.labelID,
                                                        includeStarring: true,
                                                        isStarred: message.starred)
        actionSheetPresenter.present(on: navigationController ?? self, viewModel: viewModel) { [weak self] in
            self?.handleActionSheetAction($0, message: message)
        }
    }

    private func countHeightFor(viewType: ConversationViewItemType) -> CGFloat {
        guard let viewModel = viewType.messageViewModel else {
            return UITableView.automaticDimension
        }

        if viewModel.isTrashed && self.viewModel.isTrashedMessageHidden {
            return 0
        }
        let isMessageExpanded = viewModel.state.isExpanded
        if !isMessageExpanded {
            // For smooth animation
            return 56
        }

        guard let storedHeightInfo = storedSize[viewModel.message.messageID] else {
            return UITableView.automaticDimension
        }
        let isExpanded = viewModel.state.expandedViewModel?.messageContent.isExpanded
        if storedHeightInfo.isHeaderExpanded == isExpanded {
            return storedHeightInfo.height
        }
        return UITableView.automaticDimension
    }

    private func height(for indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return UITableView.automaticDimension
        case 1:
            guard let viewType = self.viewModel.messagesDataSource[safe: indexPath.row] else {
                return UITableView.automaticDimension
            }
            return countHeightFor(viewType: viewType)
        default:
            fatalError("Not supported section")
        }
    }

    private func headerCell(
        _ tableView: UITableView,
        indexPath: IndexPath,
        subject: String
    ) -> UITableViewCell {
        let cell = tableView.dequeue(cellType: ConversationViewHeaderCell.self)
        let style = FontManager.MessageHeader.alignment(.center)
        cell.customView.titleLabel.attributedText = subject.apply(style: style)
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
            let viewController = embedController(viewModel: expandedViewModel, in: cell, indexPath: indexPath)
            embed(viewController, inside: cell.container)
            viewController.customView.topArrowTapAction = { [weak self] in
                self?.cellTapped(messageId: viewModel.message.messageID)
            }

            cell.messageId = viewModel.message.messageID

            return cell
        }
    }
}

private extension ConversationViewController {
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
            navigationAction: { [weak self] in self?.handleSingleMessageAction(action: $0) }
        )

        let viewController = ConversationExpandedMessageViewController(
            viewModel: .init(message: viewModel.message, messageContent: contentViewModel),
            singleMessageContentViewController: singleMessageContentViewController
        )

        viewModel.recalculateCellHeight = { [weak self] in
            UIView.setAnimationsEnabled(false)
            let height = cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            let heightInfo = HeightStoreInfo(height: height, isHeaderExpanded: viewModel.messageContent.isExpanded)
            self?.storedSize[viewModel.message.messageID] = heightInfo
            self?.customView.tableView.beginUpdates()
            self?.customView.tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        }

        return viewController
    }

    private func presentDetailedNavigationTitle() {
        conversationNavigationViewPresenter.present(viewType: viewModel.detailedNavigationViewType, in: navigationItem)
    }

    private func presentSimpleNavigationTitle() {
        conversationNavigationViewPresenter.present(viewType: viewModel.simpleNavigationViewType, in: navigationItem)
    }
}

private extension Array where Element == ConversationViewItemType {

    func message(with id: String) -> Message? {
        compactMap(\.message)
            .first(where: { $0.messageID == id })
    }

}

private struct HeightStoreInfo: Hashable {
    let height: CGFloat
    let isHeaderExpanded: Bool
}

// MARK: - Action Bar
private extension ConversationViewController {
    private func showActionBar() {
        guard self.actionBar == nil else { return }

        let actions = viewModel.getActionTypes()
        var actionBarItems: [PMActionBarItem] = []
        for (key, action) in actions.enumerated() {
            let actionHandler: (PMActionBarItem) -> Void = { [weak self] _ in
                switch action {
                case .more:
                    self?.moreButtonTapped()
                case .reply:
                    if let message = self?.viewModel.messagesDataSource.newestMessage {
                        self?.coordinator.handle(navigationAction: .reply(message: message))
                    }
                case .replyAll:
                    if let message = self?.viewModel.messagesDataSource.newestMessage {
                        self?.coordinator.handle(navigationAction: .replyAll(message: message))
                    }
                case .delete:
                    self?.showDeleteAlert(deleteHandler: { [weak self] _ in
                        self?.viewModel.handleActionBarAction(action)
                        self?.navigationController?.popViewController(animated: true)
                    })
                default:
                    self?.viewModel.handleActionBarAction(action)
                    self?.navigationController?.popViewController(animated: true)
                }
            }

            let actionBarItem: PMActionBarItem
            if key == actions.startIndex {
                actionBarItem = PMActionBarItem(icon: action.iconImage, text: action.name, handler: actionHandler)
            } else {
                actionBarItem = PMActionBarItem(icon: action.iconImage, backgroundColor: .clear, handler: actionHandler)
            }
            actionBarItems.append(actionBarItem)
        }
        let separator = PMActionBarItem(width: 1,
                                        verticalPadding: 6,
                                        color: UIColorManager.FloatyText)
        actionBarItems.insert(separator, at: 1)
        self.actionBar = PMActionBar(items: actionBarItems,
                                     backgroundColor: UIColorManager.FloatyBackground,
                                     floatingHeight: 42.0,
                                     width: .fit,
                                     height: 48.0)
        self.actionBar?.show(at: self)
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

    private func moreButtonTapped() {
        guard let navigationVC = self.navigationController else { return }
        let isUnread = viewModel.conversation.isUnread(labelID: viewModel.labelId)
        let isStarred = viewModel.conversation.starred

        let messagesCountInTrash = viewModel.conversation.getNumMessages(labelID: Message.Location.trash.rawValue)
        let isAllMessagesInTrash = messagesCountInTrash == viewModel.conversation.numMessages.intValue
        let actionSheetViewModel = ConversationActionSheetViewModel(title: viewModel.conversation.subject,
                                                                    labelID: viewModel.labelId,
                                                                    isUnread: isUnread,
                                                                    isStarred: isStarred,
                                                                    isAllMessagesInTrash: isAllMessagesInTrash)
        actionSheetPresenter.present(on: navigationVC,
                                     viewModel: actionSheetViewModel) { [weak self] action in
            self?.handleActionSheetAction(action)
        }
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
                presentActionSheet(for: message)
            }
        case .url(let url):
            coordinator.handle(navigationAction: .url(url: url))
        default:
            break
        }
    }
}

enum ActionSheetDataSource {
    case message(_ message: Message)
    case conversation
}

extension ConversationViewController: LabelAsActionSheetPresentProtocol {
    var labelAsActionHandler: LabelAsActionSheetProtocol {
        return viewModel
    }

    private func showLabelAsActionSheetForConversation() {
        let labels = labelAsActionHandler.getLabelMenuItems()
        let labelAsViewModel = LabelAsActionSheetViewModelConversations(menuLabels: labels,
                                                                        conversations: [viewModel.conversation])

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        self?.coordinator.pendingActionAfterDismissal = { [weak self] in
                            self?.showLabelAsActionSheetForConversation()
                        }
                        self?.coordinator.handle(navigationAction: .addNewLabel)
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
                                                     currentOptionsStatus: currentOptionsStatus)
                        }
                        self?.dismissActionSheet()
                     }
            )
    }

    private func showLabelAsActionSheet(for message: Message) {
        let labelAsViewModel = LabelAsActionSheetViewModelMessages(menuLabels: labelAsActionHandler.getLabelMenuItems(),
                                                                   messages: [message])

        labelAsActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: labelAsViewModel,
                     addNewLabel: { [weak self] in
                        self?.coordinator.pendingActionAfterDismissal = { [weak self] in
                            self?.showLabelAsActionSheet(for: message)
                        }
                        self?.coordinator.handle(navigationAction: .addNewLabel)
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

    private func showMoveToActionSheet(for message: Message) {
        let isEnableColor = viewModel.user.isEnableFolderColor
        let isInherit = viewModel.user.isInheritParentFolderColor
        let moveToViewModel = MoveToActionSheetViewModelMessages(
            menuLabels: viewModel.getFolderMenuItems(),
            messages: [message],
            isEnableColor: isEnableColor,
            isInherit: isInherit,
            labelId: message.messageLocation?.rawValue ?? ""
        )

        moveToActionSheetPresenter.present(
            on: self.navigationController ?? self,
            viewModel: moveToViewModel,
            addNewFolder: { [weak self] in
                self?.coordinator.pendingActionAfterDismissal = { [weak self] in
                    self?.showMoveToActionSheet(for: message)
                }
                self?.coordinator.handle(navigationAction: .addNewFolder)
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
               self?.moveToActionHandler.handleMoveToAction(messages: [message])
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
            isInherit: isInherit,
            labelId: viewModel.labelId
        )

        moveToActionSheetPresenter
            .present(on: self.navigationController ?? self,
                     viewModel: moveToViewModel,
                     addNewFolder: { [weak self] in
                        self?.coordinator.pendingActionAfterDismissal = { [weak self] in
                            self?.showMoveToActionSheetForConversation()
                        }
                        self?.coordinator.handle(navigationAction: .addNewFolder)
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
                            self?.navigationController?.popViewController(animated: true)
                        }
                        guard isHavingUnsavedChanges, let conversation = self?.viewModel.conversation else {
                            return
                        }
                        self?.moveToActionHandler.handleMoveToAction(conversations: [conversation])
                     })
    }

}

// MARK: - New Message floaty view
extension ConversationViewController {
    private func showNewMessageFloatyView(messageId: String) {
        let floatyView = customView.showNewMessageFloatyView(messageId: messageId)
        floatyView.show { [weak self] in
            guard let index = self?.viewModel.messagesDataSource
                    .firstIndex(where: { $0.message?.messageID == messageId }),
                  let messageViewModel = self?.viewModel.messagesDataSource[safe: index]?.messageViewModel,
                  !messageViewModel.state.isExpanded else {
                return
            }

            self?.cellTapped(messageId: messageId)
            let indexPath = IndexPath(row: Int(index), section: 1)
            self?.customView.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }

    func showMessage(of messageId: String) {
        guard let index = viewModel.messagesDataSource.firstIndex(where: { $0.message?.messageID == messageId }) else {
            return
        }
        cellTapped(messageId: messageId)
        let indexPath = IndexPath(row: index, section: 1)
        customView.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}
