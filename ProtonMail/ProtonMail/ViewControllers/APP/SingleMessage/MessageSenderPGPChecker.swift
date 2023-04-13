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

import ProtonCore_Crypto
import ProtonCore_Log
import ProtonCore_Services

struct CheckedSenderContact {
    let sender: Sender
    let encryptionIconStatus: EncryptionIconStatus?
}

final class MessageSenderPGPChecker {
    typealias Complete = (CheckedSenderContact?) -> Void

    private let message: MessageEntity
    private let user: UserManager
    private var messageService: MessageDataService { user.messageService }
    private let fetchVerificationKeys: FetchVerificationKeys
    private let dependencies: Dependencies

    init(message: MessageEntity, user: UserManager, dependencies: Dependencies) {
        self.message = message
        self.user = user
        self.fetchVerificationKeys = FetchVerificationKeys(
            dependencies: .init(
                fetchAndVerifyContacts: FetchAndVerifyContacts(user: user),
                fetchEmailsPublicKeys: FetchEmailAddressesPublicKey(dependencies: .init(apiService: user.apiService))
            ),
            userAddresses: []
        )
        self.dependencies = dependencies
    }

    func check(complete: @escaping Complete) {
        guard message.isDetailDownloaded, let sender = try? message.parseSender() else {
            complete(nil)
            return
        }

        if message.isSent {
            checkSentPGP(sender: sender, complete: complete)
            return
        }

        let senderAddress = sender.address

        let entity = message
        verifySenderAddress(senderAddress) { verifyResult in
            let helper = MessageEncryptionIconHelper()
            let iconStatus = helper.receivedStatusIconInfo(entity, verifyResult: verifyResult)
            let checkedContact = CheckedSenderContact(sender: sender, encryptionIconStatus: iconStatus)
            complete(checkedContact)
        }
    }

    private func checkSentPGP(sender: Sender, complete: @escaping Complete) {
        let helper = MessageEncryptionIconHelper()
        let iconStatus = helper.sentStatusIconInfo(message: message)
        let checkedContact = CheckedSenderContact(sender: sender, encryptionIconStatus: iconStatus)
        complete(checkedContact)
    }

    private func verifySenderAddress(_ address: String, completion: @escaping (VerificationResult) -> Void) {
        let messageEntity = message
        obtainVerificationKeys(email: address) { [weak self] keyFetchingResult in
            let verificationResult: VerificationResult

            guard let self = self else { return }
            do {
                let (senderVerified, verificationKeys) = try keyFetchingResult.get()

                let signatureVerificationResult = try self.messageService.messageDecrypter
                    .decryptAndVerify(message: messageEntity, verificationKeys: verificationKeys)
                    .signatureVerificationResult

                verificationResult = VerificationResult(
                    senderVerified: senderVerified,
                    signatureVerificationResult: signatureVerificationResult
                )

            } catch {
                PMLog.error(error)
                verificationResult = VerificationResult(senderVerified: false, signatureVerificationResult: .failure)
            }

            completion(verificationResult)
        }
    }

    private func obtainVerificationKeys(
        email: String,
        completion: @escaping (Swift.Result<(senderVerified: Bool, keys: [ArmoredKey]), Error>) -> Void
    ) {
        fetchVerificationKeys.callbackOn(.main).execute(params: .init(email: email)) { [weak self] result in
            guard let self = self else {
                let error = NSError(domain: "",
                                    code: -1,
                                    localizedDescription: LocalString._error_no_object)
                completion(.failure(error))
                return
            }
            switch result {
            case .success(let (pinnedKeys, keysResponse)):
                if !pinnedKeys.isEmpty {
                    completion(.success((senderVerified: true, keys: pinnedKeys)))
                } else {
                    if let keysResponse = keysResponse,
                       keysResponse.recipientType == .external && !keysResponse.allPublicKeys.isEmpty {
                        completion(.success((senderVerified: false, keys: keysResponse.allPublicKeys)))
                    } else {
                        self.fetchPublicKeysFromAttachments(self.message.attachmentsContainingPublicKey()) { datas in
                            completion(.success((senderVerified: false, keys: datas)))
                        }
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func fetchPublicKeysFromAttachments(
        _ attachments: [AttachmentEntity],
        completion: @escaping (_ publicKeys: [ArmoredKey]) -> Void
    ) {
        var dataToReturn: [ArmoredKey] = []
        let group = DispatchGroup()

        let userKeys = user.toUserKeys()
        for attachment in attachments {
            group.enter()
            dependencies.fetchAttachment.execute(
                params: .init(
                    attachmentID: attachment.id,
                    attachmentKeyPacket: attachment.keyPacket,
                    purpose: .decryptAndEncodePublicKey,
                    userKeys: userKeys
                )
            ) { result in
                defer { group.leave() }
                guard let encodedPublicKey = try? result.get().encoded else { return }
                dataToReturn.append(ArmoredKey(value: encodedPublicKey))
            }
        }

        group.notify(queue: .main) {
            completion(dataToReturn)
        }
    }
}

extension MessageSenderPGPChecker {
    struct Dependencies {
        let fetchAttachment: FetchAttachmentUseCase
    }
}
