class ConversationCoordinator: CoordinatorDismissalObserver {

    weak var viewController: ConversationViewController?

    private let labelId: String
    private let navigationController: UINavigationController
    private let conversation: Conversation
    private let user: UserManager
    var pendingActionAfterDismissal: (() -> Void)?

    init(labelId: String, navigationController: UINavigationController, conversation: Conversation, user: UserManager) {
        self.labelId = labelId
        self.navigationController = navigationController
        self.conversation = conversation
        self.user = user
    }

    func start() {
        let viewModel = ConversationViewModel(
            labelId: labelId,
            conversation: conversation,
            user: user
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
        case .attachmentList(let message):
            presentAttachmnetListView(message: message)
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

    private func presentAttachmnetListView(message: Message) {
        let attachments: [AttachmentInfo] = message.attachments.compactMap { $0 as? Attachment }
            .map(AttachmentNormal.init) + (message.tempAtts ?? [])

        let viewModel = AttachmentListViewModel(attachments: attachments,
                                                user: user)
        let viewController = AttachmentListViewController(viewModel: viewModel)
        self.navigationController.pushViewController(viewController, animated: true)
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
