class ConversationCoordinator {

    weak var viewController: ConversationViewController?

    private let navigationController: UINavigationController
    private let conversation: Conversation
    private let user: UserManager

    init(navigationController: UINavigationController, conversation: Conversation, user: UserManager) {
        self.navigationController = navigationController
        self.conversation = conversation
        self.user = user
    }

    func start() {
        let viewModel = ConversationViewModel(
            conversation: conversation,
            messageService: user.messageService,
            conversationService: user.conversationService,
            contactService: user.contactService
        )
        let viewController = ConversationViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

}
