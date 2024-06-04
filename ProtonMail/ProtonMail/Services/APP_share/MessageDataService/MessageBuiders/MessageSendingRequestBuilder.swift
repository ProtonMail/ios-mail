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

import CoreData
import PromiseKit
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreHash
import ProtonCoreServices

/// A sending message request builder
///
/// You can create new builder like:
/// ````
///     let builder = MessageSendingRequestBuilder()
/// ````
///

final class MessageSendingRequestBuilder {
    enum BuilderError: Error {
        case MIMEDataNotPrepared
        case plainTextDataNotPrepared
        case packagesFailedToCreate
        case sessionKeyFailedToCreate
    }

    private(set) var bodySessionKey: Data?
    private(set) var bodySessionAlgo: Algorithm?

    private(set) var addressSendPreferences: [String: SendPreferences] = [:]

    private(set) var preAttachments = [PreAttachment]()
    private(set) var password: Passphrase?
    private(set) var hint: String?

    private(set) var mimeSessionKey: Data?
    private(set) var mimeSessionAlgo: Algorithm?
    private(set) var mimeDataPackage: String?

    private(set) var clearBody: String?

    private(set) var plainTextSessionKey: Data?
    private(set) var plainTextSessionAlgo: Algorithm?
    private(set) var plainTextDataPackage: String?

    // [AttachmentID: base64 attachment body]
    private var attachmentBodys: [String: Base64String] = [:]

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func update(bodySession: Data, algo: Algorithm) {
        self.bodySessionKey = bodySession
        self.bodySessionAlgo = algo
    }

    func set(password: Passphrase, hint: String?) {
        self.password = password
        self.hint = hint
    }

    func set(clearBody: String) {
        self.clearBody = clearBody
    }

    func add(email: String, sendPreferences: SendPreferences) {
        self.addressSendPreferences[email] = sendPreferences
    }

    func add(attachment: PreAttachment) {
        self.preAttachments.append(attachment)
    }

    func add(encodedAttachmentBodies: [AttachmentID: Base64String]) {
        self.attachmentBodys = Dictionary(
            uniqueKeysWithValues: encodedAttachmentBodies.map { ($0.key.rawValue, $0.value) }
        )
    }

    var clearMimeBodyPackage: ClearBodyPackage? {
        let hasClearMIME = contains(type: .cleartextMIME) || addressSendPreferences.contains(
                where: {
                    $0.value.pgpScheme == .pgpMIME &&
                    $0.value.encrypt == false
                }
            )
        guard hasClearMIME,
              let base64MIMESessionKey = mimeSessionKey?.encodeBase64(),
              let algorithm = mimeSessionAlgo else {
            return nil
        }
        return ClearBodyPackage(
            key: base64MIMESessionKey,
            algo: algorithm
        )
    }

    var clearPlainBodyPackage: ClearBodyPackage? {
        let hasClearPlainText = contains(type: .cleartextInline) ||
            contains(type: .cleartextMIME) ||
            addressSendPreferences.contains(
                where: { $0.value.pgpScheme == .pgpInline && $0.value.encrypt == false }
            )
        guard hasClearPlainText,
              let base64SessionKey = plainTextSessionKey?.encodeBase64(),
              let algorithm = plainTextSessionAlgo else {
            return nil
        }
        return ClearBodyPackage(
            key: base64SessionKey,
            algo: algorithm
        )
    }

    var mimeBody: String {
        if hasMime, let dataPackage = mimeDataPackage {
            return dataPackage
        }
        return ""
    }

    var plainBody: String {
        if hasPlainText, let dataPackage = plainTextDataPackage {
            return dataPackage
        }
        return ""
    }

    var hasMime: Bool {
        return self.contains(type: .pgpMIME) || self.contains(type: .cleartextMIME)
    }

    var hasPlainText: Bool {
        addressSendPreferences.contains(where: { $0.value.mimeType == .plainText })
    }

    func contains(type: PGPScheme) -> Bool {
        addressSendPreferences.contains(where: { $0.value.pgpScheme == type })
    }

    var encodedSessionKey: String? {
        return self.bodySessionKey?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }

    func getClearBodyPackageIfNeeded(_ addressPackages: [AddressPackageBase]) -> ClearBodyPackage? {
        guard addressPackages.contains(where: { $0.scheme == .cleartextInline || $0.scheme == .cleartextMIME }),
              let algorithm = bodySessionAlgo,
              let encodedSessionKey = self.encodedSessionKey else { return nil }
        return ClearBodyPackage(key: encodedSessionKey, algo: algorithm)
    }

    func getClearAttachmentPackagesIfNeeded(_ addressPackages: [AddressPackageBase]) -> [ClearAttachmentPackage]? {
        guard addressPackages.contains(where: { $0.scheme == .cleartextMIME || $0.scheme == .cleartextInline }) else {
            return nil
        }
        var attachments = [ClearAttachmentPackage]()
        for preAttachment in preAttachments {
            let encodedSession = preAttachment.session
                .base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            attachments.append(
                ClearAttachmentPackage(
                    attachmentID: preAttachment.attachmentId,
                    encodedSession: encodedSession,
                    algo: preAttachment.algo
                )
            )
        }
        return attachments.isEmpty ? nil : attachments
    }
}

// MARK: - Build Message Body
extension MessageSendingRequestBuilder {

    func prepareMime(
        senderKey: Key,
        passphrase: Passphrase,
        userKeys: [ArmoredKey],
        keys: [Key]
    ) throws {
        let mimeEML = MIMEEMLBuilder(
            preAttachments: preAttachments,
            attachmentBodys: attachmentBodys,
            clearBody: clearBody
        ).build()

        let encrypted = try mimeEML.encrypt(
            withKey: senderKey,
            userKeys: userKeys,
            mailboxPassphrase: passphrase
        )
        let (keyPacket, dataPacket) = try self.preparePackages(encrypted: encrypted)

        guard let sessionKey = try keyPacket.getSessionFromPubKeyPackage(
            userKeys: userKeys,
            passphrase: passphrase,
            keys: keys
        ) else {
            throw BuilderError.sessionKeyFailedToCreate
        }
        self.mimeSessionKey = sessionKey.sessionKey
        self.mimeSessionAlgo = sessionKey.algo
        self.mimeDataPackage = dataPacket.base64EncodedString()
    }

    func preparePlainText(
        senderKey: Key,
        passphrase: Passphrase,
        userKeys: [ArmoredKey],
        keys: [Key]
    ) throws {
        let plainText = self.generatePlainTextBody()

        let encrypted = try plainText.encrypt(
            withKey: senderKey,
            userKeys: userKeys,
            mailboxPassphrase: passphrase
        )

        let (keyPacket, dataPacket) = try self.preparePackages(encrypted: encrypted)

        guard let sessionKey = try keyPacket.getSessionFromPubKeyPackage(
            userKeys: userKeys,
            passphrase: passphrase,
            keys: keys
        ) else {
            throw BuilderError.sessionKeyFailedToCreate
        }

        self.plainTextSessionKey = sessionKey.sessionKey
        self.plainTextSessionAlgo = sessionKey.algo
        self.plainTextDataPackage = dataPacket.base64EncodedString()
    }

    func preparePackages(encrypted: String) throws -> (Data, Data) {
        guard let spilted = try encrypted.split(),
              let keyPacket = spilted.keyPacket,
              let dataPacket = spilted.dataPacket else {
                  throw BuilderError.packagesFailedToCreate
              }
        return (keyPacket, dataPacket)
    }

    func generatePlainTextBody() -> String {
        let body = self.clearBody ?? ""
        // Need to improve replace part
        return body.html2String.preg_replace("\n", replaceto: "\r\n")
    }
}

// MARK: - Create builders for each type of message
extension MessageSendingRequestBuilder {
    // swiftlint:disable:next function_body_length
    func generatePackageBuilder() throws -> [PackageBuilder] {
        var out = [PackageBuilder]()
        for (email, sendPreferences) in self.addressSendPreferences {
            var sessionKey = bodySessionKey ?? Data()
            var sessionKeyAlgorithm = bodySessionAlgo ?? .AES256

            if sendPreferences.mimeType == .plainText {
                if let plainTextSessionKey = plainTextSessionKey,
                   let algorithm = plainTextSessionAlgo {
                    sessionKey = plainTextSessionKey
                    sessionKeyAlgorithm = algorithm
                } else {
                    throw BuilderError.plainTextDataNotPrepared
                }
            }

            switch sendPreferences.pgpScheme {
            case .proton:
                out.append(InternalAddressBuilder(
                    type: .proton,
                    email: email,
                    sendPreferences: sendPreferences,
                    session: sessionKey,
                    algo: sessionKeyAlgorithm,
                    atts: self.preAttachments
                ))
            case .encryptedToOutside where self.password != nil:
                out.append(EOAddressBuilder(
                    type: .encryptedToOutside,
                    email: email,
                    sendPreferences: sendPreferences,
                    session: sessionKey,
                    algo: sessionKeyAlgorithm,
                    password: self.password ?? Passphrase(value: ""),
                    atts: self.preAttachments,
                    passwordHint: self.hint,
                    apiService: dependencies.apiService
                ))
            case .cleartextInline:
                out.append(ClearAddressBuilder(
                    type: .cleartextInline,
                    email: email,
                    sendPreferences: sendPreferences
                ))
            case .pgpInline where sendPreferences.publicKey != nil &&
                sendPreferences.encrypt:
                out.append(PGPAddressBuilder(
                    type: .pgpInline,
                    email: email,
                    sendPreferences: sendPreferences,
                    session: sessionKey,
                    algo: sessionKeyAlgorithm,
                    atts: self.preAttachments
                ))
            case .pgpInline:
                out.append(ClearAddressBuilder(
                    type: .cleartextInline,
                    email: email,
                    sendPreferences: sendPreferences
                ))
            // TODO: Fix the issue about PGP/MIME signed only message.
            case .pgpMIME where sendPreferences.publicKey != nil: // && sendPreferences.encrypt:
                guard let sessionData = mimeSessionKey,
                      let algorithm = mimeSessionAlgo else {
                    throw BuilderError.MIMEDataNotPrepared
                }
                out.append(PGPMimeAddressBuilder(
                    type: .pgpMIME,
                    email: email,
                    sendPreferences: sendPreferences,
                    session: sessionData,
                    algo: algorithm
                ))
            case .pgpMIME:
                out.append(ClearMimeAddressBuilder(
                    type: .cleartextMIME,
                    email: email,
                    sendPreferences: sendPreferences
                ))
            case .cleartextMIME:
                out.append(ClearMimeAddressBuilder(
                    type: .cleartextMIME,
                    email: email,
                    sendPreferences: sendPreferences
                ))
            default:
                break
            }
        }
        return out
    }
}

extension MessageSendingRequestBuilder {
    struct Dependencies {
        let apiService: APIService
    }
}
