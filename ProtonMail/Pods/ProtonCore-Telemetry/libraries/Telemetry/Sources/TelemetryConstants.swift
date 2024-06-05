//
//  TelemetryConstant.swift
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

public enum TelemetryMeasurementGroup: String {
    case signUp = "account.any.signup"
}

public enum TelemetryFlow: String {
    case signUpFull = "iOS_signup_full"
}

public enum TelemetryValue {
    case timestamp(Float)
    case httpCode(Int)

    public var value: [String: Float] {
        switch self {
        case .timestamp(let value):
            return ["timestamp": value]
        case .httpCode(let value):
            return ["http_code": Float(value)]
        }
    }
}

public enum TelemetryDimension {
    case flow(String)
    case accountType(String)
    case item(String)
    case result(String)
    case hostType(String)

    public var value: [String: String] {
        switch self {
        case .flow(let value):
            return ["flow": value]
        case .accountType(let value):
            return ["account_type": value]
        case .item(let value):
            return ["item": value]
        case .result(let value):
            return ["result": value]
        case .hostType(let value):
            return ["host_type": value]
        }
    }
}
