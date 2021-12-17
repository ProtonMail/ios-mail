// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

protocol TimestampPushPersistable {
    func set(_ value: Any?, forKey defaultName: String)
    func string(forKey defaultName: String) -> String?
}

extension UserDefaults: TimestampPushPersistable {}

struct SharedUserDefaults {

    #if Enterprise
    private static let appGroupUserDefaults = UserDefaults(suiteName: "group.com.protonmail.protonmail")
    #else
    private static let appGroupUserDefaults = UserDefaults(suiteName: "group.ch.protonmail.protonmail")
    #endif

    private enum Key: String {
        case lastReceivedPushTimestamp
    }

    private let timestampPushPersistable: TimestampPushPersistable?

    init(timestampPushPersistable: TimestampPushPersistable? = appGroupUserDefaults) {
        self.timestampPushPersistable = timestampPushPersistable
    }

    func setLastReceivedPush(at timestamp: TimeInterval) {
        let timestampString = String(Int(timestamp))
        timestampPushPersistable?.set(timestampString, forKey: Key.lastReceivedPushTimestamp.rawValue)
    }

    var lastReceivedPushTimestamp: String {
        timestampPushPersistable?.string(forKey: Key.lastReceivedPushTimestamp.rawValue) ?? "Undefined"
    }
}
