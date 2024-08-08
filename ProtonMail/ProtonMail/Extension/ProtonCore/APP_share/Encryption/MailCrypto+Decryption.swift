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

import ProtonCoreCrypto
import ProtonCoreCryptoGoInterface

extension MailCrypto {
    /// The listener object used to communicate with gopenpgp.
    private class CryptoMIMECallbacks: NSObject, CryptoMIMECallbacksProtocol {
        private(set) var attachments: [MIMEAttachmentData] = []
        private(set) var body: String?
        private(set) var errors: [Error] = []
        private(set) var mimeType: String?
        private(set) var signatureVerificationStatus: Int?

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

        func onVerified(_ status: Int) {
            guard self.signatureVerificationStatus == nil else {
                assertionFailure("\(#function) is supposed to be only called once")
                return
            }

            self.signatureVerificationStatus = status
        }
    }

    func decryptMIME(
        encrypted message: String,
        publicKeys: [ArmoredKey],
        decryptionKeyRing: CryptoKeyRing
    ) throws -> MIMEMessageData {
        let pgpMsg = CryptoGo.CryptoPGPMessage(fromArmored: message)
        let (verifierKeyRing, verifyTime) = try prepareVerification(publicKeys: publicKeys)

        let callbacks = CryptoMIMECallbacks()

        decryptionKeyRing.decryptMIMEMessage(
            pgpMsg,
            verifyKey: verifierKeyRing,
            callbacks: callbacks,
            verifyTime: verifyTime
        )

        /*
         Error handling in this method is very lenient:

         - we don't throw the first error in `callbacks.errors` as soon as we can find it
         - instead we only care about it if it's impossible to proceed (no `body` nor `mimeType`)

         The reason for this is we don't want invalid signatures to prevent users from accessing their messages.
         */
        guard let body = callbacks.body, let mimeType = callbacks.mimeType else {
            throw callbacks.errors.first ?? CryptoError.decryptionFailed
        }

        let signatureVerificationResult: SignatureVerificationResult

        if let gopenpgpSignatureStatus = callbacks.signatureVerificationStatus {
            signatureVerificationResult = SignatureVerificationResult(gopenpgpOutput: gopenpgpSignatureStatus)
        } else {
            /*
             callbacks.signatureVerificationStatus is nil if gopenpgp doesn't call its `onVerified` callback.
             This can happen in two cases:

             1. the decryption has failed
             2. we haven't passed any verification keys (`verifyKey` is nil)

             First point is irrelevant, because we won't be reaching this point thanks to the `guard` above.
             Therefore it is safe to assume that the fallback should be `.signatureVerificationSkipped`.
             */
            signatureVerificationResult = .signatureVerificationSkipped
        }

        return MIMEMessageData(
            body: body,
            mimeType: mimeType,
            attachments: callbacks.attachments,
            signatureVerificationResult: signatureVerificationResult
        )
    }

    func decryptNonMIME(
        encrypted message: String,
        publicKeys: [ArmoredKey],
        decryptionKeyRing: CryptoKeyRing
    ) throws -> (String, SignatureVerificationResult) {
        // HelperDecryptExplicitVerify will crash if supplied an empty string
        // this might get patched in the future, making this check unnecessary
        guard !message.isEmpty else {
            return ("", .messageNotSigned)
        }

        let pgpMsg = CryptoGo.CryptoPGPMessage(fromArmored: message)
        let (verifierKeyRing, verifyTime) = try prepareVerification(publicKeys: publicKeys)

        var error: NSError?
        let verifiedMessage = CryptoGo.HelperDecryptExplicitVerify(
            pgpMsg,
            decryptionKeyRing,
            verifierKeyRing,
            verifyTime,
            &error
        )

        if let error = error {
            throw error
        }

        guard let verifiedMessage, let message = verifiedMessage.messageGoCrypto else {
            throw CryptoError.decryptionFailed
        }

        let signatureVerificationResult: SignatureVerificationResult

        if verifierKeyRing == nil {
            signatureVerificationResult = .signatureVerificationSkipped
        } else if let gopenpgpErrorCode = verifiedMessage.signatureVerificationErrorGoCrypto?.status {
            signatureVerificationResult = SignatureVerificationResult(gopenpgpOutput: gopenpgpErrorCode)
        } else {
            signatureVerificationResult = .success
        }

        return (message.getString(), signatureVerificationResult)
    }

    private func prepareVerification(publicKeys: [ArmoredKey]) throws -> (CryptoKeyRing?, Int64) {
        let verifierKeyRing: CryptoKeyRing?
        let verifyTime: Int64

        // the Crypto team has advised against constructing an empty keyring, its behavior might not be well-defined
        if publicKeys.isEmpty {
            verifierKeyRing = nil
            verifyTime = 0
        } else {
            verifierKeyRing = try KeyRingBuilder().buildPublicKeyRing(armoredKeys: publicKeys)
            verifyTime = CryptoGo.CryptoGetUnixTime()
        }

        return (verifierKeyRing, verifyTime)
    }
}
