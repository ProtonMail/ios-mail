//
//  CoreDataCache.swift
//  ProtonMail - Created on 12/18/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
    

import Foundation


/// core data related cache versioning. when clean or rebuild. should also rebuild the counter and queue
class CoreDataCache : Migrate {
    
    /// latest version, pass in from outside. should be constants in global.
    internal var latestVersion: Int
    
    /// concider pass this value in. keep the version tracking in app cache service
    internal var supportedVersions: [Int] = []
    
    /// saver for versioning
    private let versionSaver: Saver<Int>
    
    enum Key {
        static let coreDataVersion = "latest_core_data_cache"
    }
    enum Version : Int {
        static let CacheVersion : Int = 4 // this is core data cache
        
        case v1 = 1
        case v2 = 2
        var model: String { // hard code model we don't need to cache it.
            switch self {
            case .v1, .v2:
                return "ProtonMail"
            }
        }
    }
    
    init() {
        self.latestVersion = Version.CacheVersion
        self.versionSaver = UserDefaultsSaver<Int>(key: Key.coreDataVersion)
    }
    
    var currentVersion: Int {
        get {
            return self.versionSaver.get() ?? 0
        }
        set {
            self.versionSaver.set(newValue: newValue)
        }
    }
    
    var initalRun: Bool {
        get {
            return currentVersion == 0
        }
    }
    
    internal func migrate(from verfrom: Int, to verto: Int) -> Bool {
        return false
    }
    
    /// for the first version we have too many changes. we just rebuild the model and leave the migrate to later versions.
    internal func migrate_0_to_1() {
        // core data
//        let knownVersions = [self.v1_12_0].sorted()
//        let shouldMigrateTo = knownVersions.filter { $0 > self.lastMigratedTo && $0 <= self.current }
//        
//        var previousModel = self.lastMigratedTo.model!
//        var previousUrl = CoreDataService.dbUrl
//        
//        shouldMigrateTo.forEach { nextKnownVersion in
//            nextKnownVersion.migration?()
//            
//            // core data
//            
//            guard lastMigratedTo.modelName != nextKnownVersion.modelName,
//                let nextModel = nextKnownVersion.model else
//            {
//                self.lastMigratedTo = nextKnownVersion
//                return
//            }
//            
//            guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
//                                                                                              at: previousUrl,
//                                                                                              options: nil),
//                !nextModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else
//            {
//                previousModel = nextModel
//                self.lastMigratedTo = nextKnownVersion
//                return
//            }
//            
//            let migrationManager = NSMigrationManager(sourceModel: previousModel, destinationModel: nextModel)
//            guard let mappingModel = NSMappingModel(from: [Bundle.main], forSourceModel: previousModel, destinationModel: nextModel) else {
//                assert(false, "No mapping model found but need one")
//                previousModel = nextModel
//                self.lastMigratedTo = nextKnownVersion
//                return
//            }
//            
//            let destUrl = FileManager.default.temporaryDirectoryUrl.appendingPathComponent(UUID().uuidString, isDirectory: false)
//            try? migrationManager.migrateStore(from: previousUrl,
//                                               sourceType: NSSQLiteStoreType,
//                                               options: nil,
//                                               with: mappingModel,
//                                               toDestinationURL: destUrl,
//                                               destinationType: NSSQLiteStoreType,
//                                               destinationOptions: nil)
//            previousUrl = destUrl
//            previousModel = nextModel
//            self.lastMigratedTo = nextKnownVersion
//        }
        
    }
    
    internal func rebuild(reason: RebuildReason) {
        do {
            try FileManager.default.removeItem(at: CoreDataStore.dbUrl)
        } catch {
            //
        }
        
        if self.currentVersion <= Version.v2.rawValue {
            let userVersion = UserDefaultsSaver<Int>(key: UsersManager.CoderKey.Version)
            userVersion.set(newValue: 0)
            KeychainWrapper.keychain.remove(forKey: "BioProtection" + ".version")
            KeychainWrapper.keychain.remove(forKey: "PinProtection" + ".version")
        }
        
        //TODO:: fix me
        //sharedMessageDataService.cleanUp()
        self.currentVersion = self.latestVersion
    }
    
    internal func cleanLagacy() {
        
        
    }
    
    func logout() {
        self.versionSaver.set(newValue: nil)
    }
    
}
