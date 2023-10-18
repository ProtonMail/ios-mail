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

import CoreData
import ProtonMailAnalytics
import UIKit

final class CoreDataStore {
    static let shared = CoreDataStore()

    let container = NSPersistentContainer(name: "ProtonMail")

    private var initialized = false
    private let initializationQueue = DispatchQueue(label: "ch.protonmail.CoreDataStore.initialization")

    private let databaseURL = FileManager.default.appGroupsDirectoryURL.appendingPathComponent("ProtonMail.sqlite")

    private init() {
    }

    static func deleteDataStore() {
        do {
            try shared.initialize()
        } catch {
            PMAssertionFailure(error)
        }

        let dataProtectionStatus = establishDataProtectionStatus()

        let persistentStoreCoordinator = shared.container.persistentStoreCoordinator
        let persistentStores = persistentStoreCoordinator.persistentStores

        SystemLogger.log(
            message: "Deleting \(persistentStores.count) persistent data stores...",
            category: .coreData
        )

        do {
            for persistentStore in persistentStores {
                let url = persistentStoreCoordinator.url(for: persistentStore)

                if #available(iOS 15.0, *) {
                    let storeType = NSPersistentStore.StoreType(rawValue: persistentStore.type)
                    try persistentStoreCoordinator.destroyPersistentStore(at: url, type: storeType)
                    _ = try persistentStoreCoordinator.addPersistentStore(type: storeType, at: url)
                } else {
                    let storeType = persistentStore.type
                    try persistentStoreCoordinator.destroyPersistentStore(at: url, ofType: storeType)
                    _ = try persistentStoreCoordinator.addPersistentStore(
                        ofType: storeType,
                        configurationName: nil,
                        at: url
                    )
                }

                SystemLogger.log(message: "Data store at \(url) deleted", category: .coreData)
            }
        } catch {
            PMAssertionFailure(error)

            reportPersistentContainerError(
                message: "Error deleting data store: \(String(describing: error))",
                dataProtectionStatus: dataProtectionStatus
            )
        }
    }

    func initialize() throws {
        try initializationQueue.sync {
            guard !initialized else {
                return
            }

            initialized = true

            SystemLogger.log(message: "Instantiating persistent container", category: .coreData)
            var url = databaseURL

            let description = NSPersistentStoreDescription(url: url)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            container.persistentStoreDescriptions = [description]

            let dataProtectionStatus = Self.establishDataProtectionStatus()

            do {
                try container.loadPersistentStores()
                try url.excludeFromBackupThrowing()
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            } catch {
                try? FileManager.default.removeItem(at: databaseURL)
                let err = String(describing: error)
                CoreDataStore.reportPersistentContainerError(
                    message: "Error loading persistent store: \(err)",
                    dataProtectionStatus: dataProtectionStatus
                )
                userCachedStatus.signOut()
                userCachedStatus.cleanGlobal()
                throw error
            }
        }
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
