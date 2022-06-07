// Copyright (c) 2021 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

protocol TimestampPushPersistable {
    func set(_ value: Any?, forKey defaultName: String)
    func string(forKey defaultName: String) -> String?
}

protocol RegistrationRequiredPersistable {
    func set(_ value: Any?, forKey defaultName: String)
    func add(_ value: String, forKey defaultName: String)
    func remove(_ value: String, forKey defaultName: String)
    func array(forKey defaultName: String) -> [Any]?
}

extension RegistrationRequiredPersistable {
    func remove(_ value: String, forKey defaultName: String) {
        guard var currentArray = array(forKey: defaultName) as? [String] else {
            return
        }
        currentArray.removeAll(where: { $0 == value })
        self.set(currentArray, forKey: defaultName)
    }

    func add(_ value: String, forKey defaultName: String) {
        if var currentArray = array(forKey: defaultName) as? [String] {
            currentArray.append(value)
            self.set(currentArray, forKey: defaultName)
        } else {
            self.set([value], forKey: defaultName)
        }
    }
}

extension UserDefaults: TimestampPushPersistable {}
extension UserDefaults: RegistrationRequiredPersistable {}

struct SharedUserDefaults {

    #if Enterprise
    private static let appGroupUserDefaults = UserDefaults(suiteName: "group.com.protonmail.protonmail")
    #else
    private static let appGroupUserDefaults = UserDefaults(suiteName: "group.ch.protonmail.protonmail")
    #endif

    private enum Key: String {
        case lastReceivedPushTimestamp
        case shouldRegisterAgain
    }

    private let timestampPushPersistable: TimestampPushPersistable?
    private let registrationRequiredPersistable: RegistrationRequiredPersistable?

    init(timestampPushPersistable: TimestampPushPersistable? = appGroupUserDefaults,
         registrationRequiredPersistable: RegistrationRequiredPersistable? = appGroupUserDefaults) {
        self.timestampPushPersistable = timestampPushPersistable
        self.registrationRequiredPersistable = registrationRequiredPersistable
    }

    var lastReceivedPushTimestamp: String {
        timestampPushPersistable?.string(forKey: Key.lastReceivedPushTimestamp.rawValue) ?? "Undefined"
    }

    func setNeedsToRegisterAgain(for UID: String) {
        registrationRequiredPersistable?.add(UID, forKey: Key.shouldRegisterAgain.rawValue)
    }

    func shouldRegisterAgain(for UID: String) -> Bool {
        guard let UIDs = registrationRequiredPersistable?
                .array(forKey: Key.shouldRegisterAgain.rawValue) as? [String] else {
            return false
        }
        return UIDs.contains(UID)
    }

    func didRegister(for UID: String) {
        registrationRequiredPersistable?.remove(UID, forKey: Key.shouldRegisterAgain.rawValue)
    }
}
