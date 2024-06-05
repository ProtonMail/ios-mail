// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import Combine
import ProtonInboxICal
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreFeatures
import ProtonCoreServices

public final class InvitationEmailSender {
    public struct EmailContent {
        let subject: String
        let body: String
        let ics: ICS

        public init(subject: String, body: String, ics: InvitationEmailSender.EmailContent.ICS) {
            self.subject = subject
            self.body = body
            self.ics = ics
        }

        public struct ICS {
            let value: String
            let method: ICSMethod

            public init(value: String, method: ICSMethod) {
                self.value = value
                self.method = method
            }
        }
    }

    private enum ICSFile {
        static let name = "invite.ics"
    }

    // MARK: - Properties

    private let emailSender: EmailSending
    private let userPreContactsProvider: UserPreContactsProviding

    // MARK: - Init

    public init(emailSender: EmailSending, userPreContactsProvider: UserPreContactsProviding) {
        self.emailSender = emailSender
        self.userPreContactsProvider = userPreContactsProvider
    }

    // MARK: - Public

    public func send(
        content: EmailContent,
        toRecipients recipients: [String],
        senderParticipant: Participant,
        addressKeyPackage: AddressKeyPackage
    ) -> AnyPublisher<Void, Error> {
        userPreContactsProvider
            .preContacts(for: addressKeyPackage.passphraseInfo.user, recipients: recipients)
            .tryMap { preContacts -> (MessageContent, [PreContact]) in
                (try self.messageContent(content, recipients, addressKeyPackage), preContacts)
            }
            .flatMap { messageContent, preContacts in
                self.emailSender.send(
                    content: messageContent,
                    userKeys: addressKeyPackage.passphraseInfo.user.keys,
                    addressKeys: senderParticipant.address.keys.map(Key.init),
                    senderName: senderParticipant.address.displayName,
                    senderEmail: SenderInvitationEmailAddressComposer.senderEmail(
                        fromUserAddressEmail: senderParticipant.address.email,
                        invitedEmail: senderParticipant.attendee.user.email
                    ),
                    password: Passphrase(value: addressKeyPackage.passphraseInfo.userPassphrase),
                    contacts: preContacts,
                    auth: nil
                )
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func messageContent(
        _ emailContent: EmailContent,
        _ recipients: [String],
        _ addressKeyPackage: AddressKeyPackage
    ) throws -> MessageContent {
        let decryptionKey = try addressKeyPackage.primaryDecryptionKey()
        let publicKey = addressKeyPackage.activePrimaryKey.privateKey.publicKey

        let encryptedAndSignedBody = try encryptAndSignBody(body: emailContent.body, with: decryptionKey)
        let encryptedAttachment = try encryptAttachment(ics: emailContent.ics.value, publicKey: publicKey)

        let keyPacket = encryptedAttachment.keyPacket.unsafelyUnwrapped
        let dataPacket = encryptedAttachment.dataPacket.unsafelyUnwrapped

        let attachmentContent = AttachmentContent(
            fileName: ICSFile.name,
            mimeType: emailContent.ics.method.mimeType,
            keyPacket: keyPacket.base64EncodedString(),
            dataPacket: dataPacket,
            fileData: .combined(keyPacket: keyPacket, dataPacket: dataPacket)
        )

        return MessageContent(
            recipients: recipients,
            subject: emailContent.subject,
            body: encryptedAndSignedBody,
            attachments: [attachmentContent]
        )
    }

    private func encryptAndSignBody(body: String, with decryptionKey: DecryptionKey) throws -> String {
        try body.encryptNonOptional(
            withPrivKey: decryptionKey.privateKey.value,
            mailbox_pwd: decryptionKey.passphrase.value
        )
    }

    private func encryptAttachment(ics: String, publicKey: String) throws -> SplitMessage {
        try Data(ics.utf8).encryptAttachmentNonOptional(fileName: ICSFile.name, pubKey: publicKey)
    }

}

private extension String {

    static func combined(keyPacket: Data, dataPacket: Data) -> Self {
        (keyPacket + dataPacket).base64EncodedString()
    }

}
