// Copyright (c) 2026 Proton Technologies AG
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

import InboxDesignSystem
import SwiftUI
import proton_app_uniffi

struct PrivacyLockTooltipDisplayData {
    let title: LocalizedStringResource
    let description: LocalizedStringResource
    let additionalDescription: LocalizedStringResource?
}

extension PrivacyLockTooltip {
    var displayData: PrivacyLockTooltipDisplayData {
        switch self {
        case .none:  // FIXME: - It'll be removed from Rust
            .init(title: .empty, description: .empty, additionalDescription: nil)
        case .sendE2e:
            .init(
                title: L10n.PrivacyLockTooltip.Title.endToEndEncrypted,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: L10n.PrivacyLockTooltip.Description.emailsExchangedBetweenProtonUsers
            )
        case .sendE2eVerifiedRecipient:
            .init(
                title: L10n.PrivacyLockTooltip.Title.endToEndEncryptedToVerifiedRecipient,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: L10n.PrivacyLockTooltip.Description.recipientIsVerifiedContact
            )
        case .sendSignOnly:
            .init(
                title: L10n.PrivacyLockTooltip.Title.pgpSignedEmail,
                description: L10n.PrivacyLockTooltip.Description.youHaveDigitallySigned,
                additionalDescription: nil
            )
        case .sendZeroAccessEncryptionDisabled:
            .init(
                title: L10n.PrivacyLockTooltip.Title.zeroAccessEncrypted,
                description: L10n.PrivacyLockTooltip.Description.thisRecipientDisabledE2e,
                additionalDescription: L10n.PrivacyLockTooltip.Description.thisEmailIsStoredWithZeroAccessEncryption
            )
        case .zeroAccess:
            .init(
                title: L10n.PrivacyLockTooltip.Title.zeroAccessEncrypted,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsStoredWithZeroAccessEncryption,
                additionalDescription: L10n.PrivacyLockTooltip.Description.senderOrRecipientNotUsingProtonMail
            )
        case .zeroAccessSentByProton:
            .init(
                title: L10n.PrivacyLockTooltip.Title.zeroAccessEncrypted,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsStoredWithZeroAccessEncryption,
                additionalDescription: L10n.PrivacyLockTooltip.Description.senderOrRecipientNotUsingProtonMail
            )
        case .receiveE2e:
            .init(
                title: L10n.PrivacyLockTooltip.Title.endToEndEncrypted,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: L10n.PrivacyLockTooltip.Description.emailsExchangedBetweenProtonUsers
            )
        case .receiveE2eVerifiedRecipient:
            .init(
                title: L10n.PrivacyLockTooltip.Title.endToEndEncryptedFromVerifiedSender,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: L10n.PrivacyLockTooltip.Description.senderIsVerifiedContact
            )
        case .receiveE2eVerificationFailed:
            .init(
                title: L10n.PrivacyLockTooltip.Title.endToEndEncryptedWithFailedVerification,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: L10n.PrivacyLockTooltip.Description.senderVerificationFailed
            )
        case .receiveE2eVerificationFailedNoSignature:
            .init(
                title: L10n.PrivacyLockTooltip.Title.endToEndEncryptedWithFailedVerification,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: L10n.PrivacyLockTooltip.Description.senderVerificationFailedNoSignature
            )
        case .receiveSignOnlyVerifiedRecipient:
            .init(
                title: L10n.PrivacyLockTooltip.Title.pgpSignedMessageFromVerifiedSender,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsStoredWithZeroAccessEncryption,
                additionalDescription: L10n.PrivacyLockTooltip.Description.senderIsVerifiedContact
            )
        case .receiveSignOnlyVerificationFailed:
            .init(
                title: L10n.PrivacyLockTooltip.Title.pgpSignedEmailWithFailedVerification,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsStoredWithZeroAccessEncryption,
                additionalDescription: L10n.PrivacyLockTooltip.Description.senderVerificationFailed
            )
        case .sentE2eVerifiedRecipients:
            .init(
                title: L10n.PrivacyLockTooltip.Title.endToEndEncryptedToVerifiedRecipients,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: L10n.PrivacyLockTooltip.Description.recipientsAreVerifiedContacts
            )
        case .sentProtonVerifiedRecipients:
            .init(
                title: L10n.PrivacyLockTooltip.Title.zeroAccessEncryptedWithVerifiedRecipients,
                description: L10n.PrivacyLockTooltip.Description.theEmailIsStoredWithZeroAccessEncryption,
                additionalDescription: L10n.PrivacyLockTooltip.Description.recipientsAreVerifiedContacts
            )
        case .sentE2e:
            .init(
                title: L10n.PrivacyLockTooltip.Title.endToEndEncrypted,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: L10n.PrivacyLockTooltip.Description.emailsExchangedBetweenProtonUsers
            )
        case .sentRecipientE2eVerifiedRecipient:
            .init(
                title: L10n.PrivacyLockTooltip.Title.endToEndEncryptedToVerifiedRecipient,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: L10n.PrivacyLockTooltip.Description.recipientIsVerifiedContact
            )
        case .sentRecipientProtonMailVerifiedRecipient:
            .init(
                title: L10n.PrivacyLockTooltip.Title.zeroAccessEncryptedWithVerifiedRecipient,
                description: L10n.PrivacyLockTooltip.Description.theEmailIsStoredWithZeroAccessEncryption,
                additionalDescription: L10n.PrivacyLockTooltip.Description.recipientIsVerifiedContact
            )
        case .sentRecipientE2e:
            .init(
                title: L10n.PrivacyLockTooltip.Title.endToEndEncrypted,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: nil
            )
        case .sentRecipientProtonMail:
            .init(
                title: L10n.PrivacyLockTooltip.Title.zeroAccessEncrypted,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsStoredWithZeroAccessEncryption,
                additionalDescription: L10n.PrivacyLockTooltip.Description.senderOrRecipientNotUsingProtonMail
            )
        case .sentRecipientE2ePgpVerifiedRecipient:
            .init(
                title: L10n.PrivacyLockTooltip.Title.pgpEndToEndEncryptedToVerifiedRecipient,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: L10n.PrivacyLockTooltip.Description.recipientIsVerifiedContact
            )
        case .sentRecipientProtonMailPgpVerifiedRecipient:
            .init(
                title: L10n.PrivacyLockTooltip.Title.zeroAccessEncrypted,
                description: L10n.PrivacyLockTooltip.Description.theEmailIsStoredWithZeroAccessEncryption,
                additionalDescription: L10n.PrivacyLockTooltip.Description.recipientIsVerifiedContact
            )
        case .sentRecipientE2ePgpRecipient:
            .init(
                title: L10n.PrivacyLockTooltip.Title.pgpEndToEndEncrypted,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsEndToEndEncrypted,
                additionalDescription: nil
            )
        case .sentRecipientProtonMailPgpRecipient:
            .init(
                title: L10n.PrivacyLockTooltip.Title.zeroAccessEncrypted,
                description: L10n.PrivacyLockTooltip.Description.thisEmailIsStoredWithZeroAccessEncryption,
                additionalDescription: L10n.PrivacyLockTooltip.Description.senderOrRecipientNotUsingProtonMail
            )
        case .sentRecipientPgpSigned:
            .init(
                title: L10n.PrivacyLockTooltip.Title.pgpSignedEmail,
                description: L10n.PrivacyLockTooltip.Description.youHaveDigitallySigned,
                additionalDescription: nil
            )
        }
    }
}
