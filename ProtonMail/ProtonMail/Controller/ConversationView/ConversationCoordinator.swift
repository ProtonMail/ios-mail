class ConversationCoordinator: CoordinatorDismissalObserver {

    weak var viewController: ConversationViewController?

    private let labelId: String
    private let navigationController: UINavigationController
    let conversation: Conversation
    private let user: UserManager
    var pendingActionAfterDismissal: (() -> Void)?

    init(labelId: String, navigationController: UINavigationController, conversation: Conversation, user: UserManager) {
        self.labelId = labelId
        self.navigationController = navigationController
        self.conversation = conversation
        self.user = user
    }

    func start(openFromNotification: Bool = false) {
        let viewModel = ConversationViewModel(
            labelId: labelId,
            conversation: conversation,
            user: user,
            openFromNotification: openFromNotification
        )
        let viewController = ConversationViewController(coordinator: self, viewModel: viewModel)
        self.viewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    private func presentCreateFolder(type: PMLabelType) {
        let viewModel = LabelEditViewModel(user: user, label: nil, type: type, labels: [])
        let viewController = LabelEditViewController.instance()
        let coordinator = LabelEditCoordinator(services: sharedServices,
                                               viewController: viewController,
                                               viewModel: viewModel,
                                               coordinatorDismissalObserver: self)
        coordinator.start()
        if let navigation = viewController.navigationController {
            self.viewController?.navigationController?.present(navigation, animated: true, completion: nil)
        }
    }

    private func presentQuickLookView(url: URL?, subType: PlainTextViewerViewController.ViewerSubType) {
        guard let fileUrl = url, let text = try? String(contentsOf: fileUrl) else { return }
        let viewer = PlainTextViewerViewController(text: text, subType: subType)
        try? FileManager.default.removeItem(at: fileUrl)
        self.navigationController.pushViewController(viewer, animated: true)
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
        case let .attachmentList(message, inlineCIDs):
            presentAttachmnetListView(message: message, inlineCIDS: inlineCIDs)
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
        case .addNewFolder:
            presentCreateFolder(type: .folder)
        case .addNewLabel:
            presentCreateFolder(type: .label)
        case .url(let url):
            presentWebView(url: url)
        }
    }

    private func presentCompose(with contact: ContactVO) {
        let board = UIStoryboard.Storyboard.composer.storyboard
        guard let destination = board.instantiateInitialViewController() as? ComposerNavigationController,
              let viewController = destination.viewControllers.first as? ComposeContainerViewController else {
            return
        }
        let viewModel = ContainableComposeViewModel(
            msg: nil,
            action: .newDraft,
            msgService: user.messageService,
            user: user,
            coreDataService: sharedServices.get(by: CoreDataService.self)
        )
        viewModel.addToContacts(contact)

        viewController.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: viewController))
        viewController.set(coordinator: ComposeContainerViewCoordinator(controller: viewController))
        self.viewController?.present(destination, animated: true)
    }

    private func presentCompose(with mailToURL: URL) {
        let board = UIStoryboard.Storyboard.composer.storyboard
        guard let destination = board.instantiateInitialViewController() as? ComposerNavigationController,
              let viewController = destination.viewControllers.first as? ComposeContainerViewController else {
            return
        }
        let viewModel = ContainableComposeViewModel(
            msg: nil,
            action: .newDraft,
            msgService: user.messageService,
            user: user,
            coreDataService: sharedServices.get(by: CoreDataService.self)
        )
        viewModel.parse(mailToURL: mailToURL)

        viewController.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: viewController))
        viewController.set(coordinator: ComposeContainerViewCoordinator(controller: viewController))
        self.viewController?.present(destination, animated: true)
    }

    private func presentCompose(message: Message, action: ComposeMessageAction) {
        let board = UIStoryboard.Storyboard.composer.storyboard
        guard let destination = board.instantiateInitialViewController() as? ComposerNavigationController,
              let viewController = destination.viewControllers.first as? ComposeContainerViewController else {
            return
        }

        let viewModel = ContainableComposeViewModel(
            msg: message,
            action: action,
            msgService: user.messageService,
            user: user,
            coreDataService: sharedServices.get(by: CoreDataService.self)
        )

        viewController.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: viewController))
        viewController.set(coordinator: ComposeContainerViewCoordinator(controller: viewController))
        self.viewController?.present(destination, animated: true)
    }

    private func presentAddContacts(with contact: ContactVO) {
        let board = UIStoryboard.Storyboard.contact.storyboard
        guard let destination = board.instantiateViewController(
                withIdentifier: "UINavigationController-d3P-H0-xNt") as? UINavigationController,
              let viewController = destination.viewControllers.first as? ContactEditViewController else {
            return
        }
        sharedVMService.contactAddViewModel(viewController, user: user, contactVO: contact)
        self.viewController?.present(destination, animated: true)
    }

    private func presentAttachmnetListView(message: Message, inlineCIDS: [String]?) {
        let attachments: [AttachmentInfo] = message.attachments.compactMap { $0 as? Attachment }
            .map(AttachmentNormal.init) + (message.tempAtts ?? [])

        let viewModel = AttachmentListViewModel(attachments: attachments,
                                                user: user,
                                                inlineCIDS: inlineCIDS)
        let viewController = AttachmentListViewController(viewModel: viewModel)
        self.navigationController.pushViewController(viewController, animated: true)
    }

    private func presentWebView(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: nil)
        }
    }
}

extension SingleMessageNavigationAction {

    var composeAction: ComposeMessageAction? {
        switch self {
        case .reply(_):
            return .reply
        case .replyAll:
            return .replyAll
        case .forward:
            return .forward
        default:
            return nil
        }
    }

}
