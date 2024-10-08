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

    private(set) var container = NSPersistentContainer(name: "ProtonMail")

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

        let persistentStoreCoordinator = shared.container.persistentStoreCoordinator
        let persistentStores = persistentStoreCoordinator.persistentStores

        SystemLogger.log(
            message: "Deleting \(persistentStores.count) persistent data stores...",
            category: .coreData
        )

        do {
            for persistentStore in persistentStores {
                let url = persistentStoreCoordinator.url(for: persistentStore)
                let storeType = NSPersistentStore.StoreType(rawValue: persistentStore.type)
                try persistentStoreCoordinator.destroyPersistentStore(at: url, type: storeType)
                _ = try persistentStoreCoordinator.addPersistentStore(type: storeType, at: url)
                SystemLogger.log(message: "Data store at \(url) deleted", category: .coreData)
            }
        } catch {
            PMAssertionFailure(error)

            reportPersistentContainerError(message: "Error deleting data store: \(String(describing: error))")
        }
    }

    func initialize() throws {
        try initializationQueue.sync {
            guard !initialized else {
                return
            }

            initialized = true

            SystemLogger.log(message: "Instantiating persistent container", category: .coreData)
            var url = self.databaseURL

            performDataMigrationIfNeeded()

            container = NSPersistentContainer(name: "ProtonMail")
            let description = NSPersistentStoreDescription(url: url)
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true

            container.persistentStoreDescriptions = [description]

            do {
                try container.loadPersistentStores()
                try url.excludeFromBackupThrowing()
                container.viewContext.automaticallyMergesChangesFromParent = true
                container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            } catch {
                try? FileManager.default.removeItem(at: databaseURL)
                let err = String(describing: error)
                CoreDataStore.reportPersistentContainerError(message: "Error loading persistent store: \(err)")
                userCachedStatus.cleanAllData()
                throw error
            }
        }
    }

    func performDataMigrationIfNeeded() {
        guard let currentModel = getManagedObjectModel(), isMigrationNeeded(currentModel: currentModel) else {
            return
        }
        SystemLogger.log(message: "Data migration needed. target model version: \(currentModel.versionIdentifiers)", category: .coreDataMigration)
        do {
            try progressivelyMigrate(sourceStoreUrl: databaseURL, type: NSSQLiteStoreType, to: currentModel)
        } catch {
            SystemLogger.log(message: "Error occurred during migration", category: .coreDataMigration)
            SystemLogger.log(error: error, category: .coreDataMigration)
        }
    }

    private func isMigrationNeeded(currentModel: NSManagedObjectModel) -> Bool {
        do {
            var result: Result<Bool, Error>!

            try ObjC.catchException {
                do {
                    let sourceMetaData = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                        type: .sqlite,
                        at: self.databaseURL
                    )

                    let isNeeded = !currentModel.isConfiguration(
                        withName: nil,
                        compatibleWithStoreMetadata: sourceMetaData
                    )

                    result = .success(isNeeded)
                } catch {
                    result = .failure(error)
                }
            }

            return try result.get()
        } catch {
            if !shouldIgnore(error: error) {
                PMAssertionFailure(error)
            }
            return false
        }
    }

    private func shouldIgnore(error: Error) -> Bool {
        #if DEBUG
        guard ProcessInfo.isRunningUnitTests else {
            return false
        }

        let nsError = error as NSError
        return nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoSuchFileError
        #else
        return false
        #endif
    }

    private func getManagedObjectModel() -> NSManagedObjectModel? {
        guard let path = Bundle.main.path(forResource: "ProtonMail", ofType: "momd") else {
            return nil
        }
        return NSManagedObjectModel(contentsOf: URL(fileURLWithPath: path))
    }

    private static func reportPersistentContainerError(message: String) {
        SystemLogger.log(message: message, category: .coreData, isError: true)
        Analytics.shared.sendError(.coreDataInitialisation(error: message))
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

private extension CoreDataStore {
    func progressivelyMigrate(
        sourceStoreUrl: URL,
        type: String,
        to model: NSManagedObjectModel
    ) throws {
        SystemLogger.log(message: "Start migrate", category: .coreDataMigration)
        guard let sourceMetaData = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: type, at: sourceStoreUrl) else {
            SystemLogger.log(message: "Failed to load source meta data", category: .coreDataMigration)
            return
        }

        if model.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetaData) {
            SystemLogger.log(message: "Target model is not compatible with the source meta data.", category: .coreDataMigration)
            return
        }

        guard let sourceModel = getSourceModel(of: sourceMetaData) else {
            SystemLogger.log(message: "Failed to get source model", category: .coreDataMigration)
            return
        }
        let result = try getDestinationModel(sourceModel: sourceModel)
        let destinationModel = result.0
        let destinationMappingModel = result.1
        let destinationModelName = result.2
        let destinationUrl = destinationStoreURL(sourceStoreUrl: sourceStoreUrl, modelName: destinationModelName)

        SystemLogger.log(
            message: "Start to migrate from \(sourceModel.versionIdentifiers) to \(destinationModel.versionIdentifiers)",
            category: .coreDataMigration
        )
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        do {
            try manager.migrateStore(
                from: sourceStoreUrl,
                sourceType: type,
                with: destinationMappingModel,
                toDestinationURL: destinationUrl,
                destinationType: type
            )

            try container.persistentStoreCoordinator.replacePersistentStore(
                at: sourceStoreUrl,
                withPersistentStoreFrom: destinationUrl,
                ofType: type
            )
        } catch {
            SystemLogger.log(message: "Migration failed.", category: .coreDataMigration)
            SystemLogger.log(error: error, category: .coreDataMigration)
            try FileManager.default.removeItem(at: destinationUrl)
            throw error
        }
        try FileManager.default.removeItem(at: destinationUrl)

        // Call it recursively for the multiple stage migration.
        return try progressivelyMigrate(sourceStoreUrl: sourceStoreUrl, type: type, to: model)
    }

    private func getSourceModel(of sourceMetaData: [String: Any]) -> NSManagedObjectModel? {
        return NSManagedObjectModel.mergedModel(from: [.main], forStoreMetadata: sourceMetaData)
    }

    private func getDestinationModel(sourceModel: NSManagedObjectModel) throws -> (NSManagedObjectModel, NSMappingModel, String) {
        let modelPaths = modelPaths()
        guard !modelPaths.isEmpty else {
            throw CoreDataStoreError.noModelFound
        }
        var model: NSManagedObjectModel?
        var mappingModel: NSMappingModel?
        var modelPath: String?

        for path in modelPaths {
            let url = URL(fileURLWithPath: path)
            model = NSManagedObjectModel(contentsOf: url)
            mappingModel = NSMappingModel(from: [.main], forSourceModel: sourceModel, destinationModel: model)
            modelPath = url.deletingPathExtension().lastPathComponent
            if mappingModel != nil {
                break
            }
        }
        guard let mappingModel = mappingModel, let model = model, let modelPath = modelPath else {
            throw CoreDataStoreError.noMappingModelFound
        }
        return (model, mappingModel, modelPath)
    }

    private func modelPaths() -> [String] {
        var results: [String] = []
        let modelPaths = Bundle.main.paths(forResourcesOfType: "momd", inDirectory: nil)
        for modelPath in modelPaths {
            if let resourceSubPath = try? modelPath.asURL().lastPathComponent {
                let paths = Bundle.main.paths(forResourcesOfType: "mom", inDirectory: resourceSubPath)
                results.append(contentsOf: paths)
            }
        }
        let otherModels = Bundle.main.paths(forResourcesOfType: "mom", inDirectory: nil)
        results.append(contentsOf: otherModels)
        return results
    }

    private func destinationStoreURL(sourceStoreUrl: URL, modelName: String) -> URL {
        let storeExtension = sourceStoreUrl.pathExtension
        let storePath = sourceStoreUrl.deletingPathExtension().path
        let result = "\(storePath).\(modelName).\(storeExtension)"
        return URL(fileURLWithPath: result)
    }
}

enum CoreDataStoreError: String, Error {
    case noModelFound
    case noMappingModelFound
}
