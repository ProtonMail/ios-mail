//
//  PasswordValidation.swift
//  ProtonCore-Utilities - Created on 4/19/21.
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

public enum PasswordValidationError: Error {
    case passwordEmpty
    case passwordShouldHaveAtLeastEightCharacters
    case passwordNotEqual
}

public struct PasswordRestrictions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let notEmpty                   = PasswordRestrictions(rawValue: 1 << 0)
    public static let atLeastEightCharactersLong = PasswordRestrictions(rawValue: 1 << 1)

    public static let `default`: PasswordRestrictions = [.atLeastEightCharactersLong, .notEmpty]

    public func failedRestrictions(for password: String) -> PasswordRestrictions {
        var failedRestrictions: PasswordRestrictions = []
        if contains(.notEmpty) && password.isEmpty {
            failedRestrictions.insert(.notEmpty)
        }
        if contains(.atLeastEightCharactersLong) && password.count < 8 {
            failedRestrictions.insert(.atLeastEightCharactersLong)
        }
        return failedRestrictions
    }
}

public protocol PasswordValidator {
    func validate(for restrictions: PasswordRestrictions, password: String, confirmPassword: String) throws
}

public extension PasswordValidator {
    func validate(for restrictions: PasswordRestrictions, password: String, confirmPassword: String) throws {
        let passwordFailedRestrictions = restrictions.failedRestrictions(for: password)
        let confirmPasswordFailedRestrictions = restrictions.failedRestrictions(for: confirmPassword)

        if passwordFailedRestrictions.contains(.notEmpty) && confirmPasswordFailedRestrictions.contains(.notEmpty) {
            throw PasswordValidationError.passwordEmpty
        }

        if passwordFailedRestrictions.contains(.atLeastEightCharactersLong)
            && confirmPasswordFailedRestrictions.contains(.notEmpty) {
            throw PasswordValidationError.passwordShouldHaveAtLeastEightCharacters
        }

        guard password == confirmPassword else {
            throw PasswordValidationError.passwordNotEqual
        }

        if passwordFailedRestrictions.contains(.atLeastEightCharactersLong)
            && confirmPasswordFailedRestrictions.contains(.atLeastEightCharactersLong) {
            throw PasswordValidationError.passwordShouldHaveAtLeastEightCharacters
        }
    }
}
