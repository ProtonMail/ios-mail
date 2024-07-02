//
//  AuthenticationObservability.swift
//  ProtonCore-Observability - Created on 11.06.2024.
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
import ProtonCoreObservability

protocol AuthenticationObservability {
    func observabilityAuth2FAStatusReport(twoFAType: TwoFAType, httpCode: Int?)
}

extension AuthenticationObservability {
    func observabilityAuth2FAStatusReport(twoFAType: TwoFAType, httpCode: Int?) {

        let status: HTTPResponseCodeStatus = switch httpCode {
        case .some(200...299): .http2xx
        case .some(400...499): .http4xx
        case .some(500...599): .http5xx
        default: .unknown
        }

        ObservabilityEnv.report(.loginAuthWith2FATotalEvent(status: status,
                                                            twoFAType: twoFAType))
    }
}
