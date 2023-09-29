//
//  ObservabilityEvent.swift
//  ProtonCore-Observability - Created on 16.12.22.
//
//  Copyright (c) 2022 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

/// ObservabilityEvent structure defines the envelope for the event payload
public struct ObservabilityEvent<Payload>: Encodable where Payload: Encodable {

    // API expects the timestamp as int value in seconds
    let timestamp: UInt64 = UInt64(Date().timeIntervalSince1970)
    /// This name must correspond to the schema file name in the json-schema-registry, otherwise it's gonna be rejected
    let name: String
    let version: ObservabilityEventVersion
    let data: Payload

    enum CodingKeys: String, CodingKey {
        case timestamp = "Timestamp"
        case name = "Name"
        case version = "Version"
        case data = "Data"
    }

    public init(name: String, version: ObservabilityEventVersion, data: Payload) {
        self.name = name
        self.version = version
        self.data = data
    }
}

/// Defines the versioning for the event schema
public enum ObservabilityEventVersion: Int, Encodable {
    case v1 = 1
}
