// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import CoreData

extension Contact: DeletableManagedObject {
    static var entityName: String { "Contact" }
}

extension ContextLabel: DeletableManagedObject {
    static var entityName: String { "ContextLabel" }
}

extension Email: DeletableManagedObject {
    static var entityName: String { "Email" }
}

extension Label: DeletableManagedObject {
    static var entityName: String { "Label" }
}

extension LabelUpdate: DeletableManagedObject {
    static var entityName: String { "LabelUpdate" }
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
