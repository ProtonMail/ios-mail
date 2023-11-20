// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import CoreData

extension Contact: DeletableManagedObject {
    static var entityName: String { "Contact" }

    static func makeFetchRequest() -> NSFetchRequest<Contact> {
        NSFetchRequest<Contact>(entityName: entityName)
    }
}

extension ContextLabel: DeletableManagedObject {
    static var entityName: String { "ContextLabel" }

    static func makeFetchRequest() -> NSFetchRequest<ContextLabel> {
        NSFetchRequest<ContextLabel>(entityName: entityName)
    }
}

extension Conversation: DeletableManagedObject {
    static var entityName: String { "Conversation" }

    static func makeFetchRequest() -> NSFetchRequest<Conversation> {
        NSFetchRequest<Conversation>(entityName: entityName)
    }
}

extension ConversationCount: DeletableManagedObject {
    static var entityName: String { "ConversationCount" }

    static func makeFetchRequest() -> NSFetchRequest<ConversationCount> {
        NSFetchRequest<ConversationCount>(entityName: entityName)
    }
}

extension Email: DeletableManagedObject {
    static var entityName: String { "Email" }

    static func makeFetchRequest() -> NSFetchRequest<Email> {
        NSFetchRequest<Email>(entityName: entityName)
    }
}

extension IncomingDefault: DeletableManagedObject {
    static var entityName: String { "IncomingDefault" }

    static func makeFetchRequest() -> NSFetchRequest<IncomingDefault> {
        NSFetchRequest<IncomingDefault>(entityName: entityName)
    }
}

extension Label: DeletableManagedObject {
    static var entityName: String { "Label" }

    static func makeFetchRequest() -> NSFetchRequest<Label> {
        NSFetchRequest<Label>(entityName: entityName)
    }
}

extension LabelUpdate: DeletableManagedObject {
    static var entityName: String { "LabelUpdate" }

    static func makeFetchRequest() -> NSFetchRequest<LabelUpdate> {
        NSFetchRequest<LabelUpdate>(entityName: entityName)
    }
}

extension Message: DeletableManagedObject {
    static var entityName: String { "Message" }

    static func makeFetchRequest() -> NSFetchRequest<Message> {
        NSFetchRequest<Message>(entityName: entityName)
    }
}

extension UserEvent: DeletableManagedObject {
    static var entityName: String { "UserEvent" }

    static func makeFetchRequest() -> NSFetchRequest<UserEvent> {
        NSFetchRequest<UserEvent>(entityName: entityName)
    }
}

protocol DeletableManagedObject: NSManagedObject {
    static var entityName: String { get }
}

extension DeletableManagedObject {
    static func delete(in context: NSManagedObjectContext, basedOn predicate: NSPredicate) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = predicate

        do {
            let objectsToDelete = try context.fetch(fetchRequest)
            for objectToDelete in objectsToDelete {
                context.delete(objectToDelete)
            }
        } catch {
            PMAssertionFailure(error)
        }
    }
}
