//
//  Migrate.swift
//  Proton Mail - Created on 12/18/18.
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

enum RebuildReason {
    case inital // for first time inital value
    case noSupports // doens't support force rebuild the case
}

protocol Migrate: AnyObject {
    /// this is a constant value. change manually every time need to update the cache
    var latestVersion: Int {get}
    /// current cached version. get from the versioning cache.
    var currentVersion: Int {get set}
    /// check if the cache is a inital run, check if the cache version is nil or 0
    var initalRun: Bool {get}

    /// rebuild the case
    ///
    /// - Parameter reason: the rebuild reason
    func rebuild(reason: RebuildReason) throws
}

extension Migrate {

    func run() throws {

        /// run rebuild if it is inital run
        guard initalRun == false else {
            try rebuild(reason: .inital)
            return
        }

        /// version matched to latest. done
        guard self.currentVersion != self.latestVersion else {
            return
        }

        try rebuild(reason: .noSupports)
    }
}
