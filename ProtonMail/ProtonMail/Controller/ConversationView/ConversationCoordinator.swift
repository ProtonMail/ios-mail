class ConversationCoordinator {

    weak var viewController: ConversationViewController?

    private let navigationController: UINavigationController
    private let conversation: Conversation

    init(navigationController: UINavigationController, conversation: Conversation) {
        self.navigationController = navigationController
        self.conversation = conversation
    }

    func start() {
        let viewModel = ConversationViewModel(conversation: conversation)
        let viewController = ConversationViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

}
