import SafariServices

protocol ConversationCoordinatorProtocol: AnyObject {
    var pendingActionAfterDismissal: (() -> Void)? { get set }
    var goToDraft: ((MessageID, OriginalScheduleDate?) -> Void)? { get set }

    func handle(navigationAction: ConversationNavigationAction)
}

class ConversationCoordinator: CoordinatorDismissalObserver, ConversationCoordinatorProtocol {

    weak var viewController: ConversationViewController?

    private let labelId: LabelID
    private weak var navigationController: UINavigationController?
    let conversation: ConversationEntity
    private let user: UserManager
    private let targetID: MessageID?
    private let internetStatusProvider: InternetConnectionStatusProvider
    private let infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider
    var pendingActionAfterDismissal: (() -> Void)?
    var goToDraft: ((MessageID, OriginalScheduleDate?) -> Void)?

    init(labelId: LabelID,
         navigationController: UINavigationController,
         conversation: ConversationEntity,
         user: UserManager,
         internetStatusProvider: InternetConnectionStatusProvider,
         infoBubbleViewStatusProvider: ToolbarCustomizationInfoBubbleViewStatusProvider,
         targetID: MessageID? = nil) {
        self.labelId = labelId
        self.navigationController = navigationController
        self.conversation = conversation
        self.user = user
        self.targetID = targetID
        self.internetStatusProvider = internetStatusProvider
        self.infoBubbleViewStatusProvider = infoBubbleViewStatusProvider
    }

    func start(openFromNotification: Bool = false) {
        let viewController = makeConversationVC()
        self.viewController = viewController
        if navigationController?.viewControllers.last is MessagePlaceholderVC,
           var viewControllers = navigationController?.viewControllers {
            _ = viewControllers.popLast()
            viewControllers.append(viewController)
            navigationController?.setViewControllers(viewControllers, animated: false)
        } else {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func makeConversationVC() -> ConversationViewController {
        let fetchMessageDetail = FetchMessageDetail(
            dependencies: .init(
                queueManager: sharedServices.get(by: QueueManager.self),
                apiService: user.apiService,
                contextProvider: sharedServices.get(by: CoreDataService.self),
                realAttachmentsFlagProvider: userCachedStatus,
                messageDataAction: user.messageService,
                cacheService: user.cacheService
            )
        )
        let dependencies = ConversationViewModel.Dependencies(
            fetchMessageDetail: fetchMessageDetail
        )
        let viewModel = ConversationViewModel(
            labelId: labelId,
            conversation: conversation,
            user: user,
            contextProvider: CoreDataService.shared,
            internetStatusProvider: internetStatusProvider,
            conversationStateProvider: user.conversationStateService,
            labelProvider: user.labelService,
            userIntroductionProgressProvider: userCachedStatus,
            targetID: targetID,
            toolbarActionProvider: user,
            saveToolbarActionUseCase: SaveToolbarActionSettings(
                dependencies: .init(user: user)
            ),
            toolbarCustomizeSpotlightStatusProvider: userCachedStatus,
            goToDraft: { [weak self] msgID, originalScheduledTime in
                self?.navigationController?.popViewController(animated: false)
                self?.goToDraft?(msgID, originalScheduledTime)
            },
            dependencies: dependencies)
        let viewController = ConversationViewController(coordinator: self, viewModel: viewModel)
        self.viewController = viewController
        return viewController
    }

    func handle(navigationAction: ConversationNavigationAction) {
        switch navigationAction {
        case .reply(let message):
            presentCompose(message: message, action: .reply)
        case .draft(let message):
            presentCompose(message: message, action: .openDraft)
        case .addContact(let contact):
            presentAddContacts(with: contact)
        case .composeTo(let contact):
            presentCompose(with: contact)
        case let .attachmentList(message, inlineCIDs, attachments):
            presentAttachmentListView(message: message, inlineCIDS: inlineCIDs, attachments: attachments)
        case .mailToUrl(let url):
            presentCompose(with: url)
        case .replyAll(let message):
            presentCompose(message: message, action: .replyAll)
        case .forward(let message):
            presentCompose(message: message, action: .forward)
        case .viewHeaders(url: let url):
            presentQuickLookView(url: url, subType: .headers)
        case .viewHTML(url: let url):
            presentQuickLookView(url: url, subType: .html)
        case .viewCypher(url: let url):
            presentQuickLookView(url: url, subType: .cypher)
        case .addNewFolder:
            presentCreateFolder(type: .folder)
        case .addNewLabel:
            presentCreateFolder(type: .label)
        case .url(let url):
            presentWebView(url: url)
        case .inAppSafari(let url):
            presentInAppSafari(url: url)
        case let .toolbarCustomization(currentActions: currentActions,
                                       allActions: allActions):
            presentToolbarCustomization(allActions: allActions,
                                        currentActions: currentActions)
        }
    }

    // MARK: - Private methods
    private func presentCreateFolder(type: PMLabelType) {
        let folderLabels = user.labelService.getMenuFolderLabels()
        let dependencies = LabelEditViewModel.Dependencies(userManager: user)
        let navigationController = LabelEditStackBuilder.make(
            editMode: .creation,
            type: type,
            labels: folderLabels,
            dependencies: dependencies,
            coordinatorDismissalObserver: self
        )
        self.viewController?.navigationController?.present(navigationController, animated: true, completion: nil)
    }

    private func presentQuickLookView(url: URL?, subType: PlainTextViewerViewController.ViewerSubType) {
        guard let fileUrl = url, let text = try? String(contentsOf: fileUrl) else { return }
        let viewer = PlainTextViewerViewController(text: text, subType: subType)
        try? FileManager.default.removeItem(at: fileUrl)
        self.navigationController?.pushViewController(viewer, animated: true)
    }

    private func presentCompose(with contact: ContactVO) {
        let viewModel = ContainableComposeViewModel(
            msg: nil,
            action: .newDraft,
            msgService: user.messageService,
            user: user,
            coreDataContextProvider: sharedServices.get(by: CoreDataService.self)
        )
        viewModel.addToContacts(contact)

        presentCompose(viewModel: viewModel)
    }

    private func presentCompose(with mailToURL: URL) {
        let viewModel = ContainableComposeViewModel(
            msg: nil,
            action: .newDraft,
            msgService: user.messageService,
            user: user,
            coreDataContextProvider: sharedServices.get(by: CoreDataService.self)
        )
        viewModel.parse(mailToURL: mailToURL)

        presentCompose(viewModel: viewModel)
    }

    private func presentCompose(message: MessageEntity, action: ComposeMessageAction) {
        let contextProvider = sharedServices.get(by: CoreDataService.self)
        guard let rawMessage = contextProvider.mainContext.object(with: message.objectID.rawValue) as? Message else {
            return
        }
        let viewModel = ContainableComposeViewModel(
            msg: rawMessage,
            action: action,
            msgService: user.messageService,
            user: user,
            coreDataContextProvider: contextProvider
        )

        presentCompose(viewModel: viewModel)
    }

    private func presentCompose(viewModel: ContainableComposeViewModel) {
        let coordinator = ComposeContainerViewCoordinator(presentingViewController: self.viewController,
                                                          editorViewModel: viewModel)
        coordinator.start()
    }

    private func presentAddContacts(with contact: ContactVO) {
        let viewModel = ContactAddViewModelImpl(contactVO: contact,
                                                user: user,
                                                coreDataService: sharedServices.get(by: CoreDataService.self))
        let newView = ContactEditViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: newView)
        self.viewController?.present(nav, animated: true)
    }

    private func presentAttachmentListView(message: MessageEntity,
                                           inlineCIDS: [String]?,
                                           attachments: [AttachmentInfo]) {
        let viewModel = AttachmentListViewModel(
            attachments: attachments,
            user: user,
            inlineCIDS: inlineCIDS,
            dependencies: .init(fetchAttachment: FetchAttachment(dependencies: .init(apiService: user.apiService)))
        )
        let viewController = AttachmentListViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func presentWebView(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: nil)
        }
    }

    private func presentInAppSafari(url: URL) {
        let safari = SFSafariViewController(url: url)
        self.viewController?.present(safari, animated: true, completion: nil)
    }

    private func presentToolbarCustomization(
        allActions: [MessageViewActionSheetAction],
        currentActions: [MessageViewActionSheetAction]
    ) {
        let view = ToolbarCustomizeViewController<MessageViewActionSheetAction>(
            viewModel: .init(
                currentActions: currentActions,
                allActions: allActions,
                actionsNotAddableToToolbar: MessageViewActionSheetAction.actionsNotAddableToToolbar,
                defaultActions: MessageViewActionSheetAction.defaultActions,
                infoBubbleViewStatusProvider: infoBubbleViewStatusProvider
            )
        )
        view.customizationIsDone = { [weak self] result in
            self?.viewController?.showProgressHud()
            self?.viewController?.viewModel.updateToolbarActions(
                actions: result,
                completion: { error in
                    if let error = error {
                        error.alertErrorToast()
                    }
                    self?.viewController?.setUpToolBarIfNeeded()
                    self?.viewController?.hideProgressHud()
                }
            )
        }
        let nav = UINavigationController(rootViewController: view)
        viewController?.navigationController?.present(nav, animated: true)
    }
}
