// Copyright (c) 2022 Proton AG
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
import ProtonCore_DataModel

typealias ResolveSendPreferencesUseCase = NewUseCase<[RecipientSendPreferences], ResolveSendPreferences.Params>

final class ResolveSendPreferences: ResolveSendPreferencesUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        verifiedContacts(for: params.recipientsEmailAddresses) { [unowned self] preContacts in
            let fetchParams = FetchEmailAddressesPublicKey.Params(emails: params.recipientsEmailAddresses)
            dependencies
                .fetchAddressesPublicKeys
                .callbackOn(executionQueue)
                .executionBlock(params: fetchParams) { result in
                    switch result {
                    case .success(let keysDict):
                        let recipientsSendPreferences = params.recipientsEmailAddresses.map { [unowned self] in
                            self.preferences(for: $0, preContacts: preContacts, keysDict: keysDict, params: params)
                        }
                        callback(.success(recipientsSendPreferences))

                    case .failure(let error):
                        callback(.failure(error))
                    }
                }
        }
    }

    /// Returns contacts that match any of the email addresses if these contacts are verified successfully.
    private func verifiedContacts(
        for emailAddresses: [String],
        completion: @escaping ([PreContact]) -> Void
    ) {
        let params = FetchAndVerifyContacts.Parameters(emailAddresses: emailAddresses)
        dependencies
            .fetchVerifiedContacts
            .callbackOn(executionQueue)
            .executionBlock(params: params) { result in
                // FetchVerifiedContacts never returns error. However it follows
                // the NewUseCase.Callback convention that requires to declare a
                // Result as return type.
                let preContacts = (try? result.get()) ?? [PreContact]()
                completion(preContacts)
            }
    }

    private func preferences(
        for email: String,
        preContacts: [PreContact],
        keysDict: [String: KeysResponse],
        params: Params
    ) -> RecipientSendPreferences {
        guard let keysResponse = keysDict[email] else {
            fatalError("Inconsistent state: a KeysResponse should exist if no error is returned")
        }
        let encryptionPreferences = EncryptionPreferencesHelper.getEncryptionPreferences(
            email: email,
            keysResponse: keysResponse,
            userDefaultSign: params.isSenderSignMessagesEnabled,
            userAddresses: params.currentUserEmailAddresses,
            contact: preContacts.find(email: email)
        )
        let sendPreferences = SendPreferencesHelper.getSendPreferences(
            encryptionPreferences: encryptionPreferences,
            isMessageHavingPWD: params.isEmailBeingSentPasswordProtected
        )
        return RecipientSendPreferences(emailAddress: email, sendPreferences: sendPreferences)
    }
}

extension ResolveSendPreferences {
    struct Params {
        /// Email addresses of the recipients of the email that is about to be sent
        let recipientsEmailAddresses: [String]
        /// Indicates whether the message about to be sent is protected by a password
        let isEmailBeingSentPasswordProtected: Bool
        /// Indicates whether the user wants to sign outgoing messages
        let isSenderSignMessagesEnabled: Bool
        /// All the email addresses the authenticated account has
        let currentUserEmailAddresses: [Address]
    }
}

extension ResolveSendPreferences {
    struct Dependencies {
        let fetchVerifiedContacts: FetchAndVerifyContactsUseCase
        let fetchAddressesPublicKeys: FetchEmailAddressesPublicKeyUseCase
    }
}

struct RecipientSendPreferences {
    let emailAddress: String
    let sendPreferences: SendPreferences
}
