//
//  TelemetrySettingsService.swift
//  ProtonCore-Settings - Created on 09.11.2022.
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

public protocol TelemetrySettingsServiceProtocol {
    var isTelemetryEnabled: Bool { get }
    func setTelemetryEnabled(_ enabled: Bool)
}

public class TelemetrySettingsService: TelemetrySettingsServiceProtocol {
    private let userDefaults: UserDefaults
    private let telemetryKey = "telemetry.settings.key"

    public private(set) var isTelemetryEnabled: Bool {
        get {
            userDefaults.bool(forKey: telemetryKey)
        }
        set {
            userDefaults.set(newValue, forKey: telemetryKey)
        }
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func setTelemetryEnabled(_ enabled: Bool) {
        self.isTelemetryEnabled = enabled
    }
}
