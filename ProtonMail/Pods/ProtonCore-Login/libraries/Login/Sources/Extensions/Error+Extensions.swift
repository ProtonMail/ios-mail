//
//  Error+Extensions.swift
//  ProtonCore-Login - Created on 11/11/2020.
//
//  Copyright (c) 2019 Proton Technologies AG
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
import ProtonCore_Networking

extension LoginError {
    public var description: String {
        switch self {
        case let .generic(message: message, _, _):
            return message
        case let .invalidCredentials(message: message):
            return message
        case let .invalid2FACode(message):
            return message
        case let .invalidAccessToken(message):
            return message
        case .invalidSecondPassword:
            return ""
        case .invalidState:
            return ""
        case .missingKeys:
            return ""
        case .needsFirstTimePasswordChange:
            return ""
        case .emailAddressAlreadyUsed:
            return ""
        }
    }
}

public extension AuthErrors {

    func asLoginError(in2FAContext: Bool = false) -> LoginError {
        switch self {
        case .networkingError(let responseError):
            if responseError.httpCode == 401 {
                return .invalidAccessToken(message: responseError.localizedDescription)
            }
            if responseError.responseCode == 8002 {
                return in2FAContext
                    ? .invalid2FACode(message: responseError.localizedDescription)
                    : .invalidCredentials(message: responseError.localizedDescription)
            }
            return .generic(message: responseError.networkResponseMessageForTheUser,
                            code: codeInNetworking,
                            originalError: responseError)
        default:
            return .generic(message: userFacingMessageInNetworking,
                            code: codeInNetworking,
                            originalError: self)
        }
    }

    func asAvailabilityError() -> AvailabilityError {
        switch self {
        case .networkingError(let responseError) where responseError.responseCode == 12106:
            return .notAvailable(message: localizedDescription)
        default:
            return .generic(message: userFacingMessageInNetworking, code: codeInNetworking, originalError: self)
        }
    }

    func asSetUsernameError() -> SetUsernameError {
        switch self {
        case .networkingError(let responseError) where responseError.responseCode == 2011:
            return .alreadySet(message: localizedDescription)
        default:
            return .generic(message: userFacingMessageInNetworking, code: codeInNetworking, originalError: self)
        }
    }

    func asCreateAddressKeysError() -> CreateAddressKeysError {
        .generic(message: userFacingMessageInNetworking, code: codeInNetworking, originalError: self)
    }
}
