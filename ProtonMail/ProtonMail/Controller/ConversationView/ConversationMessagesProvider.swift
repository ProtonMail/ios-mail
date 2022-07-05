import CoreData

class ConversationMessagesProvider: NSObject, NSFetchedResultsControllerDelegate {

    private let conversation: ConversationEntity
    private var conversationUpdate: ((ConversationUpdateType) -> Void)?
    private let contextProvider: CoreDataContextProviderProtocol

    private lazy var fetchedController: NSFetchedResultsController<Message> = {
        let context = contextProvider.mainContext
        let fetchRequest = NSFetchRequest<Message>(entityName: Message.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(
            format: "%K == %@ AND %K.length != 0 AND %K == %@",
            Message.Attributes.conversationID,
            conversation.conversationID.rawValue,
            Message.Attributes.messageID,
            Message.Attributes.isSoftDeleted,
            NSNumber(false)
        )
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Message.time), ascending: true),
            NSSortDescriptor(key: #keyPath(Message.order), ascending: true)
        ]
        return NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
    }()

    init(conversation: ConversationEntity, contextProvider: CoreDataContextProviderProtocol) {
        self.conversation = conversation
        self.contextProvider = contextProvider
    }

    func message(by objectID: NSManagedObjectID) -> Message? {
        return self.fetchedController.managedObjectContext.object(with: objectID) as? Message
    }

    func observe(
        conversationUpdate: @escaping (ConversationUpdateType) -> Void,
        storedMessages: @escaping ([MessageEntity]) -> Void
    ) {
        self.conversationUpdate = conversationUpdate
        fetchedController.delegate = self
        try? fetchedController.performFetch()
        let messageObjects = fetchedController.fetchedObjects ?? []
        storedMessages(messageObjects.map(MessageEntity.init))
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        conversationUpdate?(.willUpdate)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let messages = controller.fetchedObjects?.compactMap { $0 as? Message } ?? []
        conversationUpdate?(.didUpdate(messages: messages.map(MessageEntity.init)))
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
            if let indexPath = newIndexPath {
                conversationUpdate?(.insert(row: indexPath.row))
            }
        case .update:
            if let message = anObject as? Message, let indexPath = indexPath, let newIndexPath = newIndexPath {
                conversationUpdate?(.update(message: MessageEntity(message),
                                            fromRow: indexPath.row,
                                            toRow: newIndexPath.row))
            }
        case .move:
            if let oldIndexPath = indexPath, let newIndexPath = newIndexPath {
                conversationUpdate?(.move(fromRow: oldIndexPath.row, toRow: newIndexPath.row))
            }
        case .delete:
            if let row = indexPath?.row, let message = anObject as? Message {
                conversationUpdate?(.delete(row: row, messageID: MessageID(message.messageID)))
            }
        @unknown default:
            break
        }
    }

}
