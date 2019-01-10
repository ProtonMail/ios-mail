//
//  Migrate.swift
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


enum RebuildReason {
    case inital //for first time inital value
    case noSupports // doens't support force rebuild the case
    case invalidSupport // found the supported version > latest version. add assert in rebuild. could detect it before launch
    case failed(from: Int, to: Int) // failed to migrate, should rebuild and give user error.
}

protocol Migrate : AnyObject {
    /// this is a constant value. change manually every time need to update the cache
    var latestVersion : Int {get}
    /// current cached version. get from the versioning cache.
    var currentVersion : Int {get set}
    /// the legacy cache versions supported. if the latest version not in this list. the end of the supported version will migrate to the latest automatically
    /// And if changed the latest version should put the last version in the list even have nothing to migrate. To handle and process the nono data changes version in the implementation
    var supportedVersions : [Int] {get}
    /// check if the cache is a inital run, check if the cache version is nil or 0
    var initalRun : Bool {get}
    
    /// migrate function call when process migration, sync func
    ///
    /// - Parameters:
    ///   - verfrom: from version
    ///   - verto: migrate to version
    func migrate(from verfrom: Int, to verto: Int) -> Bool
    /// rebuild the case
    ///
    /// - Parameter reason: the rebuild reason
    func rebuild(reason: RebuildReason)
    /// after migrate finished with no errors. this will be called. if sub class received reset then should call this manually
    func cleanLagacy()
    
    func logout()
}

extension Migrate {

    func run() {
        let curr = self.currentVersion
        
        /// run rebuild if it is inital run
        guard initalRun == false else {
            self.rebuild(reason: .inital)
            return
        }
        
        /// version matched to latest. done
        guard self.currentVersion != self.latestVersion else {
            return
        }
        
        /// if not supported version defined. run rebuild
        guard self.supportedVersions.count > 0 else {
            self.rebuild(reason: .noSupports)
            return
        }
        
        /// sort the version to make sure the it is in correct order
        let supported = self.supportedVersions.sorted()
        
        /// check if the latest version
        for v in supported {
            if v > self.latestVersion {
                self.rebuild(reason: .invalidSupport)
                return
            }
        }
        
        /// loop to find the match versions
        var found = false
        for iterator in supported {
            if found {
                if migrate(from: self.currentVersion, to: iterator) {
                    self.currentVersion = iterator
                } else {
                    self.rebuild(reason: RebuildReason.failed(from: self.currentVersion, to: iterator))
                    return
                }
            }
            //found the current version. next iterator will do the migrate
            if found == false && iterator == self.currentVersion {
                found = true
            }
        }
        
        guard found else {
            self.rebuild(reason: .noSupports)
            return
        }
        
        if self.currentVersion != self.latestVersion {
            if migrate(from: self.currentVersion, to: self.latestVersion) {
                self.currentVersion = self.latestVersion
            } else {
                self.rebuild(reason: RebuildReason.failed(from: self.currentVersion, to: self.latestVersion))
                return
            }
        }
        
        //The migration is done
        self.cleanLagacy()
    }

    
    //    // methods
    //
    //    static internal func migrate() {
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
    //
    //        try? NSPersistentStoreCoordinator(managedObjectModel: previousModel).replacePersistentStore(at: CoreDataService.dbUrl,
    //                                                                                                    destinationOptions: nil,
    //                                                                                                    withPersistentStoreFrom: previousUrl,
    //                                                                                                    sourceOptions: nil,
    //                                                                                                    ofType: NSSQLiteStoreType)
    //    }
}
