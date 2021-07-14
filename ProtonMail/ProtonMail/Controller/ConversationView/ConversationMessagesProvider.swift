import CoreData

class ConversationMessagesProvider: NSObject, NSFetchedResultsControllerDelegate {

    private let conversation: Conversation
    private var conversationUpdate: ((ConversationUpdateType) -> Void)?

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

    func observe(
        conversationUpdate: @escaping (ConversationUpdateType) -> Void,
        storedMessages: @escaping ([Message]) -> Void
    ) {
        self.conversationUpdate = conversationUpdate
        fetchedController?.delegate = self
        try? fetchedController?.performFetch()
        storedMessages((fetchedController?.fetchedObjects as? [Message]) ?? [])
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        conversationUpdate?(.willUpdate)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        conversationUpdate?(.didUpdate)
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            if let message = anObject as? Message, let indexPath = newIndexPath {
                conversationUpdate?(.insert(message: message, row: indexPath.row))
            }
        case .update:
            if let message = anObject as? Message, let indexPath = indexPath, let newIndexPath = newIndexPath {
                conversationUpdate?(.update(message: message, fromRow: indexPath.row, toRow: newIndexPath.row))
            }
        case .move:
            if let oldIndexPath = indexPath, let newIndexPath = newIndexPath {
                conversationUpdate?(.move(fromRow: oldIndexPath.row, toRow: newIndexPath.row))
            }
        case .delete:
            if let message = anObject as? Message {
                conversationUpdate?(.delete(message: message))
            }
        @unknown default:
            break
        }
    }

}
