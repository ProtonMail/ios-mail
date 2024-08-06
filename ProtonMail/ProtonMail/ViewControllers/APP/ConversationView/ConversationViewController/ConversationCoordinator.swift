import ProtonCoreDataModel
import SafariServices

// sourcery: mock
protocol ConversationCoordinatorProtocol: AnyObject {
    var pendingActionAfterDismissal: (() -> Void)? { get set }

    func handle(navigationAction: ConversationNavigationAction)
}

class ConversationCoordinator: CoordinatorDismissalObserver, ConversationCoordinatorProtocol {
    typealias Dependencies = ConversationViewController.Dependencies
    & HasComposerViewFactory
    & HasContactViewsFactory
    & HasToolbarSettingViewFactory
    & HasSaveToolbarActionSettings
    & ConversationViewModel.Dependencies

    weak var viewController: ConversationViewController?

    private let labelId: LabelID
    private weak var navigationController: UINavigationController?
    let conversation: ConversationEntity
    private let user: UserManager
    private let targetID: MessageID?
    private let highlightedKeywords: [String]
    private let dependencies: Dependencies
    var pendingActionAfterDismissal: (() -> Void)?
    var goToDraft: ((MessageID, Date?) -> Void)?

    init(
        labelId: LabelID,
        navigationController: UINavigationController,
        conversation: ConversationEntity,
        highlightedKeywords: [String] = [],
        dependencies: Dependencies,
        targetID: MessageID? = nil
    ) {
        self.labelId = labelId
        self.navigationController = navigationController
        self.conversation = conversation
        self.user = dependencies.user
        self.targetID = targetID
        self.highlightedKeywords = highlightedKeywords
        self.dependencies = dependencies
    }

    func start() {
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
        let viewModel = ConversationViewModel(
            labelId: labelId,
            conversation: conversation,
            coordinator: self,
            conversationStateProvider: user.conversationStateService,
            labelProvider: user.labelService,
            targetID: targetID,
            toolbarActionProvider: user,
            saveToolbarActionUseCase: dependencies.saveToolbarActionSettings,
            highlightedKeywords: highlightedKeywords,
            goToDraft: { [weak self] msgID, originalScheduledTime in
                self?.navigationController?.popViewController(animated: false)
                self?.goToDraft?(msgID, originalScheduledTime)
            },
            dependencies: dependencies)
        let viewController = ConversationViewController(dependencies: dependencies, viewModel: viewModel)
        self.viewController = viewController
        return viewController
    }

    func handle(navigationAction: ConversationNavigationAction) {
        switch navigationAction {
        case let .reply(message, remoteContentPolicy, embeddedContentPolicy):
            presentCompose(
                message: message,
                action: .reply,
                remoteContentPolicy: remoteContentPolicy,
                embeddedContentPolicy: embeddedContentPolicy
            )
        case .draft(let message):
            presentCompose(
                message: message,
                action: .openDraft,
                remoteContentPolicy: nil,
                embeddedContentPolicy: nil
            )
        case .addContact(let contact):
            presentAddContacts(with: contact)
        case .composeTo(let contact):
            presentCompose(with: contact)
        case let .attachmentList(inlineCIDs, attachments):
            presentAttachmentListView(inlineCIDS: inlineCIDs, attachments: attachments)
        case .mailToUrl(let url):
            presentCompose(with: url)
        case let .replyAll(message, remoteContentPolicy, embeddedContentPolicy):
            presentCompose(
                message: message,
                action: .replyAll,
                remoteContentPolicy: remoteContentPolicy,
                embeddedContentPolicy: embeddedContentPolicy
            )
        case let .forward(message, remoteContentPolicy, embeddedContentPolicy):
            presentCompose(
                message: message,
                action: .forward,
                remoteContentPolicy: remoteContentPolicy,
                embeddedContentPolicy: embeddedContentPolicy
            )
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
        case .toolbarSettingView:
            presentToolbarCustomizationSettingView()
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
        let composer = dependencies.composerViewFactory.makeComposer(
            msg: nil,
            action: .newDraft,
            remoteContentPolicy: nil,
            embeddedContentPolicy: nil,
            toContact: contact
        )
        viewController?.present(composer, animated: true)
    }

    private func presentCompose(with mailToURL: URL) {
        let composer = dependencies.composerViewFactory.makeComposer(
            msg: nil,
            action: .newDraft,
            mailToUrl: mailToURL
        )
        viewController?.present(composer, animated: true)
    }

    private func presentCompose(
        message: MessageEntity,
        action: ComposeMessageAction,
        remoteContentPolicy: WebContents.RemoteContentPolicy?,
        embeddedContentPolicy: WebContents.EmbeddedContentPolicy?
    ) {
        guard message.isDetailDownloaded else { return }
        guard let msg: MessageEntity? = dependencies.contextProvider.read(block: { context in
            if let msg = context.object(with: message.objectID.rawValue) as? Message {
                return MessageEntity(msg)
            } else {
                return nil
            }
        }) else { return }
        let composer = dependencies.composerViewFactory.makeComposer(
            msg: msg,
            action: action,
            remoteContentPolicy: remoteContentPolicy,
            embeddedContentPolicy: embeddedContentPolicy
        )
        viewController?.present(composer, animated: true)
    }

    private func presentAddContacts(with contact: ContactVO) {
        let newView = dependencies.contactViewsFactory.makeEditView(contact: contact)
        let nav = UINavigationController(rootViewController: newView)
        self.viewController?.present(nav, animated: true)
    }

    private func presentAttachmentListView(inlineCIDS: [String]?, attachments: [AttachmentInfo]) {
        let viewModel = AttachmentListViewModel(
            attachments: attachments,
            inlineCIDS: inlineCIDS,
            dependencies: dependencies
        )
        let viewController = AttachmentListViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }

    private func presentWebView(url: URL) {
        UIApplication.shared.open(
            url,
            options: [:],
            completionHandler: nil
        )
    }

    private func presentInAppSafari(url: URL) {
        let safari = SFSafariViewController(url: url)
        self.viewController?.present(safari, animated: true, completion: nil)
    }

    private func presentToolbarCustomization(
        allActions: [MessageViewActionSheetAction],
        currentActions: [MessageViewActionSheetAction]
    ) {
        let view = dependencies.toolbarSettingViewFactory.makeCustomizeView(
            currentActions: currentActions,
            allActions: allActions
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

    private func presentToolbarCustomizationSettingView() {
        let settingView = dependencies.toolbarSettingViewFactory.makeSettingView()
        self.viewController?.navigationController?.pushViewController(settingView, animated: true)
    }
}
