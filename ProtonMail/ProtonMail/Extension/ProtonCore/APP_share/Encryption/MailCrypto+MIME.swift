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

import Crypto
import ProtonCore_Crypto

extension MailCrypto {
    /// The listener object used to communicate with gopenpgp.
    private class CryptoMIMECallbacks: NSObject, CryptoMIMECallbacksProtocol {
        private (set) var attachments: [MIMEAttachmentData] = []
        private (set) var body: String?
        private (set) var errors: [Error] = []
        private (set) var mimeType: String?

        func onAttachment(_ headers: String?, data: Data?) {
            guard let headers = headers, let data = data else {
                assertionFailure("\(#function) called with nil parameters")
                return
            }

            let attachment = MIMEAttachmentData(data: data, headersString: headers)
            attachments.append(attachment)
        }

        func onBody(_ body: String?, mimetype: String?) {
            guard self.body == nil else {
                assertionFailure("\(#function) is supposed to be only called once")
                return
            }

            guard let body = body else {
                assertionFailure("\(#function) called with nil parameter")
                return
            }

            self.body = body
            self.mimeType = mimetype
        }

        func onEncryptedHeaders(_ headers: String?) {
            guard let headers = headers, !headers.isEmpty else {
                return
            }

            assertionFailure("\(#function) not implemented yet by the Go library")
        }

        func onError(_ err: Error?) {
            guard let error = err else {
                assertionFailure("\(#function) called with nil parameter")
                return
            }

            errors.append(error)
        }

        func onVerified(_ verified: Int) {
            // to be implemented in https://jira.protontech.ch/browse/MAILIOS-2429
        }
    }

    func decryptMIME(
        encrypted message: String,
        keys: [(privateKey: String, passphrase: String)]
    ) throws -> MIMEMessageData {
        let keyRing = try Crypto().buildPrivateKeyRing(keys: keys)

        var error: NSError?
        let pgpMsg = CryptoNewPGPMessageFromArmored(message, &error)
        if let err = error {
            throw err
        }

        let callbacks = CryptoMIMECallbacks()

        keyRing.decryptMIMEMessage(pgpMsg, verifyKey: nil, callbacks: callbacks, verifyTime: CryptoGetUnixTime())

        if let error = callbacks.errors.first {
            throw error
        }

        guard let body = callbacks.body, let mimeType = callbacks.mimeType else {
            throw CryptoError.decryptionFailed
        }

        return MIMEMessageData(body: body, mimeType: mimeType, attachments: callbacks.attachments)
    }
}
