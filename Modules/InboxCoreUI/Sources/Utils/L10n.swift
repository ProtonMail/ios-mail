//
// Copyright (c) 2025 Proton Technologies AG
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

enum L10n {
    enum BiometricLock {
        static let biometricUnlockRationale = LocalizedStringResource(
            "Please authenticate to unlock your screen.",
            comment: "Displayed in the system PIN pop-up when FaceID for this app is disabled."
        )
        static let unlockButtonTitle = LocalizedStringResource(
            "Unlock Proton Mail",
            comment: "Title of a button that triggers biometric authorization on the lock screen."
        )
        enum BiometricsNotAvailableAlert {
            static let signInAgainAction = LocalizedStringResource(
                "Sign in again",
                comment: "Alert action title. The alert is dispalyed when biometric is set as lock protection method, but it's not configured on the device."
            )
            static let title = LocalizedStringResource(
                "Enable access",
                comment: "Alert title. The alert is dispalyed when biometric is set as lock protection method, but it's not configured on the device."
            )
            static let messageFaceID = LocalizedStringResource(
                "PIN and Face ID are disabled on your device. Enable them in Settings or sign in to unlock this app.",
                comment: "Face ID version alert message. The alert is dispalyed when biometric is set as lock protection method, but it's not configured on the device."
            )
            static let messageTouchID = LocalizedStringResource(
                "PIN and Touch ID are disabled on your device. Enable them in Settings or sign in to unlock this app.",
                comment: "Touch ID version alert message. The alert is dispalyed when biometric is set as lock protection method, but it's not configured on the device."
            )
            static let defaultMessage = LocalizedStringResource(
                "PIN and Biometry are disabled on your device. Enable them in Settings or sign in to unlock this app.",
                comment: "Default version alert message. The alert is dispalyed when biometric is set as lock protection method, but it's not configured on the device."
            )
        }
    }

    enum PINLock {
        static let title = LocalizedStringResource(
            "Enter PIN",
            comment: "Title of the pin lock screen."
        )
        static let subtitle = LocalizedStringResource(
            "Confirm it's you to continue.",
            comment: "Subtitle of PIN lock screen."
        )
        static let pinInputPlaceholder = LocalizedStringResource(
            "PIN Code",
            comment: "PIN input placeholder."
        )
        static let invalidPIN = LocalizedStringResource(
            "Incorrect PIN. Please try again.",
            comment: "Error message when a user enters an invalid PIN"
        )
        static let tooFrequentAttempts = LocalizedStringResource(
            "Too many attempts too quickly. Please wait before trying again.",
            comment: "Displayed when the user tries to validate their PIN too frequently."
        )
        static let signOut = LocalizedStringResource(
            "Sign out",
            comment: "Title of the sign out button."
        )
        static let signOutConfirmationTitle = LocalizedStringResource(
            "Sign Out of All Accounts",
            comment: "Title of the sign out confirmation alert."
        )
        static let signOutConfirmationMessage = LocalizedStringResource(
            "You're about to be signed out of all your accounts on this device. Do you want to continue?",
            comment: "Message of the sign out confirmation alert."
        )
        static func remainingAttemptsWarning(_ number: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "\(number) attempts remaining before sign-out.",
                comment: "Remaining attempts after a user has entered a wrong PIN a few times."
            )
        }
    }

    enum PrivacyLockTooltip {
        enum Title {
            static let endToEndEncrypted = LocalizedStringResource(
                "End-to-end encrypted",
                comment: "Title indicating email is end-to-end encrypted."
            )
            static let endToEndEncryptedFromVerifiedSender = LocalizedStringResource(
                "End-to-end encrypted from verified sender",
                comment: "Title indicating email is end-to-end encrypted from a verified sender."
            )
            static let endToEndEncryptedToVerifiedRecipient = LocalizedStringResource(
                "End-to-end encrypted to verified recipient",
                comment: "Title indicating email is end-to-end encrypted to a verified recipient."
            )
            static let endToEndEncryptedToVerifiedRecipients = LocalizedStringResource(
                "End-to-end encrypted to verified recipients",
                comment: "Title indicating email is end-to-end encrypted to verified recipients."
            )
            static let endToEndEncryptedWithFailedVerification = LocalizedStringResource(
                "End-to-end encrypted with failed verification",
                comment: "Title indicating email is end-to-end encrypted but verification failed."
            )
            static let pgpEndToEndEncrypted = LocalizedStringResource(
                "PGP end-to-end encrypted",
                comment: "Title indicating email is PGP end-to-end encrypted."
            )
            static let pgpEndToEndEncryptedToVerifiedRecipient = LocalizedStringResource(
                "PGP end-to-end encrypted to verified recipient",
                comment: "Title indicating email is PGP end-to-end encrypted to a verified recipient."
            )
            static let pgpSignedEmail = LocalizedStringResource(
                "PGP-signed email",
                comment: "Title indicating email is PGP-signed."
            )
            static let pgpSignedEmailWithFailedVerification = LocalizedStringResource(
                "PGP-signed email with failed verification",
                comment: "Title indicating email is PGP-signed but verification failed."
            )
            static let pgpSignedMessageFromVerifiedSender = LocalizedStringResource(
                "PGP-signed message from verified sender",
                comment: "Title indicating message is PGP-signed from a verified sender."
            )
            static let zeroAccessEncrypted = LocalizedStringResource(
                "Zero-access encrypted",
                comment: "Title indicating email is zero-access encrypted."
            )
            static let zeroAccessEncryptedWithVerifiedRecipient = LocalizedStringResource(
                "Zero-access encrypted with verified recipient",
                comment: "Title indicating email is zero-access encrypted with a verified recipient."
            )
            static let zeroAccessEncryptedWithVerifiedRecipients = LocalizedStringResource(
                "Zero-access encrypted with verified recipients",
                comment: "Title indicating email is zero-access encrypted with verified recipients."
            )
        }

        enum Description {
            static let emailsExchangedBetweenProtonUsers = LocalizedStringResource(
                "Emails exchanged between Proton users are automatically end-to-end encrypted.",
                comment: "Additional description explaining that emails between Proton users are automatically end-to-end encrypted."
            )
            static let recipientIsVerifiedContact = LocalizedStringResource(
                "The recipient is a [verified contact](https://proton.me/support/address-verification) whose encryption keys you have trusted.",
                comment: "Additional description explaining the recipient is a verified contact."
            )
            static let recipientsAreVerifiedContacts = LocalizedStringResource(
                "The recipients are [verified contacts](https://proton.me/support/address-verification) whose encryption keys you have trusted.",
                comment: "Additional description explaining the recipients are verified contacts."
            )
            static let senderIsVerifiedContact = LocalizedStringResource(
                "The sender is a [verified contact](https://proton.me/support/address-verification) whose encryption keys you have trusted.",
                comment: "Additional description explaining the sender is a verified contact."
            )
            static let senderVerificationFailed = LocalizedStringResource(
                "The [sender verification failed](https://proton.me/support/sender-verification-failed). Please confirm the authenticity of the email with your contact.",
                comment: "Additional description explaining sender verification failed."
            )
            static let senderVerificationFailedNoSignature = LocalizedStringResource(
                "The [sender verification failed](https://proton.me/support/sender-verification-failed) because it was not signed. Please confirm the authenticity of the email with your contact.",
                comment: "Additional description explaining sender verification failed because email was not signed."
            )
            static let senderOrRecipientNotUsingProtonMail = LocalizedStringResource(
                "However, a sender or recipient not using Proton Mail may have a non-encrypted copy stored on their email server.",
                comment: "Additional description noting that non-Proton Mail users may have unencrypted copies."
            )
            static let theEmailIsStoredWithZeroAccessEncryption = LocalizedStringResource(
                "The email is stored on Proton servers with [zero-access encryption](https://proton.me/blog/zero-access-encryption). Neither Proton nor anyone else can read it.",
                comment: "Description explaining the email is stored with zero-access encryption."
            )
            static let thisEmailIsEndToEndEncrypted = LocalizedStringResource(
                "This email is [end-to-end encrypted](https://proton.me/blog/what-is-end-to-end-encryption) on the sender's device and can only be decrypted by the recipient. Proton can't see the contents of the email at any time.",
                comment: "Description explaining what end-to-end encryption means for this email."
            )
            static let thisEmailIsStoredWithZeroAccessEncryption = LocalizedStringResource(
                "This email is stored on Proton servers with [zero-access encryption](https://proton.me/blog/zero-access-encryption). Neither Proton nor anyone else can read it.",
                comment: "Description explaining email is stored with zero-access encryption."
            )
            static let thisRecipientDisabledE2e = LocalizedStringResource(
                "This recipient has disabled end-to-end encryption on their account.",
                comment: "Description explaining that the recipient has disabled end-to-end encryption."
            )
            static let youHaveDigitallySigned = LocalizedStringResource(
                "You have [digitally signed](https://proton.me/support/proton-mail-digital-signatures) this email, proving to the recipient that your email is genuine and hasn't been tampered with.",
                comment: "Description explaining that you have digitally signed this email."
            )
        }
    }
}
