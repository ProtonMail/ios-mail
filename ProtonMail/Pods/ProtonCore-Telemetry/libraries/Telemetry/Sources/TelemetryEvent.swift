//
//  TelemetryEvent.swift
//  ProtonCore-Telemetry - Created on 26.02.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
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

public protocol TelemetryEventProtocol: Encodable {
    var measurementGroup: String { get }
    var event: String { get }
    var values: [String: Float] { get }
    var dimensions: [String: String] { get }
}

public struct TelemetryEvent: TelemetryEventProtocol {
    public var source: TelemetryEventSource
    public var screen: TelemetryEventScreen
    public var action: TelemetryEventAction

    public var measurementGroup: String
    public var event: String {
        "\(source.rawValue).\(screen.rawValue).\(action.rawValue)"
    }
    public var values: [String: Float]
    public var dimensions: [String: String]

    public init(
        source: TelemetryEventSource,
        screen: TelemetryEventScreen,
        action: TelemetryEventAction,
        measurementGroup: String,
        values: [TelemetryValue] = [],
        dimensions: [TelemetryDimension] = []
    ) {
        self.source = source
        self.screen = screen
        self.action = action
        self.measurementGroup = measurementGroup
        self.values = Dictionary(uniqueKeysWithValues: values.flatMap { $0.value })
        self.dimensions = Dictionary(uniqueKeysWithValues: dimensions.flatMap { $0.value })
    }
}

public enum TelemetryEventSource: String, Encodable {
    case user
    case fe
    case be
}

public enum TelemetryEventScreen: String, Encodable {
    case welcome
    case signin
    case signup
    case signupPassword = "signup_password"
    case hv
    case recoveryMethod = "recovery_method"
}

public enum TelemetryEventAction: String, Encodable {
    case displayed
    case clicked
    case focused
    case auth
    case closed
    case verify
    case validate
    case createUser = "create_user"
}
