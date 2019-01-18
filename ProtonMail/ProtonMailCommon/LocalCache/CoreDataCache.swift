//
//  CoreDataCache.swift
//  ProtonMail - Created on 12/18/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

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
        static let CacheVersion : Int = 1 // this is core data cache
        
        case v1 = 1
        var model: String { // hard code model we don't need to cache it.
            switch self {
            case .v1:
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
        }
        sharedMessageDataService.cleanUp()
        self.currentVersion = self.latestVersion
    }
    
    internal func cleanLagacy() {
        
        
    }
    
    func logout() {
        self.versionSaver.set(newValue: nil)
    }
    
}
