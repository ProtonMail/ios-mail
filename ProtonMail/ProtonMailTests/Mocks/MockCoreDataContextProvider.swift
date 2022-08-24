// Copyright (c) 2021 Proton AG
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
@testable import ProtonMail

class MockCoreDataContextProvider: CoreDataContextProviderProtocol {
    let coreDataService = CoreDataService(container: MockCoreDataStore.testPersistentContainer)

    var mainContext: NSManagedObjectContext {
        coreDataService.mainContext
    }

    var rootSavingContext: NSManagedObjectContext {
        /*
         The unit tests run on the main thread.

         To prevent the ConcurrencyDebug flag from triggering a crash we should either:
         - not access `rootSavingContext` on the main thread
         - wrap every access to every Core Data object in `rootSavingContext.performAndWait`

         For now it's the first approach.
         */
        mainContext
    }

    func makeComposerMainContext() -> NSManagedObjectContext {
        return coreDataService.makeComposerMainContext()
    }

    func enqueue(context: NSManagedObjectContext,
                 block: @escaping (_ context: NSManagedObjectContext) -> Void) {
        let context = context
        context.performAndWait {
            block(context)
        }
    }

    func managedObjectIDForURIRepresentation(_ urlString: String) -> NSManagedObjectID? {
        return nil
    }
}
