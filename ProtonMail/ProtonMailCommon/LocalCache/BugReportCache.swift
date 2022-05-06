//
//  BugReportCache.swift
//  Proton Mail - Created on 10/19/16.
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

let cachedBugReport = BugReportCache()
final class BugReportCache: SharedCacheBase {

    fileprivate struct Key {
        static let lastBugReport = "BugReportCache_LastBugReport"
    }

    var cachedBug: String! {
        get {
            return getShared().string(forKey: Key.lastBugReport) ?? ""
        }
        set {
            getShared().setValue(newValue, forKey: Key.lastBugReport)
            getShared().synchronize()
        }
    }

    func clear() {
        getShared().removeObject(forKey: Key.lastBugReport)
        getShared().synchronize()
    }
}
