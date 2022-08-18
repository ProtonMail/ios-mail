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

/// Provide the local store for core data.
final class CoreDataStore {
    static let shared = CoreDataStore()


    // MARK: Static attributes

    private static let databaseName: String = "ProtonMail.sqlite"
    private static let databaseShm = "ProtonMail.sqlite-shm"
    private static let databaseWal = "ProtonMail.sqlite-wal"
    private static var databaseUrl: URL {
        FileManager.default.appGroupsDirectoryURL.appendingPathComponent(CoreDataStore.databaseName)
    }
    private static var databaseShmUrl: URL {
        FileManager.default.appGroupsDirectoryURL.appendingPathComponent(CoreDataStore.databaseShm)
    }
    private static var databaseWalUrl: URL {
        FileManager.default.appGroupsDirectoryURL.appendingPathComponent(CoreDataStore.databaseWal)
    }

    static var managedObjectModel: NSManagedObjectModel = {
        var modelURL = Bundle.main.url(forResource: "ProtonMail", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    static func deleteDataStore() {
        do {
            try FileManager.default.removeItem(at: databaseUrl)
            try FileManager.default.removeItem(at: databaseShmUrl)
            try FileManager.default.removeItem(at: databaseWalUrl)
            SystemLogger.log(message: "Data store deleted", category: .coreData)
        } catch {
            reportPersistentContainerError(message: "Error deleting data store: \(String(describing: error))")
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
        container.loadPersistentStores { (persistentStoreDescription, error) in
            if let error = error {
                let err = String(describing: error)
                CoreDataStore.reportPersistentContainerError(message: "Error loading persistent store: \(err)")
                CoreDataStore.deleteDataStore()
                LastUpdatedStore.clear()
                fatalError("Core Data store failed to load")
            } else {
                url.excludeFromBackup()
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            }
        }
        return container
    }

    private static func reportPersistentContainerError(message: String) {
        SystemLogger.log(message: message, category: .coreData, isError: true)
        Analytics.shared.sendError(.coreDataInitialisation(error: message))
    }
}
