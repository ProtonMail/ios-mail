import CoreData

class ConversationMessagesProvider: NSObject, NSFetchedResultsControllerDelegate {

    private let conversation: Conversation
    private var conversationMessagesHasChanged: (([Message]) -> Void)?

    private lazy var fetchedController: NSFetchedResultsController<NSFetchRequestResult>? = {
        let context = CoreDataService.shared.mainContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@",
            Message.Attributes.conversationID,
            conversation.conversationID
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(Message.time), ascending: true)]
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }()

    init(conversation: Conversation) {
        self.conversation = conversation
    }

    func observe(conversationMessagesHasChanged: @escaping ([Message]) -> Void) {
        self.conversationMessagesHasChanged = conversationMessagesHasChanged
        fetchedController?.delegate = self
        try? fetchedController?.performFetch()
        conversationMessagesHasChanged(conversationMessages)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let messages = controller.fetchedObjects?.compactMap({ $0 as? Message }) else { return }
        conversationMessagesHasChanged?(messages)
    }

    private var conversationMessages: [Message] {
        fetchedController?.fetchedObjects?.compactMap { $0 as? Message } ?? []
    }

}
