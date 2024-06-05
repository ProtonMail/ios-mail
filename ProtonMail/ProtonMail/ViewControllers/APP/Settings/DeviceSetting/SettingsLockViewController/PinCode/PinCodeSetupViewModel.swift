// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCoreKeymaker

protocol PinCodeSetupVMProtocol {
    func activatePinCodeProtection() async -> Bool
    func deactivatePinCodeProtection()
    func go(to step: PinCodeSetupRouter.PinCodeSetUpStep)
    @discardableResult
    func isCorrectCurrentPinCode(_ pinCode: String) async throws -> Bool
    @discardableResult
    func isNewPinCodeMatch(repeatPinCode: String) throws -> Bool
    @discardableResult
    func isValid(pinCode: String) throws -> Bool
    func set(newPinCode: String)
}

extension PinCodeSetupViewModel {
    enum Constants {
        static let minimumLength = 4
        static let maximumLength = 21
    }

    enum Error: LocalizedError {
        case pinTooShort
        case pinTooLong
        case pinDoesNotMatch
        case wrongPinCode

        var errorDescription: String? {
            switch self {
            case .pinTooShort:
                return L10n.PinCodeSetup.pinTooShortError
            case .pinTooLong:
                return L10n.PinCodeSetup.pinTooLongError
            case .pinDoesNotMatch:
                return L10n.PinCodeSetup.pinMustMatch
            case .wrongPinCode:
                // all of translations has `.` in the end
                // Remove it
                var str = LocalString._incorrect_pin
                _ = str.remove(at: str.index(before: str.endIndex))
                return str
            }
        }
    }
}

final class PinCodeSetupViewModel: PinCodeSetupVMProtocol {
    typealias Dependencies = HasKeychain & HasKeyMakerProtocol & HasPinCodeProtection

    private let dependencies: Dependencies
    private let router: PinCodeSetupRouterProtocol
    private var newPinCode = ""

    init(dependencies: Dependencies, router: PinCodeSetupRouterProtocol) {
        self.dependencies = dependencies
        self.router = router
    }

    /// - Returns: is activated
    func activatePinCodeProtection() async -> Bool {
        await dependencies.pinCodeProtection.activate(with: newPinCode)
    }

    func deactivatePinCodeProtection() {
        dependencies.pinCodeProtection.deactivate()
    }

    func go(to step: PinCodeSetupRouter.PinCodeSetUpStep) {
        router.go(to: step, existingVM: self)
    }

    @discardableResult
    func isCorrectCurrentPinCode(_ pinCode: String) async throws -> Bool {
        let protection = PinProtection(pin: pinCode, keychain: dependencies.keychain)
        do {
            try await self.dependencies.keyMaker.verify(protector: protection)
            return true
        } catch {
            throw PinCodeSetupViewModel.Error.wrongPinCode
        }
    }

    @discardableResult
    func isNewPinCodeMatch(repeatPinCode: String) throws -> Bool {
        if repeatPinCode == newPinCode {
            return true
        }
        throw Self.Error.pinDoesNotMatch
    }

    @discardableResult
    func isValid(pinCode: String) throws -> Bool {
        if Constants.minimumLength > pinCode.count {
            throw Self.Error.pinTooShort
        } else if Constants.maximumLength < pinCode.count {
            throw Self.Error.pinTooLong
        } else {
            return true
        }
    }

    func set(newPinCode: String) {
        self.newPinCode = newPinCode
    }
}
