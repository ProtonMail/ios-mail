class ConversationCoordinator: CoordinatorDismissalObserver {

    weak var viewController: ConversationViewController?

    private let labelId: String
    private let navigationController: UINavigationController
    private let conversation: Conversation
    private let user: UserManager
    var pendingActionAfterDismissal: (() -> Void)?

    init(navigationController: UINavigationController, labelId: String, conversation: Conversation, user: UserManager) {
        self.navigationController = navigationController
        self.labelId = labelId
        self.conversation = conversation
        self.user = user
    }

    func start() {
        let viewModel = ConversationViewModel(
            conversation: conversation,
            labelId: labelId,
            user: user,
            messageService: user.messageService,
            conversationService: user.conversationService,
            contactService: user.contactService
        )
        let viewController = ConversationViewController(coordinator: self,
                                                        viewModel: viewModel)
        self.viewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func navigate(to navigationAction: SingleMessageNavigationAction) {
        switch navigationAction {
        case .reply, .replyAll, .forward:
            presentCompose(action: navigationAction)
        case .addNewFolder:
            presentCreateFolder(type: .folder)
        case .addNewLabel:
            presentCreateFolder(type: .label)
        case .viewHeaders(url: let url):
            presentQuickLookView(url: url, subType: .headers)
        case .viewHTML(url: let url):
            presentQuickLookView(url: url, subType: .html)
        default:
            return
        }
    }

    private func presentCompose(action: SingleMessageNavigationAction) {
        let allowedActions: [SingleMessageNavigationAction] = [.reply, .replyAll, .forward]
        guard allowedActions.contains(action) else {
            return
        }

        guard let newestMessage = viewController?.viewModel.dataSource.newestMessage else {
            return
        }
        let board = UIStoryboard.Storyboard.composer.storyboard
        guard let destination = board.instantiateInitialViewController() as? ComposerNavigationController,
              let viewController = destination.viewControllers.first as? ComposeContainerViewController else {
            return
        }

        let composeAction: ComposeMessageAction
        switch action {
        case .reply:
            composeAction = .reply
        case .replyAll:
            composeAction = .replyAll
        case .forward:
            composeAction = .forward
        default:
            return
        }

        let viewModel = ContainableComposeViewModel(
            msg: newestMessage,
            action: composeAction,
            msgService: user.messageService,
            user: user,
            coreDataService: sharedServices.get(by: CoreDataService.self)
        )

        viewController.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: viewController))
        viewController.set(coordinator: ComposeContainerViewCoordinator(controller: viewController))
        self.viewController?.present(destination, animated: true)
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
}
