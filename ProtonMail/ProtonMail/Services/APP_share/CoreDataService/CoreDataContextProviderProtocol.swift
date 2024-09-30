// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreData
import Foundation

protocol CoreDataContextProviderProtocol {
    var mainContext: NSManagedObjectContext { get }

    func enqueueOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void)
    func managedObjectIDForURIRepresentation(_ urlString: String) -> NSManagedObjectID?
    func performOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void)
    func performAndWaitOnRootSavingContext(block: @escaping (_ context: NSManagedObjectContext) -> Void)
    func performAndWaitOnRootSavingContext<T>(block: @escaping (NSManagedObjectContext) throws -> T) throws -> T
    func read<T>(block: (NSManagedObjectContext) throws -> T) rethrows -> T

    @available(*, deprecated, message: "This method violates the runtime contract that the threads do not block, which is required by Swift concurrency. Use `writeAsync` instead.")
    func write<T>(block: @escaping (NSManagedObjectContext) throws -> T) throws -> T

    func writeAsync<T>(block: @escaping @Sendable (NSManagedObjectContext) throws -> T) async throws -> T

    func createFetchedResultsController<T>(
        entityName: String,
        predicate: NSPredicate?,
        sortDescriptors: [NSSortDescriptor],
        fetchBatchSize: Int,
        sectionNameKeyPath: String?
    ) -> NSFetchedResultsController<T>

    func deleteAllData() async
}
