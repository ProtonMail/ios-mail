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

import ProtonCoreDataModel
import ProtonCoreNetworking

enum SettingUpdateRequest: Request {
    static let settingApiPath = "/\(Constants.App.API_PREFIXED)/settings"

    case signature(String)
    case linkConfirmation(LinkOpeningMode)
    case enableFolderColor(Bool)
    case inheritParentFolderColor(Bool)
    case notify(Bool)
    case telemetry(Bool)
    case crashReports(Bool)
    case notificationEmail(UpdateNotificationPayload)
    case loginPassword(UpdateLoginPasswordPayload)

    var route: String {
        switch self {
        case .signature:
            return "/signature"
        case .linkConfirmation:
            return "/confirmlink"
        case .enableFolderColor:
            return "/enablefoldercolor"
        case .inheritParentFolderColor:
            return "/inheritparentfoldercolor"
        case .notify:
            return "/email/notify"
        case .telemetry:
            return "/telemetry"
        case .crashReports:
            return "/crashreports"
        case .notificationEmail:
            return "/email"
        case .loginPassword:
            return "/password"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .signature(let value):
            return ["Signature": value]
        case .linkConfirmation(let status):
            return ["ConfirmLink": NSNumber(value: status == .confirmationAlert).intValue]
        case .enableFolderColor(let isEnable):
            return ["EnableFolderColor": isEnable.intValue]
        case .inheritParentFolderColor(let isEnable):
            return ["InheritParentFolderColor": isEnable.intValue]
        case .notify(let isEnable):
            return ["Notify": isEnable.intValue]
        case .telemetry(let isEnable):
            return ["Telemetry": isEnable.intValue]
        case .crashReports(let isEnable):
            return ["CrashReports": isEnable.intValue]
        case .notificationEmail(let payload):
            var result: [String: Any] = [
                "ClientEphemeral": payload.clientEphemeral,
                "ClientProof": payload.clientProof,
                "SRPSession": payload.srpSession,
                "Email": payload.email
            ]
            if let code = payload.twoFACode {
                result["TwoFactorCode"] = code
            }
            return result
        case .loginPassword(let payload):
            let auth: [String: Any] = [
                "Version": 4,
                "ModulusID": payload.modulusID,
                "Salt": payload.salt,
                "Verifier": payload.verifier
            ]
            var result: [String: Any] = [
                "ClientEphemeral": payload.clientEphemeral,
                "ClientProof": payload.clientProof,
                "SRPSession": payload.srpSession,
                "Auth": auth
            ]
            if let code = payload.twoFACode {
                result["TwoFactorCode"] = code
            }
            return result
        }
    }

    var method: HTTPMethod { .put }
    var path: String {
        switch self {
        case .notificationEmail, .notify, .loginPassword:
            return "/settings" + route
        case .telemetry, .crashReports:
            return "/core/v4/settings" + route
        default:
            return Self.settingApiPath + route
        }
    }
}

struct UpdateNotificationPayload {
    let email: String
    let clientEphemeral: String
    let clientProof: String
    let srpSession: String
    let twoFACode: String?
}

struct UpdateLoginPasswordPayload {
    let clientEphemeral: String
    let clientProof: String
    let srpSession: String
    let twoFACode: String?
    let modulusID: String
    let salt: String
    let verifier: String
}

extension Bool {
    var intValue: Int {
        self ? 1 : 0
    }
}
