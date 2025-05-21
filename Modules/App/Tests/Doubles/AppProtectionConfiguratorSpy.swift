// Copyright (c) 2025 Proton Technologies AG
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

@testable import ProtonMail
import proton_app_uniffi

final class AppProtectionConfiguratorSpy: AppProtectionConfigurator, Sendable {

    var deletePinCodeResultStub = MailSessionDeletePinCodeResult.ok
    var setPinCodeResultStub = MailSessionSetPinCodeResult.ok
    var verifyPinCodeResultStub = MailSessionVerifyPinCodeResult.ok
    var setBiometricsAppProtectionResultStub = MailSessionSetBiometricsAppProtectionResult.ok
    var mailSessionUnsetBiometricsAppProtectionResultStub = MailSessionUnsetBiometricsAppProtectionResult.ok

    private(set) var setBiometricsAppProtectionInvokeCount = 0
    private(set) var unsetBiometricsAppProtectionInvokeCount = 0
    private(set) var invokedDeletePINCode: [[UInt32]] = []
    private(set) var invokedSetPINCode: [[UInt32]] = []
    private(set) var invokedVerifyPINCode: [[UInt32]] = []

    // MARK: - AppProtectionConfigurator

    func deletePinCode(pin: [UInt32]) async -> MailSessionDeletePinCodeResult {
        invokedDeletePINCode.append(pin)

        return deletePinCodeResultStub
    }

    func setPinCode(pin: [UInt32]) async -> MailSessionSetPinCodeResult {
        invokedSetPINCode.append(pin)

        return setPinCodeResultStub
    }

    func setBiometricsAppProtection() async -> MailSessionSetBiometricsAppProtectionResult {
        setBiometricsAppProtectionInvokeCount += 1

        return setBiometricsAppProtectionResultStub
    }

    func unsetBiometricsAppProtection() async -> MailSessionUnsetBiometricsAppProtectionResult {
        unsetBiometricsAppProtectionInvokeCount += 1

        return mailSessionUnsetBiometricsAppProtectionResultStub
    }

    func verifyPinCode(pin: [UInt32]) async -> MailSessionVerifyPinCodeResult {
        invokedVerifyPINCode.append(pin)

        return verifyPinCodeResultStub
    }

}
