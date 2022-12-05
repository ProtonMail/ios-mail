// Copyright (c) 2021 Proton AG
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

import Crypto
import Foundation
import ProtonCore_DataModel
import ProtonCore_Services
import ProtonCore_UIFoundations

struct ContactPGPTypeHelper {
    let internetConnectionStatusProvider: InternetConnectionStatusProvider
    let apiService: APIService
    /// Get from UserManager.UserInfo.sign
    let userSign: Int
    let localContacts: [PreContact]
    let userAddresses: [Address]

    func calculateEncryptionIcon(email: String,
                                 isMessageHavingPWD: Bool,
                                 completion: @escaping (EncryptionIconStatus?, Int?) -> Void) {
        if internetConnectionStatusProvider.currentStatus == .notConnected {
            let result = calculateEncryptionIconLocally(email: email)
            completion(result.0, result.1)
        } else {
            calculateEncryptionIconWithAPI(email: email,
                                           isMessageHavingPwd: isMessageHavingPWD,
                                           completion: completion)
        }
    }

    func calculateEncryptionIconLocally(email: String) -> (EncryptionIconStatus?, Int?) {
        if ProtonMailAddresses.allCases.contains(where: { pmEmail in email.preg_match("@\(pmEmail.rawValue)$") }) {
            return (EncryptionIconStatus(iconColor: .blue,
                                         icon: IconProvider.lockFilled,
                                         text: "End-to-end encrypted"),
                    nil)
        }

        if !email.isValidEmail() {
            return (.init(iconColor: .black,
                          icon: IconProvider.exclamationCircle,
                          text: LocalString._signle_address_invalid_error_content,
                          isInvalid: true,
                          nonExisting: true),
                    PGPTypeErrorCode.recipientNotFound.rawValue)
        }

        return (nil, nil)
    }

    // swiftlint:disable function_body_length
    func calculateEncryptionIconWithAPI(email: String,
                                        isMessageHavingPwd: Bool,
                                        completion: @escaping (EncryptionIconStatus?, Int?) -> Void) {
        let request = UserEmailPubKeys(email: email)
        apiService.exec(route: request, responseObject: KeysResponse()) { result in
            if let error = result.error {
                var errCode = error.responseCode ?? -1
                var errorString = ""
                if errCode == PGPTypeErrorCode.emailAddressFailedValidation.rawValue {
                    errorString = LocalString._signle_address_invalid_error_content
                    completion(.init(iconColor: .black,
                                     icon: IconProvider.exclamationCircle,
                                     text: errorString,
                                     isInvalid: true), errCode)
                    return
                } else if errCode == PGPTypeErrorCode.recipientNotFound.rawValue {
                    errorString = LocalString._recipient_not_found
                    completion(.init(iconColor: .black,
                                     icon: IconProvider.exclamationCircle,
                                     text: errorString,
                                     isInvalid: true,
                                     nonExisting: true), errCode)
                    return
                }
                if !email.isValidEmail() {
                    errCode = PGPTypeErrorCode.recipientNotFound.rawValue
                    completion(.init(iconColor: .black,
                                     icon: IconProvider.exclamationCircle,
                                     text: errorString,
                                     isInvalid: true,
                                     nonExisting: true), errCode)
                } else {
                    completion(.init(iconColor: .black,
                                     icon: IconProvider.exclamationCircle,
                                     text: errorString), errCode)
                }
            } else {
                let contact = localContacts.first(where: { $0.email == email })
                let encryptionPreferences = EncryptionPreferencesHelper
                    .getEncryptionPreferences(email: email,
                                              keysResponse: result,
                                              userDefaultSign: userSign == 1,
                                              userAddresses: userAddresses,
                                              contact: contact)
                let sendPreferences = SendPreferencesHelper
                    .getSendPreferences(encryptionPreferences: encryptionPreferences,
                                        isMessageHavingPWD: isMessageHavingPwd)

                let helper = MessageEncryptionIconHelper()
                let statusIcon = helper.sendStatusIconInfo(email: email, sendPreferences: sendPreferences)
                completion(statusIcon, nil)
            }
        }
    }
}

enum PGPScheme: Int, Equatable {
    case proton = 1
    case encryptedToOutside = 2
    case cleartextInline = 4
    case pgpInline = 8
    case pgpMIME = 16
    case cleartextMIME = 32

    var sendType: SendType {
        switch self {
        case .proton:
            return .proton
        case .encryptedToOutside:
            return .encryptedToOutside
        case .cleartextInline:
            return .cleartextInline
        case .pgpInline:
            return .pgpInline
        case .pgpMIME:
            return .pgpMIME
        case .cleartextMIME:
            return .cleartextMIME
        }
    }
}

enum SendMIMEType: String, Equatable {
    case mime = "multipart/mixed"
    case plainText = "text/plain"
    case html = "text/html"
}
