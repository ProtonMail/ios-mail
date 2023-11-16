//
//  FeatureFlags.swift
//  ProtonCore-FeatureFlags - Created on 29.09.23.
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

public struct FeatureFlags: Hashable, Codable, Sendable {
    public let flags: [FeatureFlag]

    public init(flags: [FeatureFlag]) {
        self.flags = flags
    }

    public static var `default`: FeatureFlags {
        FeatureFlags(flags: [])
    }

    public var isEmpty: Bool {
        flags.isEmpty
    }

    public func isEnabled(for key: any FeatureFlagTypeProtocol) -> Bool {
        flags.first { $0.name == key.rawValue }?.enabled ?? false
    }

    func getFlag(for key: any FeatureFlagTypeProtocol) -> FeatureFlag? {
        flags.first { $0.name == key.rawValue }
    }
}
