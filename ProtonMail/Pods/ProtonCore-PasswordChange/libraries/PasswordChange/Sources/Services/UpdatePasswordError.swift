//
//  UpdatePasswordError.swift
//  ProtonCore-PasswordChange - Created on 20.03.2024.
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

enum UpdatePasswordError: Int, Error {
    case invalidUserName
    case invalidModulusID
    case invalidModulus
    case cantHashPassword
    case cantGenerateVerifier
    case cantGenerateSRPClient
    case keyUpdateFailed

    case `default`
}

extension UpdatePasswordError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidUserName:
            return PCTranslation.errorInvalidUsername.l10n
        case .invalidModulusID:
            return PCTranslation.errorInvalidModulusID.l10n
        case .invalidModulus:
            return PCTranslation.errorInvalidModulus.l10n
        case .cantHashPassword:
            return PCTranslation.errorCantHashPassword.l10n
        case .cantGenerateVerifier:
            return PCTranslation.errorCantGenerateVerifier.l10n
        case .cantGenerateSRPClient:
            return PCTranslation.errorCantGenerateSRPClient.l10n
        case .keyUpdateFailed:
            return PCTranslation.errorKeyUpdateFailed.l10n
        case .default:
            return PCTranslation.errorUpdatePasswordDefault.l10n
        }
    }
}
