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

        static let discard = LocalizedStringResource(
            "Discard",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast action to discard the draft after dismising the screen"
        )

        static let discarded = LocalizedStringResource(
            "Discarded",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message confirming draft discarded"
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
            "Undo",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Undo action after message has been sent."
        )
    }

    enum Attachments {
        static let addAttachments = LocalizedStringResource(
            "Add attachments",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachments action sheet title."
        )

        static let attachmentFromPhotoLibrary = LocalizedStringResource(
            "From your photo library",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachments action sheet photo library option."
        )

        static let attachmentFromCamera = LocalizedStringResource(
            "Take new photo",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachments action sheet camera option."
        )

        static let attachmentImport = LocalizedStringResource(
            "Import from...",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachments action sheet import option."
        )

        static let cameraAccessDeniedTitle = LocalizedStringResource(
            "Camera",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Alert title shown if permission to camera is denied when trying to use it for attachments."
        )

        static let cameraAccessDeniedMessage = LocalizedStringResource(
            "Access to the camera was disabled. Please go to Settings and enable the camera permission.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Alert shown if permission to camera is denied when trying to use it for attachments."
        )

        static let removeAttachment = LocalizedStringResource(
            "Remove",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Confirmation for the remove attachment action in a Draft."
        )

        static let sendAsAttachment = LocalizedStringResource(
            "Send as attachment",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Menu option to send inline image as attachment instead."
        )
    }

    enum AttachmentError {

        static let attachmentsOverSizeLimitTitle = LocalizedStringResource(
            "Attachments too big",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachment failed because the total attachment size is over the limit"
        )

        static let singleAttachmentOverSizeLimitMessage = LocalizedStringResource(
            "There is a 25 MB limit on attachments per email. Send them in separate emails or share them via Proton Drive.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachment failed because the total attachment size is over the limit"
        )

        static func multipleAttachmentOverSizeLimitMessage(count: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "There is a 25 MB limit on attachments per email and \(count) attachments couldn't be added. Send them in separate emails or share them via Proton Drive.",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Attachment failed because the total attachment size is over the limit"
            )
        }

        static let tooManyAttachmentsTitle = LocalizedStringResource(
            "Too many attachments",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachment failed because the total of number of attachments is over the limit"
        )

        static let tooManyAttachmentsMessage = LocalizedStringResource(
            "You have reached the limit of attachments, 1 or more attachments weren't able to be added. Send them in separate emails or share them via Proton Drive.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachment failed because the total of number of attachments is over the limit"
        )

        static let tooManyAttachmentsFromServerTitle = LocalizedStringResource(
            "Attachment limit",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachment failed because the total size was above the limit"
        )

        static let tooManyAttachmentsFromServerMessage = LocalizedStringResource(
            "The size limit for attachments is 25 MB.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachment failed because the total size was above the limit"
        )

        static let somethingWentWrongTitle = LocalizedStringResource(
            "Something went wrong",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachment failed because an unexpected error"
        )

        static let somethingWentWrongMessage = LocalizedStringResource(
            "The attachment could not be added, please try again",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachment failed because an unexpected error"
        )
    }

    enum Alert {

        static let gotIt = LocalizedStringResource(
            "Got it",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Attachment error ok button"
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
        static let addressDoesNotExist = LocalizedStringResource(
            "The address does not exist",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error shown when a non existing address is added as recipient."
        )

        static func duplicateRecipient(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Removed duplicate recipient: \(address)",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Error shown when a duplicated recipient is added to the draft."
            )
        }

        static let draftSaveFailed = LocalizedStringResource(
            "There was a problem saving the draft",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error shown when the draft fails to save."
        )

        static let draftDiscardFailed = LocalizedStringResource(
            "There was a problem discarding the draft",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error shown when the draft fails to delete."
        )

        static let invalidAddressFormatTitle = LocalizedStringResource(
            "Invalid recipient",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer alert telling the user the entered address has not a valid format"
        )

        static let invalidAddressFormatMessage = LocalizedStringResource(
            "Please enter a valid email address",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer alert telling the user the entered address has not a valid format"
        )
    }

    enum DraftSaveError {

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


    enum DraftSendError {

        static func addressDisabled(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "The address is disabled: \(address)",
                comment: "Error in the context of sending a draft before being sent."
            )
        }

        static func addressDoesNotHavePrimaryKey(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Recipient primary key is missing: \(address)",
                comment: "Error in the context of sending a draft before being sent."
            )
        }

        static let messageAlreadySent = LocalizedStringResource(
            "The message was already sent",
            comment: "Error in the context of sending a draft before being sent."
        )

        static let messageDoesNotExist = LocalizedStringResource(
            "The draft to be sent was not found",
            comment: "Error in the context of sending a draft before being sent."
        )

        static let messageIsNotADraft = LocalizedStringResource(
            "The message to be sent is not a draft",
            comment: "Error in the context of sending a draft before being sent."
        )

        static let missingAttachmentUploads = LocalizedStringResource(
            "The attachment is missing",
            comment: "Error in the context of managing attachments in a draft."
        )

        static let noRecipients = LocalizedStringResource(
            "Message to be sent has no recipients",
            comment: "Error in the context of sending a draft before being sent."
        )

        static func packageError(error: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "There was a problem sending the message: \(error)",
                comment: "Error in the context of sending a draft before being sent."
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

        static let scheduleSendExpired = LocalizedStringResource(
            "The scheduled send date has expired",
            comment: "Error in the context of setting a schedule time for a message."
        )

        static func unknownRecipientValidation(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "The recipient is unknown: \(address)",
                comment: "Error in the context of sending a draft before being sent."
            )
        }
    }

    enum DraftAttachmentUploadError {
        static let attachmentTooLarge = LocalizedStringResource(
            "The attachments is too large",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let crypto = LocalizedStringResource(
            "There was a problem encrypting attachment",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageAlreadySent = LocalizedStringResource(
            "The message has been already sent",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageDoesNotExist = LocalizedStringResource(
            "Message does not exist",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageDoesNotExistOnServer = LocalizedStringResource(
            "Message does not exist on the server",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let retryInvalidState = LocalizedStringResource(
            "Retry failed, please remove the attachment",
            comment: "Error in the context of retrying to upload a draft."
        )

        static let tooManyAttachments = LocalizedStringResource(
            "The limit of attachments has been reached",
            comment: "Error in the context of saving a draft before being sent."
        )
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

    enum ScheduleSend {

        static let customTitle = LocalizedStringResource(
            "Custom",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Schedule send custom time option tile"
        )

        static let customSubtitleFreeUser = LocalizedStringResource(
            "Upgrade for full flexibility",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Schedule send custom time option subtitle for free user"
        )

        static let customSubtitle = LocalizedStringResource(
            "Pick time and date",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Schedule send custom time option subtitle"
        )

        static let monday = LocalizedStringResource(
            "Monday",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Schedule send predefined time option"
        )

        static let previouslySet = LocalizedStringResource(
            "Previously set",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title of a schedule send option that shows the time when the message was last scheduled"
        )

        static let title = LocalizedStringResource(
            "Schedule send",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title of the schedule send view"
        )

        static let tomorrow = LocalizedStringResource(
            "Tomorrow",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Schedule send predefined time option"
        )

    }
}
