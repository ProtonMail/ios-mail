// Copyright (c) 2024 Proton Technologies AG
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

/// Once you define `LocalizedStringResource` below Xcode puts related string in `Localizable.xcstrings` file.
/// The generation happens automatically when adding/removing string below. All keys are added in alphabetical order.
/// IMPORTANT: Remember about setting bundle for each key: `bundle: .atURL(Bundle.module.bundleURL)`.
enum L10n {
    enum Composer {

        static let draftLoadedOffline = LocalizedStringResource(
            "You're currently offline. This draft may not be up-to-date.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Draft might not be up-to-date when loaded"
        )

        static let send = LocalizedStringResource(
            "Send",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Message send button."
        )

        static let to = LocalizedStringResource(
            "To:",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer to recipients."
        )

        static let from = LocalizedStringResource(
            "From:",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer from field."
        )

        static let subject = LocalizedStringResource(
            "Subject:",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer subject."
        )

        static let draftSaved = LocalizedStringResource(
            "Draft saved",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message when dismissing the screen."
        )

        static let sendingMessage = LocalizedStringResource(
            "Sending message...",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message when send is tapped."
        )

        static let messageSent = LocalizedStringResource(
            "Message sent",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message after sent."
        )

        static let undoSend = LocalizedStringResource(
            "UNDO",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Undo action after message has been sent."
        )
    }

    enum Contacts {

        static func groupSubtitle(membersCount: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "\(membersCount) members",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Contact group row subtitle in contact picker."
            )
        }
    }

    enum ComposerError {
        static let unknownMimeType = LocalizedStringResource(
            "Unrecognized MIME type",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error when saving a draft"
        )

        static func duplicateRecipient(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Removed duplicate recipient: \(address)",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Error shown when a duplicated recipient is added to the draft."
            )
        }

        static let draftSaveFailed =  LocalizedStringResource(
            "There was a problem saving the draft",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error shown when the draft fails to save."
        )

        static let invalidLastRecipient = LocalizedStringResource(
            "Please verify your last recipient",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message when an invalid recipient is added by prematurely finishing text input"
        )
    }

    enum DraftSaveSendError {

        static func addressDisabled(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "The address is disabled: \(address)",
                comment: "Error in the context of saving a draft before being sent."
            )
        }

        static func addressDoesNotHavePrimaryKey(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Recipient primary key is missing: \(address)",
                comment: "Error in the context of saving a draft before being sent."
            )
        }

        static let messageAlreadySent = LocalizedStringResource(
            "The message was already sent",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageDoesNotExist = LocalizedStringResource(
            "The draft to be sent was not found",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageIsNotADraft = LocalizedStringResource(
            "The message to be sent is not a draft",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let noRecipients = LocalizedStringResource(
            "Message to be sent has no recipients",
            comment: "Error in the context of saving a draft before being sent."
        )

        static func packageError(error: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "There was a problem sending the message: \(error)",
                comment: "Error in the context of saving a draft before being sent."
            )
        }

        static func protonRecipientNotFound(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "The Proton address in the recipient does not exist: \(address)",
                comment: "Error in the context of saving a draft before being sent."
            )
        }

        static func recipientInvalidAddress(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Recipient address is invalid: \(address)",
                comment: "Error in the context of saving a draft before being sent."
            )
        }

        static func unknownRecipientValidation(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "The recipient is unknown: \(address)",
                comment: "Error in the context of saving a draft before being sent."
            )
        }
    }

    enum OpenDraftError {
        static let addressNotFound = LocalizedStringResource(
            "Address not found",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error in the context of opening a draft in the composer"
        )

        static let draftDoesNotExist = LocalizedStringResource(
            "Draft not found",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error in the context of opening a draft in the composer"
        )

        static let missingMessageBody = LocalizedStringResource(
            "Draft body is missing",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error in the context of opening a draft in the composer"
        )

        static let cantReplyOrForward = LocalizedStringResource(
            "Error trying to reply or forward this message",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error in the context of opening a draft in the composer"
        )
    }
}
