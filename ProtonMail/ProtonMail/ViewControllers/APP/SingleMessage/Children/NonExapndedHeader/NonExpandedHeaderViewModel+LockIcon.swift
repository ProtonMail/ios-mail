//
//  NonExpandedHeaderViewModel+LockIcon.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import PromiseKit
import ProtonCore_Log

extension NonExpandedHeaderViewModel {
    func verifySenderAddress(_ address: String, completion: @escaping (VerificationResult) -> Void) {
        obtainVerificationKeys(email: address) { keyFetchingResult in
            let verificationResult: VerificationResult

            do {
                let (senderVerified, verificationKeys) = try keyFetchingResult.get()

                let signatureVerificationResult = try self.user.messageService
                    .messageDecrypter
                    .decrypt(message: self.message, verificationKeys: verificationKeys)
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
        completion: @escaping (Swift.Result<(senderVerified: Bool, keys: [Data]), Error>) -> Void
    ) {
        fetchVerificationKeys.execute(email: email) { result in
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

    func fetchPublicKeysFromAttachments(_ attachments: [AttachmentEntity],
                                        completion: @escaping (_ publicKeys: [Data]) -> Void) {
        var dataToReturn: [Data] = []
        let group = DispatchGroup()

        for attachment in attachments {
            group.enter()
            fetchAttachmentData(attachment: attachment) { fileUrl in
                if let url = fileUrl,
                   let decryptedData = self.decryptAttachment(attachment, fileUrl: url),
                   let decryptedString = String(data: decryptedData, encoding: .utf8),
                   let publicKey = decryptedString.unArmor {
                    dataToReturn.append(publicKey)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(dataToReturn)
        }
    }

    func decryptAttachment(_ attachment: AttachmentEntity, fileUrl: URL) -> Data? {
        guard let keyPacket = attachment.keyPacket,
              let keyPackage: Data = Data(base64Encoded: keyPacket,
                                          options: NSData.Base64DecodingOptions(rawValue: 0)) else {
                  return nil
              }
        guard let data = try? Data(contentsOf: fileUrl) else {
            return nil
        }
        guard let decryptData =
                user.newSchema ?
                try? data.decryptAttachment(keyPackage: keyPackage,
                                            userKeys: user.userPrivateKeys,
                                            passphrase: user.mailboxPassword,
                                            keys: user.addressKeys) :
                    try? data.decryptAttachmentNonOptional(keyPackage,
                                                           passphrase: user.mailboxPassword,
                                                           privKeys: user.addressPrivateKeys) else {
            return nil
        }
        return decryptData
    }

    func fetchAttachmentData(attachment: AttachmentEntity, completion: @escaping (URL?) -> Void) {
        user.messageService.fetchAttachmentForAttachment(attachment,
                                                         downloadTask: nil) { _, fileUrl, error in
            if error != nil {
                completion(nil)
            } else {
                completion(fileUrl)
            }
        }
    }

    func lockIcon(completion: @escaping LockCheckComplete) {
        guard let sender = message.sender else { return }

        if self.message.isSent {
            let helper = MessageEncryptionIconHelper()
            let iconStatus = helper.sentStatusIconInfo(message: self.message)
            sender.encryptionIconStatus = iconStatus
            self.senderContact = sender
            // TODO: refactor the return type later.
            completion(iconStatus?.iconWithColor, 0)
            return
        }

        let senderAddress = sender.email

        verifySenderAddress(senderAddress) { [weak self] verifyResult in
            guard let self = self else { return }
            let helper = MessageEncryptionIconHelper()
            let iconStatus = helper.receivedStatusIconInfo(self.message, verifyResult: verifyResult)
            sender.encryptionIconStatus = iconStatus
            self.senderContact = sender
            // TODO: refactor the return type later.
            completion(iconStatus?.iconWithColor, 0)
        }
    }
}
