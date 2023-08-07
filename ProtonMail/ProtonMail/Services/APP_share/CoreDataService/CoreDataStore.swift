//
//  CoreDataStoreService.swift
//  Proton Mail - Created on 12/19/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CoreData
import ProtonMailAnalytics
import UIKit

/// Provide the local store for core data.
final class CoreDataStore {
    static let shared = CoreDataStore()

    // MARK: Static attributes

    private static let databaseName: String = "ProtonMail.sqlite"
    private static var databaseUrl: URL {
        FileManager.default.appGroupsDirectoryURL.appendingPathComponent(CoreDataStore.databaseName)
    }

    private init() {
    }

    static var managedObjectModel: NSManagedObjectModel = {
        var modelURL = Bundle.main.url(forResource: "ProtonMail", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    static func deleteDataStore() {
        let dataProtectionStatus = establishDataProtectionStatus()

        let persistentStoreCoordinator = shared.defaultContainer.persistentStoreCoordinator

        SystemLogger.log(
            message: "Deleting \(persistentStoreCoordinator.persistentStores.count) persistent data stores...",
            category: .coreData
        )

        do {
            for persistentStore in persistentStoreCoordinator.persistentStores {
                let url = persistentStoreCoordinator.url(for: persistentStore)

                if #available(iOS 15.0, *) {
                    let storeType = NSPersistentStore.StoreType(rawValue: persistentStore.type)
                    try persistentStoreCoordinator.destroyPersistentStore(at: url, type: storeType)
                } else {
                    try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: persistentStore.type)
                }

                SystemLogger.log(message: "Data store at \(url) deleted", category: .coreData)
            }

            try shared.defaultContainer.loadPersistentStores()
        } catch {
            reportPersistentContainerError(
                message: "Error deleting data store: \(String(describing: error))",
                dataProtectionStatus: dataProtectionStatus
            )
        }
    }

    // MARK: Instance attributes

    lazy var defaultContainer: NSPersistentContainer = {
        SystemLogger.log(message: "Instantiating persistent container", category: .coreData)
        return newPersistentContainer(
            CoreDataStore.managedObjectModel,
            name: CoreDataStore.databaseName,
            url: CoreDataStore.databaseUrl
        )
    }()


    // MARK: Private methods

    private func newPersistentContainer(_ model: NSManagedObjectModel, name: String, url: URL) -> NSPersistentContainer {
        var url = url
        let container = NSPersistentContainer(name: name, managedObjectModel: model)

        let description = NSPersistentStoreDescription(url: url)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]

        let dataProtectionStatus = Self.establishDataProtectionStatus()

        do {
            try container.loadPersistentStores()
            url.excludeFromBackup()
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        } catch {
                let err = String(describing: error)
                CoreDataStore.reportPersistentContainerError(
                    message: "Error loading persistent store: \(err)",
                    dataProtectionStatus: dataProtectionStatus
                )
                userCachedStatus.signOut()
                userCachedStatus.cleanGlobal()
                fatalError("Core Data store failed to load")
        }
        return container
    }

    private static func establishDataProtectionStatus() -> String {
#if APP_EXTENSION
        return "n/a (extension)"
#else
        return UIApplication.shared.isProtectedDataAvailable ? "on": "off"
#endif
    }

    private static func reportPersistentContainerError(message: String, dataProtectionStatus: String) {
        SystemLogger.log(message: message, category: .coreData, isError: true)
        Analytics.shared.sendError(.coreDataInitialisation(error: message, dataProtectionStatus: dataProtectionStatus))
    }
}

extension CoreDataStore: CoreDataMetadata {
    var sqliteFileSize: Measurement<UnitInformationStorage>? {
        do {
            let dbValues = try CoreDataStore.databaseUrl.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
            return Measurement(value: Double(dbValues.totalFileAllocatedSize!), unit: .bytes)
        } catch let error {
            PMAssertionFailure("CoreDataStore databaseSize error: \(error)")
            return nil
        }
    }
}

private extension NSPersistentContainer {
    func loadPersistentStores() throws {
        assert(!persistentStoreDescriptions.contains(where: \.shouldAddStoreAsynchronously))

        var result: Result<Void, Error>!

        loadPersistentStores { _, error in
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(())
            }
        }

        try result.get()
    }
}
