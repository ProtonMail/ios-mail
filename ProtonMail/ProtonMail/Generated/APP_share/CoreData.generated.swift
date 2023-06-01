// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import CoreData

extension Contact: DeletableManagedObject {
    static var entityName: String { "Contact" }

    static func makeFetchRequest() -> NSFetchRequest<Contact> {
        NSFetchRequest<Contact>(entityName: entityName)
    }
}

extension Email: DeletableManagedObject {
    static var entityName: String { "Email" }

    static func makeFetchRequest() -> NSFetchRequest<Email> {
        NSFetchRequest<Email>(entityName: entityName)
    }
}

extension LabelUpdate: DeletableManagedObject {
    static var entityName: String { "LabelUpdate" }

    static func makeFetchRequest() -> NSFetchRequest<LabelUpdate> {
        NSFetchRequest<LabelUpdate>(entityName: entityName)
    }
}

protocol DeletableManagedObject: NSManagedObject {
    static var entityName: String { get }
}

extension DeletableManagedObject {
    static func delete(in context: NSManagedObjectContext, basedOn predicate: NSPredicate) {
        deleteWithOptionalPredicate(in: context, predicate: predicate)
    }

    static func deleteAll(in context: NSManagedObjectContext) {
        deleteWithOptionalPredicate(in: context, predicate: nil)
    }

    private static func deleteWithOptionalPredicate(in context: NSManagedObjectContext, predicate: NSPredicate?) {
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
