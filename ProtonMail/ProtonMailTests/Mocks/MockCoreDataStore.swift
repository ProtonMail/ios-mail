// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import CoreData
@testable import ProtonMail

final class MockCoreDataStore {

    /// Returns the same managed object defined in the main app to have the exact same
    /// functionality for tests.
    private static let managedObjectModel: NSManagedObjectModel = {
        CoreDataStore.managedObjectModel
    }()

    /// Returns an in memory persistent container.
    ///
    /// When you attempt to create an SQLite store at /dev/null, SQLite will know that your store should
    /// be persisted in memory rather than on disk, and you’ll still get all of SQLite’s behaviors while you
    /// run your tests against an in-memory store that was set up like this.
    static var testPersistentContainer: NSPersistentContainer {
        let container = NSPersistentContainer(name: "ProtonMailTest.sqlite", managedObjectModel: managedObjectModel)
        let description = NSPersistentStoreDescription()
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores{ (_, _) in }
        return container
    }
}
