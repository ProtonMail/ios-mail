// Copyright (c) 2024 Proton Technologies AG
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

import ProtonCoreNetworking
@testable import ProtonMail
import XCTest

final class SettingUpdateRequestTests: XCTestCase {
    func testInit_signature() {
        let signature = String.randomString(20)

        let sut = SettingUpdateRequest.signature(signature)

        XCTAssertEqual(sut.method, .put)
        XCTAssertEqual(sut.path, "/mail/v4/settings/signature")
        XCTAssertEqual(sut.parameters as? [String : String], ["Signature": signature])
    }

    func testInit_linkConfirmation() {
        var sut = SettingUpdateRequest.linkConfirmation(.confirmationAlert)

        XCTAssertEqual(sut.method, .put)
        XCTAssertEqual(sut.path, "/mail/v4/settings/confirmlink")
        XCTAssertEqual(sut.parameters as? [String : Int], ["ConfirmLink": 1])

        sut = SettingUpdateRequest.linkConfirmation(.openAtWill)
        XCTAssertEqual(sut.parameters as? [String : Int], ["ConfirmLink": 0])
    }

    func testInit_enableFolderColor() {
        let isEnable = Bool.random()
        let sut = SettingUpdateRequest.enableFolderColor(isEnable)

        XCTAssertEqual(sut.method, .put)
        XCTAssertEqual(sut.path, "/mail/v4/settings/enablefoldercolor")
        XCTAssertEqual(sut.parameters as? [String : Int], ["EnableFolderColor": isEnable ? 1 : 0])
    }

    func testInit_inheritParentFolderColor() {
        let isEnable = Bool.random()
        let sut = SettingUpdateRequest.inheritParentFolderColor(isEnable)

        XCTAssertEqual(sut.method, .put)
        XCTAssertEqual(sut.path, "/mail/v4/settings/inheritparentfoldercolor")
        XCTAssertEqual(sut.parameters as? [String : Int], ["InheritParentFolderColor": isEnable ? 1 : 0])
    }

    func testInit_notify() {
        let isEnable = Bool.random()
        let sut = SettingUpdateRequest.notify(isEnable)

        XCTAssertEqual(sut.method, .put)
        XCTAssertEqual(sut.path, "/settings/email/notify")
        XCTAssertEqual(sut.parameters as? [String : Int], ["Notify": isEnable ? 1 : 0])
    }

    func testInit_telemetry() {
        let isEnable = Bool.random()
        let sut = SettingUpdateRequest.telemetry(isEnable)

        XCTAssertEqual(sut.method, .put)
        XCTAssertEqual(sut.path, "/core/v4/settings/telemetry")
        XCTAssertEqual(sut.parameters as? [String : Int], ["Telemetry": isEnable ? 1 : 0])
    }

    func testInit_crashReports() {
        let isEnable = Bool.random()
        let sut = SettingUpdateRequest.crashReports(isEnable)

        XCTAssertEqual(sut.method, .put)
        XCTAssertEqual(sut.path, "/core/v4/settings/crashreports")
        XCTAssertEqual(sut.parameters as? [String : Int], ["CrashReports": isEnable ? 1 : 0])
    }

    func testInit_notificationEmail() {
        let email = String.randomString(20)
        let clientEphemeral = String.randomString(20)
        let clientProof = String.randomString(20)
        let srpSession = String.randomString(20)
        let twoFACode = String.randomString(4)
        let payload = UpdateNotificationPayload(
            email: email,
            clientEphemeral: clientEphemeral,
            clientProof: clientProof,
            srpSession: srpSession,
            twoFACode: twoFACode
        )
        let sut = SettingUpdateRequest.notificationEmail(payload)

        XCTAssertEqual(sut.method, .put)
        XCTAssertEqual(sut.path, "/settings/email")
        XCTAssertEqual(
            sut.parameters as? [String : String],
            [
                "ClientEphemeral": clientEphemeral,
                "ClientProof": clientProof,
                "SRPSession": srpSession,
                "Email": email,
                "TwoFactorCode": twoFACode
            ]
        )
    }

    func testInit_loginPassword() throws {
        let clientEphemeral = String.randomString(20)
        let clientProof = String.randomString(20)
        let srpSession = String.randomString(20)
        let modulusID = String.randomString(20)
        let salt = String.randomString(20)
        let verifier = String.randomString(20)
        let twoFACode = String.randomString(4)
        let payload = UpdateLoginPasswordPayload(
            clientEphemeral: clientEphemeral,
            clientProof: clientProof,
            srpSession: srpSession,
            twoFACode: twoFACode,
            modulusID: modulusID,
            salt: salt,
            verifier: verifier
        )
        let sut = SettingUpdateRequest.loginPassword(payload)
        XCTAssertEqual(sut.method, .put)
        XCTAssertEqual(sut.path, "/settings/password")
        XCTAssertEqual(
            sut.parameters?["ClientEphemeral"] as? String,
            clientEphemeral
        )
        XCTAssertEqual(
            sut.parameters?["ClientProof"] as? String,
            clientProof
        )
        XCTAssertEqual(
            sut.parameters?["SRPSession"] as? String,
            srpSession
        )
        XCTAssertEqual(
            sut.parameters?["TwoFactorCode"] as? String,
            twoFACode
        )
        let authDict = try XCTUnwrap(sut.parameters?["Auth"] as? [String: Any])
        XCTAssertEqual(authDict["Version"] as? Int, 4)
        XCTAssertEqual(authDict["ModulusID"] as? String, modulusID)
        XCTAssertEqual(authDict["Salt"] as? String, salt)
        XCTAssertEqual(authDict["Verifier"] as? String, verifier)
    }

    private func isEqual(sut: Request, expected: Request) {
        let result = sut.method == expected.method
            && sut.path == expected.path
        XCTAssertTrue(result)
    }
}
