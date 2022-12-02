// Copyright (c) 2022 Proton Technologies AG
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
import ProtonCore_Crypto
import ProtonCore_DataModel
@testable import ProtonMail
import ProtonCore_TestingToolkit

final class MockPrepareSendMetadata: NewUseCase<SendMessageMetadata, PrepareSendMetadata.Params> {

    private lazy var dummySendMessageMetadata: SendMessageMetadata = {
        let validKeyPair = try! MailCrypto.generateRandomKeyPair()
        let validKey = Key(keyID: "good", privateKey: validKeyPair.privateKey)
        let userKeys = UserKeys(
            privateKeys: [ArmoredKey(value: validKeyPair.privateKey)],
            addressesPrivateKeys: [validKey],
            mailboxPassphrase: Passphrase(value: validKeyPair.passphrase)
        )
        let keys = SendMessageKeys(senderAddressKey: validKey, userKeys: userKeys)
        return SendMessageMetadata(
            keys: keys,
            messageID: MessageID(rawValue: "dummy_id"),
            timeToExpire: 0,
            recipientSendPreferences: [],
            bodySessionKey: Data(),
            bodySessionAlgorithm: .AES256,
            encryptedBody: Data(),
            decryptedBody: nil,
            attachments: [],
            encodedAttachments: [:],
            password: nil,
            passwordHint: nil
        )
    }()

    private var successResult: Result<SendMessageMetadata, Error> { .success(dummySendMessageMetadata) }
    var failureResult: PrepareSendMessageMetadataError?

    @FuncStub(MockPrepareSendMetadata.executionBlock) var executionBlock
    override func executionBlock(params: PrepareSendMetadata.Params, callback: @escaping Callback) {
        executionBlock(params, callback)
        if let failureResult = failureResult {
            callback(.failure(failureResult))
        } else {
            callback(successResult)
        }
    }
}
