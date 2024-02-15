//
//  UserDefaults+Decodable.swift
//  ProtonCore-Utilities - Created on 21.11.23.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

public final class UserDefaultsObservationCenter {

    private class Observation {
        weak var observer: AnyObject?
        let keyValueObservation: NSKeyValueObservation

        init(observer: AnyObject, keyValueObservation: NSKeyValueObservation) {
            self.observer = observer
            self.keyValueObservation = keyValueObservation
        }
    }

    private let store: UserDefaults
    private var observations = [Observation]()

    public init(userDefaults: UserDefaults) {
        self.store = userDefaults
    }

    deinit {
        observations.forEach { observation in
            observation.keyValueObservation.invalidate()
        }
    }

    public func addObserver<Value>(_ observer: AnyObject, of key: KeyPath<UserDefaults, Value>, using handler: @escaping (Value?) -> Void) {
        let keyValueObservation = store.observe(key, options: [.new], changeHandler: { (_, change) in
            handler(change.newValue)
        })
        let observation = Observation(observer: observer, keyValueObservation: keyValueObservation)
        self.observations.append(observation)
    }

    public func removeObserver(_ observer: AnyObject) {
        self.observations = observations.filter { observation in
            // Clear up any deallocated observers as well as this observer
            if observation.observer == nil || observer === observation.observer {
                observation.keyValueObservation.invalidate()
                return false
            }

            return true
        }
    }
}
