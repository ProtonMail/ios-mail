//
//  Created on 7/5/24.
//
//  Copyright (c) 2024 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCoreObservability

protocol PasswordChangeObservability {
    func observabilityPasswordChangeSuccess(
        mode: PasswordChangeModule.PasswordChangeMode,
        twoFAMode: TwoFactorMode
    )
    func observabilityPasswordChangeError(
        mode: PasswordChangeModule.PasswordChangeMode,
        error: Error,
        twoFAMode: TwoFactorMode
    )
}

extension PasswordChangeObservability {

    func observabilityPasswordChangeSuccess(
        mode: PasswordChangeModule.PasswordChangeMode,
        twoFAMode: TwoFactorMode
    ) {
        switch mode {
        case .singlePassword, .loginPassword:
            ObservabilityEnv.report(.updateLoginPassword(
                status: .http200,
                twoFactorMode: twoFAMode
            ))
        case .mailboxPassword:
            ObservabilityEnv.report(.updateMailboxPassword(
                status: .http200,
                twoFactorMode: twoFAMode
            ))
        }
    }

    func observabilityPasswordChangeError(
        mode: PasswordChangeModule.PasswordChangeMode,
        error: Error,
        twoFAMode: TwoFactorMode
    ) {
        let status: PasswordChangeHTTPResponseCodeStatus
        switch error.responseCode {
        case .some(200): status = .http200
        case .some(201...299): status = .http2xx
        case .some(401): status = .http401
        case .some(400...499): status = .http4xx
        case .some(500...599): status = .http5xx
        case .some(8002): status = .invalidCredentials
        case nil where error is UpdatePasswordError:
            status = (error as? UpdatePasswordError)?.passwordChangeObservabilityStatus ?? .unknown
        default: status = .unknown
        }
        switch mode {
        case .singlePassword, .loginPassword:
            ObservabilityEnv.report(.updateLoginPassword(
                status: status,
                twoFactorMode: twoFAMode
            ))
        case .mailboxPassword:
            ObservabilityEnv.report(.updateMailboxPassword(
                status: status,
                twoFactorMode: twoFAMode
            ))
        }
    }
}
