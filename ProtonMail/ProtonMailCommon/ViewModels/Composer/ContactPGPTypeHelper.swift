// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_Services

struct ContactPGPTypeHelper {
    let internetConnectionStatusProvider: InternetConnectionStatusProvider
    let apiService: APIService
    /// Get from UserManager.UserInfo.sign
    let userSign: Int
    let localContacts: [PreContact]
    typealias PGPTypeCheckCompletionBlock = (PGPType, Int?, String?) -> Void

    func calculatePGPType(email: String, isMessageHavingPwd: Bool, completion: @escaping PGPTypeCheckCompletionBlock) {
        internetConnectionStatusProvider.registerConnectionStatus { status in
            if status == .notConnected {
                getPGPTypeLocally(email: email, completion: completion)
            } else {
                getPGPType(email: email,
                           isMessageHavingPwd: isMessageHavingPwd,
                           completion: completion)
            }
        }
    }

    func getPGPTypeLocally(email: String, completion: @escaping PGPTypeCheckCompletionBlock) {
        for pmEmail in ProtonMailAddresses.allCases {
            if email.preg_match("@\(pmEmail.rawValue)$") {
                completion(PGPType.internal_normal, nil, nil)
                return
            }
        }

        if !email.isValidEmail() {
            completion(PGPType.failed_validation, PGPTypeErrorCode.recipientNotFound.rawValue, nil)
            return
        }

        completion(PGPType.none, nil, nil)
    }

    func getPGPType(email: String, isMessageHavingPwd: Bool, completion: @escaping PGPTypeCheckCompletionBlock) {
        let request = UserEmailPubKeys(email: email)
        apiService.exec(route: request) { (result: KeysResponse) in
            if let error = result.error {
                var errCode = error.responseCode ?? -1
                var pgpType = PGPType.none
                var errorString: String?
                defer {
                    completion(pgpType, errCode, errorString)
                }

                if errCode == PGPTypeErrorCode.emailAddressFailedValidation.rawValue {
                    pgpType = .failed_server_validation
                    errorString = LocalString._signle_address_invalid_error_content
                    return
                } else if errCode == PGPTypeErrorCode.recipientNotFound.rawValue {
                    errorString = LocalString._recipient_not_found
                    return
                }

                if !email.isValidEmail() {
                    errCode = PGPTypeErrorCode.recipientNotFound.rawValue
                    pgpType = .failed_validation
                }

            } else {
                let pgpType = calculatePGPTypeWith(email: email,
                                                   keyRes: result,
                                                   contacts: localContacts,
                                                   isMessageHavingPwd: isMessageHavingPwd)
                completion(pgpType, nil, nil)
            }
        }
    }

    func calculatePGPTypeWith(email: String,
                              keyRes: KeysResponse,
                              contacts: [PreContact],
                              isMessageHavingPwd: Bool) -> PGPType {
        if keyRes.recipientType == 1 {
            if let contact = contacts.first,
               contact.email == email,
               contact.firstPgpKey != nil {
                return .internal_trusted_key
            } else {
                return .internal_normal
            }
        } else if let contact = contacts.first,
                  contact.email == email {
            if contact.encrypt,
               contact.firstPgpKey != nil {
                return .pgp_encrypt_trusted_key
            } else if isMessageHavingPwd {
                return .eo
            } else if contact.sign {
                return .pgp_signed
            } else {
                return .none
            }
        } else if isMessageHavingPwd {
            return .eo
        } else if userSign == 1 {
            return .pgp_signed
        } else {
            return .none
        }
    }
}
