// Copyright (c) 2024 Proton Technologies AG
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
import XCTest

class BaseMigrationTests: XCTestCase {
    let modelName = "ProtonMail"

    func storeURL(_ version: String) -> URL? {
        let storeURL = URL(fileURLWithPath: "\(NSTemporaryDirectory())\(version).sqlite")
        return storeURL
    }

    func createObjectModel(_ version: String) -> NSManagedObjectModel? {
        let bundle = Bundle.main
        let managedObjectModelURL = bundle.url(forResource: modelName, withExtension: "momd")
        let managedObjectModelURLBundle = Bundle(url: managedObjectModelURL!)
        let managedObjectModelVersionURL = managedObjectModelURLBundle!.url(forResource: version, withExtension: "mom")
        return NSManagedObjectModel(contentsOf: managedObjectModelVersionURL!)
    }

    func createStore(_ version: String) -> NSPersistentStoreCoordinator {
        let model = createObjectModel(version)
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        try! storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                 configurationName: nil,
                                                 at: storeURL(version),
                                                 options: nil)
        return storeCoordinator
    }

    func migrateStore(fromVersionMOM: String, toVersionMOM: String) throws {
        let store = createStore(fromVersionMOM)
        let nextVersionObjectModel = createObjectModel(toVersionMOM)!
        let mappingModel = NSMappingModel(from: [Bundle.main], forSourceModel: store.managedObjectModel, destinationModel: nextVersionObjectModel)!
        let migrationManager = NSMigrationManager(sourceModel: store.managedObjectModel, destinationModel: nextVersionObjectModel)
        do {
            try migrationManager.migrateStore(from: store.persistentStores.first!.url!,
                                              sourceType: NSSQLiteStoreType,
                                              options: nil,
                                              with: mappingModel,
                                              toDestinationURL: storeURL(toVersionMOM)!,
                                              destinationType: NSSQLiteStoreType,
                                              destinationOptions: nil)
        } catch {
            print("Error: \(error)")
            XCTAssertNil(error)
        }
        try FileManager.default.removeItem(at: storeURL(toVersionMOM)!)
        try FileManager.default.removeItem(at: storeURL(fromVersionMOM)!)
    }
}
