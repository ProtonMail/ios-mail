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
import PromiseKit
import enum ProtonCore_Crypto.Based64
import struct ProtonCore_Crypto.Password
import class ProtonCore_Networking.AuthCredential

typealias PrepareSendRequestUseCase = NewUseCase<SendMessageRequest, PrepareSendRequest.Params>

final class PrepareSendRequest: PrepareSendRequestUseCase {

    override func executionBlock(params: Params, callback: @escaping Callback) {
        do {
            // Using an empty UseCase for fetchAttachment because it is not needed here
            // since we alredy have the attachments at this point in `params.metadata.attachments`.
            let emptyUseCase: FetchAttachmentUseCase = NewUseCase()
            let sendBuilder = MessageSendingRequestBuilder(dependencies: .init(fetchAttachment: emptyUseCase))
            sendBuilder.update(with: params.sendMetadata)

            try prepareMimeFormatIfNeeded(sendBuilder: sendBuilder, params: params)
            try preparePlainTextFormatIfNeeded(sendBuilder: sendBuilder, params: params)
            try prepareAddressPackagesBase(sendBuilder: sendBuilder) { [unowned self] result in
                switch result {
                case .failure(let error):
                    callback(.failure(error))
                case .success(let addressesPackageBase):
                    let request = self.createRequest(
                        sendBuilder: sendBuilder,
                        params: params,
                        addressesPackageBase: addressesPackageBase
                    )
                    callback(.success(request))
                }
            }

        } catch {
            callback(.failure(error))
        }
    }

    private func prepareMimeFormatIfNeeded(sendBuilder: MessageSendingRequestBuilder, params: Params) throws {
        guard params.sendMetadata.recipientSendPreferences.atLeastOneRequiresMimeFormat else { return }
        logInfo(step: .preparingMimeFormat)
        let userKeys = params.sendMetadata.keys.userKeys
        try sendBuilder.prepareMime(
            senderKey: params.sendMetadata.keys.senderAddressKey,
            passphrase: userKeys.mailboxPassphrase,
            userKeys: userKeys.privateKeys,
            keys: userKeys.addressesPrivateKeys
        )
    }

    private func preparePlainTextFormatIfNeeded(sendBuilder: MessageSendingRequestBuilder, params: Params) throws {
        guard params.sendMetadata.recipientSendPreferences.atLeastOneRequiresPlainTextFormat else { return }
        logInfo(step: .preparingPlainTextFormat)
        let userKeys = params.sendMetadata.keys.userKeys
        try sendBuilder.preparePlainText(
            senderKey: params.sendMetadata.keys.senderAddressKey,
            passphrase: userKeys.mailboxPassphrase,
            userKeys: userKeys.privateKeys,
            keys: userKeys.addressesPrivateKeys
        )
    }

    private func prepareAddressPackagesBase(
        sendBuilder: MessageSendingRequestBuilder,
        completion: @escaping (Swift.Result<[AddressPackageBase], Error>) -> Void
    ) throws {
        logInfo(step: .preparingAddressesPackageBase)
        let packageBuilders = try sendBuilder.generatePackageBuilder()
        let promises: [Promise<AddressPackageBase>] = packageBuilders.map({ $0.build() })
        _ = when(resolved: promises)
            .done { results in
                var addressesPackageBase = [AddressPackageBase]()
                var returnedError: Error?
                for result in results {
                    switch result {
                    case .fulfilled(let value):
                        addressesPackageBase.append(value)
                    case .rejected(let error):
                        returnedError = error
                    }
                    if returnedError != nil {
                        break
                    }
                }
                if let error = returnedError {
                    completion(.failure(error))
                } else {
                    completion(.success(addressesPackageBase))
                }
            }
    }

    private func createRequest(
        sendBuilder: MessageSendingRequestBuilder,
        params: Params,
        addressesPackageBase: [AddressPackageBase]
    ) -> SendMessageRequest {
        return SendMessageRequest(
            messageID: params.sendMetadata.messageID.rawValue,
            expirationTime: params.sendMetadata.timeToExpire,
            delaySeconds: params.undoSendDelay,
            messagePackage: addressesPackageBase,
            body: Based64.encode(raw: params.sendMetadata.encryptedBody),
            clearBody: sendBuilder.clearBodyPackage,
            clearAtts: sendBuilder.clearAtts,
            mimeDataPacket: sendBuilder.mimeBody,
            clearMimeBody: sendBuilder.clearMimeBodyPackage,
            plainTextDataPacket: sendBuilder.plainBody,
            clearPlainTextBody: sendBuilder.clearPlainBodyPackage,
            authCredential: params.authCredential,
            deliveryTime: params.scheduleSendDeliveryTime
        )
    }

    private func logInfo(step: SendMessageRequestStep) {
        SystemLogger.log(message: "\(step.rawValue)", category: .sendMessage, isError: false)
    }
}

extension PrepareSendRequest {
    struct Params {
        let authCredential: AuthCredential  // TODO: is this needed? is the authCred this one or the apiService one
        let sendMetadata: SendMessageMetadata
        let scheduleSendDeliveryTime: Date?
        let undoSendDelay: Int
    }
}

/// Enum describing the different steps involved in preparing a SendMessageRequest for logging and debugging purposes.
private enum SendMessageRequestStep: String {
    case preparingMimeFormat
    case preparingPlainTextFormat
    case preparingAddressesPackageBase
}

private extension MessageSendingRequestBuilder {

    func update(with data: SendMessageMetadata) {
        update(bodyData: data.encryptedBody, bodySession: data.bodySessionKey, algo: data.bodySessionAlgorithm)
        if let decryptedBody = data.decryptedBody {
            set(clearBody: decryptedBody)
        }
        for recipient in data.recipientSendPreferences {
            add(email: recipient.emailAddress, sendPreferences: recipient.sendPreferences)
        }
        for attachment in data.attachments {
            add(attachment: attachment)
        }
        add(encodedAttachmentBodies: data.encodedAttachments)
        set(password: Password(value: data.password ?? ""), hint: data.passwordHint)
    }
}
