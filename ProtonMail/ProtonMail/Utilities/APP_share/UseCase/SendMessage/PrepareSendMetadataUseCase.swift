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
import GoLibs
import class ProtonCore_DataModel.Address
import class ProtonCore_DataModel.Key
import class ProtonCore_DataModel.UserInfo
import ProtonCore_Crypto

typealias PrepareSendMetadataUseCase = NewUseCase<SendMessageMetadata, PrepareSendMetadata.Params>

final class PrepareSendMetadata: PrepareSendMetadataUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        preparePreMetadataInfo(params.messageSendingData, params: params) { [unowned self] result in
            switch result {
            case .failure(let error):
                callback(.failure(error))

            case .success(let data):
                generateSendMessageMetadata(
                    message: data.message,
                    recipients: data.recipientsSendPreferences,
                    senderAddress: data.userData.senderAddress,
                    userKeys: data.toUserKeys(),
                    callback: callback
                )
            }
        }
    }

    /// Returns all the necessary data needed to generate the `SendMessageMetadata` object.
    private func preparePreMetadataInfo(
        _ messageSendingData: MessageSendingData,
        params: Params,
        completion: @escaping (Result<PreMetadataInfo, Error>) -> Void
    ) {
        guard !messageSendingData.message.messageID.rawValue.isEmpty else {
            completion(.failure(PrepareSendMessageMetadataError.messageIdEmptyForURI))
            return
        }
        let userPrivateData: UserSendPrivateData
        if let cachedData = UserSendPrivateData(messageSendingData: messageSendingData) {
            logInfo(step: .usingUserCachedData)
            userPrivateData = cachedData
        } else {
            logInfo(step: .notUsingUserCachedData)
            guard let defaultSenderAddress = messageSendingData.defaultSenderAddress else {
                completion(.failure(PrepareSendMessageMetadataError.noSenderAddressFound))
                return
            }
            userPrivateData = UserSendPrivateData(
                userInfo: dependencies.userDataSource.userInfo,
                authCredential: dependencies.userDataSource.authCredential,
                senderAddress: defaultSenderAddress
            )
        }

        recipientsSendPreferences(params: params, message: messageSendingData.message) { resultRecipients in
            switch resultRecipients {
            case .failure(let error):
                completion(.failure(error))

            case .success(let recipientsSendPreferences):
                let data = PreMetadataInfo(
                    message: messageSendingData.message,
                    recipientsSendPreferences: recipientsSendPreferences,
                    userData: userPrivateData
                )
                completion(.success(data))
            }
        }
    }

    private func recipientsSendPreferences(
        params: Params,
        message: MessageEntity,
        completion: @escaping (Result<[RecipientSendPreferences], Error>) -> Void
    ) {
        logInfo(step: .getRecipientsSendPreferences)
        let recipients = message.recipientsTo + message.recipientsCc + message.recipientsBcc
        let resolverParams = ResolveSendPreferences.Params(
            recipientsEmailAddresses: recipients,
            isEmailBeingSentPasswordProtected: !message.password.isEmpty,
            isSenderSignMessagesEnabled: dependencies.userDataSource.userInfo.sign == 1,
            currentUserEmailAddresses: dependencies.userDataSource.userInfo.userAddresses
        )
        dependencies
            .resolveSendPreferences
            .callbackOn(executionQueue)
            .execute(params: resolverParams, callback: completion)
    }

    private func generateSendMessageMetadata(
        message: MessageEntity,
        recipients: [RecipientSendPreferences],
        senderAddress: Address,
        userKeys: UserKeys,
        callback: @escaping Callback
    ) {
        do {
            guard let senderAddressKey = senderAddress.keys.first else {
                callback(.failure(PrepareSendMessageMetadataError.noSenderAddressKeyFound))
                return
            }
            let splitMessage = try split(encryptedBody: message.body)
            let encryptedBody = try splitMessage.bodyData
            let sessionKey = try sessionKey(from: splitMessage, userKeys: userKeys)

            let decryptedBody: String?
            if recipients.atLeastOneRequiresMimeFormat || recipients.atLeastOneRequiresPlainTextFormat {
                decryptedBody = try decrypt(encryptedBody: message.body, userKeys: userKeys)
            } else {
                decryptedBody = nil
            }

            let preAttachments = createPreAttachments(from: message.attachments, userKeys: userKeys)

            fetchAndEncodeAttachmentsIfNeeded(
                recipients: recipients,
                attachments: message.attachments,
                userKeys: userKeys
            ) { encodedAttachments in
                let sendMessageMetadata = SendMessageMetadata(
                    keys: SendMessageKeys(senderAddressKey: senderAddressKey, userKeys: userKeys),
                    messageID: message.messageID,
                    timeToExpire: message.expirationOffset,
                    recipientSendPreferences: recipients,
                    bodySessionKey: sessionKey.sessionKey,
                    bodySessionAlgorithm: sessionKey.algo,
                    encryptedBody: encryptedBody,
                    decryptedBody: decryptedBody,
                    attachments: preAttachments,
                    encodedAttachments: encodedAttachments,
                    password: message.password,
                    passwordHint: message.passwordHint
                )
                callback(.success(sendMessageMetadata))
            }
        } catch {
            callback(.failure(error))
        }
    }

    private func split(encryptedBody: String) throws -> SplitMessage {
        guard let split = try encryptedBody.split() else {
            throw PrepareSendMessageMetadataError.splitMessageFail
        }
        return split
    }

    private func sessionKey(from splitMessage: SplitMessage, userKeys: UserKeys) throws -> SessionKey {
        guard let session = try splitMessage.keyData.getSessionFromPubKeyPackage(
            userKeys: userKeys.privateKeys,
            passphrase: userKeys.mailboxPassphrase,
            keys: userKeys.addressesPrivateKeys
        ) else {
            throw PrepareSendMessageMetadataError.bodySessionKeyFail
        }
        return session
    }

    private func decrypt(encryptedBody: String, userKeys: UserKeys) throws -> String {
        logInfo(step: .decryptingBody)
        var decryptedBody: String?
        for addressKey in userKeys.addressesPrivateKeys {
            if let decrypted = decrypt(encryptedBody: encryptedBody, withAddressKey: addressKey, userKeys: userKeys) {
                decryptedBody = decrypted
                break
            }
        }
        guard let result = decryptedBody else {
            throw PrepareSendMessageMetadataError.decryptBodyFail
        }
        return result
    }

    private func decrypt(encryptedBody: String, withAddressKey addressKey: Key, userKeys: UserKeys) -> String? {
        do {
            let addressKeyPassphrase = try addressKey.passphrase(
                userPrivateKeys: userKeys.privateKeys,
                mailboxPassphrase: userKeys.mailboxPassphrase
            )
            let decryptedBody = try encryptedBody.decryptMessageWithSingleKeyNonOptional(
                ArmoredKey(value: addressKey.privateKey),
                passphrase: addressKeyPassphrase
            )
            return decryptedBody
        } catch {
            return nil
        }
    }

    private func createPreAttachments(from attachments: [AttachmentEntity], userKeys: UserKeys) -> [PreAttachment] {
        logInfo(step: .preparingAttachments)
        let preAttachments: [PreAttachment] = attachments.compactMap({ attachment in
            guard
                let keyPacket = attachment.keyPacket,
                let data: Data = Data(base64Encoded: keyPacket, options: NSData.Base64DecodingOptions(rawValue: 0)),
                let sessionKey = try? data.getSessionFromPubKeyPackage(
                    userKeys: userKeys.privateKeys,
                    passphrase: userKeys.mailboxPassphrase,
                    keys: userKeys.addressesPrivateKeys
                )
            else {
                let message = "missing data for attachment id \(attachment.id.rawValue)"
                logError(step: .preparingAttachments, error: message)
                return nil
            }
            return PreAttachment(
                id: attachment.id.rawValue,
                session: sessionKey.sessionKey,
                algo: sessionKey.algo,
                att: attachment
            )
        })
        return preAttachments
    }

    private func fetchAndEncodeAttachmentsIfNeeded(
        recipients: [RecipientSendPreferences],
        attachments: [AttachmentEntity],
        userKeys: UserKeys,
        completion: @escaping ([AttachmentID: String]) -> Void
    ) {
        guard recipients.atLeastOneRequiresMimeFormat else {
            completion([:])
            return
        }
        logInfo(step: .mimeEncodingAttachments, info: "fetching \(attachments.count) attachments")
        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "me.proton.mail.PrepareSendMetadata.fetchAndEncodeAttachmentsIfNeeded")
        var encodedAttachments = [AttachmentID: String]()

        for attachment in attachments {
            group.enter()
            dependencies.fetchAttachment.execute(params: .init(
                attachmentID: attachment.id,
                attachmentKeyPacket: attachment.keyPacket,
                purpose: .decryptAndEncodeAttachment,
                userKeys: userKeys
            )) { [weak self] result in
                switch result {
                case .success(let attachmentFile):
                    serialQueue.sync {
                        encodedAttachments[attachment.id] = attachmentFile.encoded
                    }
                case .failure(let error):
                    let errorMessage = "attachmentID = \(attachment.id) | error: \(error)"
                    self?.logError(step: .mimeEncodingAttachments, error: errorMessage)
                }
                group.leave()
            }
        }
        group.notify(queue: executionQueue) {
            completion(encodedAttachments)
        }
    }

    private func logInfo(step: PrepareSendMessageMetadataStep, info: String = "") {
        let extraInfo = info.isEmpty ? "" : ": \(info)"
        SystemLogger.log(message: "\(step.rawValue)\(extraInfo)", category: .sendMessage, isError: false)
    }

    private func logError(step: PrepareSendMessageMetadataStep, error: String) {
        SystemLogger.log(message: "\(step.rawValue) error: \(error)", category: .sendMessage, isError: true)
    }
}

extension PrepareSendMetadata {

    struct Params {
        let messageSendingData: MessageSendingData
    }

    struct Dependencies {
        let userDataSource: UserDataSource
        let resolveSendPreferences: ResolveSendPreferencesUseCase
        let fetchAttachment: FetchAttachmentUseCase
    }
}

/// Enum describing the different steps involved in preparing a message metadata for logging and debugging purposes.
private enum PrepareSendMessageMetadataStep: String {
    case usingUserCachedData
    case notUsingUserCachedData
    case getRecipientsSendPreferences
    case decryptingBody
    case preparingAttachments
    case mimeEncodingAttachments
}

/// Intermediate data object required to prepare `SendMessageMetadata`
private struct PreMetadataInfo {
    let message: MessageEntity
    let recipientsSendPreferences: [RecipientSendPreferences]
    let userData: UserSendPrivateData

    func toUserKeys() -> UserKeys {
        UserKeys(
            privateKeys: userData.userInfo.userPrivateKeys,
            addressesPrivateKeys: userData.userInfo.addressKeys,
            mailboxPassphrase: Passphrase(value: userData.authCredential.mailboxpassword)
        )
    }
}

// MARK: Private helper extensions

private extension SplitMessage {
    var bodyData: Data {
        get throws {
            guard let dataPacket = dataPacket else {
                throw PrepareSendMessageMetadataError.splitMessageDataPacketFail
            }
            return dataPacket
        }
    }

    var keyData: Data {
        get throws {
            guard let keyPacket = keyPacket else {
                throw PrepareSendMessageMetadataError.splitMessageKeyPacketFail
            }
            return keyPacket
        }
    }
}

private extension UserSendPrivateData {
    /// This constructor keeps the user data consistent by
    /// returning `nil` if any cached property is missing.
    init?(messageSendingData: MessageSendingData) {
        guard
            let userInfo = messageSendingData.cachedUserInfo,
            let auth = messageSendingData.cachedAuthCredential,
            let senderAddress = messageSendingData.cachedSenderAddress
        else {
            return nil
        }
        self.userInfo = userInfo
        self.authCredential = auth
        self.senderAddress = senderAddress
    }
}
