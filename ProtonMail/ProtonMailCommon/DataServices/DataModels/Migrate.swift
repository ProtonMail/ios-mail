//
//  Migrate.swift
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
}
