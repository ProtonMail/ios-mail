//
//  SentryCoreManager.swift
//  ProtonCore-Log - Created on 17/01/2024.
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Sentry
#if canImport(UIKit)
import UIKit
#endif

public protocol ExternalLogProtocol {
    func capture(errorMessage: String, level: PMLog.LogLevel)
}

public final class SentryCoreManager: ExternalLogProtocol {

    struct Constants {
        static let sentryDSN = "https://2c74eb763791400d9a3c17db8bf57dea@sentry-new.protontech.ch/56"
        static let clientName = "client.name"
        static let device = "device"
        static let deviceFamily = "device.family"
        static let os = "os"
        static let osName = "os.name"
    }

    private var hub: SentryHub!

    public var environment: String

    public init(environment: String) {
        self.environment = environment
        setup()
    }

    func setup() {
        let options = Sentry.Options()
        options.dsn = Constants.sentryDSN
        #if DEBUG
        options.debug = true
        #endif
        options.environment = self.environment

        let scope = Scope()
        let clientName = Bundle.main.bundleIdentifier ?? "Unknown"
        scope.setTag(value: clientName, key: Constants.clientName)
        #if canImport(UIKit)
        scope.setTag(value: UIDevice.current.name, key: Constants.device)
        scope.setTag(value: UIDevice.current.systemName, key: Constants.deviceFamily)
        scope.setTag(value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)", key: Constants.os)
        scope.setTag(value: UIDevice.current.systemName, key: Constants.osName)
        #endif
        #if os(macOS)
        scope.setTag(value: ProcessInfo.processInfo.operatingSystemVersionString, key: Constants.os)
        #endif

        hub = SentryHub(
            client: .init(options: options),
            andScope: scope
        )
    }

    public func capture(errorMessage: String, level: PMLog.LogLevel) {
        let event = Event(level: level.sentryLevel)
        event.message = SentryMessage(formatted: errorMessage)
        hub.capture(event: event)
    }
}

extension PMLog.LogLevel {
    var sentryLevel: SentryLevel {
        switch self {
        case .fatal: return .fatal
        case .error: return .error
        case .warn: return .warning
        case .info: return .info
        case .debug, .trace: return .debug
        }
    }
}
