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

        static let discardConfirmationTitle = LocalizedStringResource(
            "Discard this message?",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer discard confirmation alert title"
        )

        static let discardConfirmationMessage = LocalizedStringResource(
            "Your draft will not be saved",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer discard confirmation alert message"
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

        static func messageWillBeSentOn(time: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "This message will be sent on \(time)",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Composer toast message when message has been scheduled."
            )
        }

        static let sendingMessage = LocalizedStringResource(
            "Sending message...",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message when send is tapped."
        )

        static let schedulingMessage = LocalizedStringResource(
            "Scheduling message...",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message when schedule a message is tapped."
        )

        static let messageSent = LocalizedStringResource(
            "Message sent",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message after sent."
        )

        static let senderPickerSheetTitle = LocalizedStringResource(
            "From",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title for the sender picker action sheet."
        )
    }

    enum SenderValidation {
        static let addressNotAvailableAlertTitle = LocalizedStringResource(
            "Address not available",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title for the alert telling the user the address is invalid for sending."
        )

        static func cannotSend(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "\(address) cannot be used to send messages",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Error shown when the sender address can't be used for sending."
            )
        }

        static func disabled(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "\(address) is disabled. It cannot send messages",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Error shown when the sender address can't be used because it's disabled."
            )
        }

        static func subscriptionRequired(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "A paid plan is required to use \(address)",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Error shown when the sender address can't be used for subscription-based reasons."
            )
        }
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

        static func duplicateRecipients(addresses: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Removed duplicate recipients: \(addresses)",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Error shown when multiple duplicated recipients are added to the draft."
            )
        }

        static let draftSaveFailed = LocalizedStringResource(
            "There was a problem saving the draft",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error shown when the draft fails to save."
        )

        static let draftDiscardFailed = LocalizedStringResource(
            "Draft wasn't discarded. Try discarding it agian.",
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

    enum DraftPasswordError {
        static let passwordTooShort = LocalizedStringResource(
            "Password is too short.",
            comment: "Error in the context of setting password protection in the composer."
        )
    }

    enum DraftExpirationError {
        static let expirationTimeInThePast = LocalizedStringResource(
            "Expiration time can't be in the past.",
            comment: "Error in the context of setting a custom message expiration date in the composer."
        )

        static let expirationTimeExceeds30Days = LocalizedStringResource(
            "Expiration time is too far in the future.",
            comment: "Error in the context of setting a custom message expiration date in the composer."
        )
    }

    enum DraftSaveError {
        static func addressDisabled(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Disabled email address. Check that the address is valid and active.",
                comment: "Error in the context of saving a draft before being sent."
            )
        }

        static let addressDoesNotHavePrimaryKey = LocalizedStringResource(
            "Issue with this email address. Check the address or try again later.",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageAlreadySent = LocalizedStringResource(
            "Message was already sent",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageDoesNotExist = LocalizedStringResource(
            "The draft was not found",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageIsNotADraft = LocalizedStringResource(
            "The message is not a draft",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let protonRecipientNotFound = LocalizedStringResource(
            "Address not recognized. Please check the address.",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let recipientInvalidAddress = LocalizedStringResource(
            "Invalid email address. Check address and try again.",
            comment: "Error in the context of saving a draft before being sent."
        )
    }

    enum DraftSendError {
        static func addressDisabled(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Disabled email address. Check that the address is valid and active.",
                comment: "Error in the context of sending a draft before being sent."
            )
        }

        static func addressDoesNotHavePrimaryKey(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Issue with this email address. Check the address or try again later.",
                comment: "Error in the context of sending a draft before being sent."
            )
        }

        static let failedToDecryptExternalEncryptionPassword = LocalizedStringResource(
            "Failed to decrypt external encryption password",  // FIXME: - To verify
            comment: "Error in the context of scheduling a message."
        )

        static let messageAlreadySent = LocalizedStringResource(
            "Message was already sent",
            comment: "Error in the context of sending a draft before being sent."
        )

        static let messageDoesNotExist = LocalizedStringResource(
            "Draft not found. You may have discarded it.",
            comment: "Error in the context of sending a draft before being sent."
        )

        static let messageIsNotADraft = LocalizedStringResource(
            "Draft not found. You may have sent it already.",
            comment: "Error in the context of sending a draft before being sent."
        )

        static let missingAttachmentUploads = LocalizedStringResource(
            "Attachment is missing. Please upload again.",
            comment: "Error in the context of managing attachments in a draft."
        )

        static let noRecipients = LocalizedStringResource(
            "Please add at least one recipient",
            comment: "Error in the context of sending a draft before being sent."
        )

        static let packageError = LocalizedStringResource(
            "Problem sending message. Please try again.",
            comment: "Error in the context of sending a draft before being sent."
        )

        static func protonRecipientNotFound(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Address not recognized. Please check the address.",
                comment: "Error in the context of saving a draft before being sent."
            )
        }

        static func recipientInvalidAddress(address: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Invalid email address. Please check the address.",
                comment: "Error in the context of saving a draft before being sent."
            )
        }

        static let scheduleSendExpired = LocalizedStringResource(
            "Scheduled send time is in the past. Go to Drafts to send or reschedule it.",
            comment: "Error in the context of setting a schedule time for a message."
        )

        static let scheduleSendMessageLimitExceeded = LocalizedStringResource(
            "You reached the limit of scheduled messages.",
            comment: "Error in the context of scheduling a message."
        )

        static let expirationTimeTooSoon = LocalizedStringResource(
            "Message expiration time is too soon.",
            comment: "Error in the context of scheduling a message."
        )
    }

    enum DraftAttachmentUploadError {
        static let attachmentTooLarge = LocalizedStringResource(
            "Attachments too large. Keep attachment size under 25 MB.",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let crypto = LocalizedStringResource(
            "Problem encrypting attachment. Please upload it again.",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageAlreadySent = LocalizedStringResource(
            "Message was already sent",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageDoesNotExist = LocalizedStringResource(
            "Message does not exist",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let messageDoesNotExistOnServer = LocalizedStringResource(
            "Message was not found on the server",
            comment: "Error in the context of saving a draft before being sent."
        )

        static let retryInvalidState = LocalizedStringResource(
            "Retry not possible. Attachment is uploading or already uploaded.",
            comment: "Error in the context of retrying to upload a draft."
        )

        static let tooManyAttachments = LocalizedStringResource(
            "Too many attachments. Send them in multiple emails.",
            comment: "Error in the context of saving a draft before being sent."
        )
    }

    enum DraftSenderAddressChangeError {
        static let addressEmailNotFound = LocalizedStringResource(
            "Address not found",  // FIXME: Check
            comment: "Error in the context of changing the sender with a wrong sender address."
        )

        static let addressNotSendEnabled = LocalizedStringResource(
            "Address cannot be used to send messages",
            comment: "Error in the context of changing the sender with a disabled sender address."
        )

        static let addressDisabled = LocalizedStringResource(
            "Address is disabled",
            comment: "Error in the context of changing the sender with a disabled sender address."
        )
    }

    enum OpenDraftError {
        static let addressNotFound = LocalizedStringResource(
            "Address not found. Add again or reopen the draft.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error in the context of opening a draft in the composer"
        )

        static let draftDoesNotExist = LocalizedStringResource(
            "Message not found. You may have sent or discarded it.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error in the context of opening a draft in the composer"
        )

        static let missingMessageBody = LocalizedStringResource(
            "Message body wasn't retrieved. Close and reopen the draft.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Error in the context of opening a draft in the composer"
        )

        static let cantReplyOrForward = LocalizedStringResource(
            "Problem performing that action. Please try again.",
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

    enum MessageExpiration {
        static let menuTitle = LocalizedStringResource(
            "Message expires",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title of the message expiration menu"
        )

        static let never = LocalizedStringResource(
            "Never",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Default option for the message expiration menu"
        )

        static let afterOneHour = LocalizedStringResource(
            "After 1 hour",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Predefined option for the message expiration menu"
        )

        static let afterOneDay = LocalizedStringResource(
            "After 1 day",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Predefined option for the message expiration menu"
        )

        static let afterThreeDays = LocalizedStringResource(
            "After 3 days",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Predefined option for the message expiration menu"
        )

        static let specificDate = LocalizedStringResource(
            "On specific date",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Predefined option for the message expiration menu"
        )

        static let howExpirationWorks = LocalizedStringResource(
            "How expiration works?",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "subtitle for the learn more option in the message expiration menu"
        )

        static let datePickerTitle = LocalizedStringResource(
            "Set Message Expiry",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title of the message expiration custom date picker"
        )

        static let alertUnsupportedTitle = LocalizedStringResource(
            "Add Password to Use Expiration",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Sending to non-Proton accounts alert title"
        )

        static func alertUnsupportedForSomeRecipientsMessage(addresses: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Some recipients (\(addresses)) don’t support expiration by default. Add a password to enable expiration for non-Proton Mail recipients.",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Sending to only non-Proton accounts alert message"
            )
        }

        static let alertUnknownSupportForAllRecipientsMessage = LocalizedStringResource(
            "We could not confirm all recipients use Proton Mail. Only Proton addresses support message expiration. In this case, we suggest adding a password instead.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Sending to only non-Proton accounts alert message"
        )

        static let sendAnyway = LocalizedStringResource(
            "Send anyway",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Sending to non-Proton accounts alert option"
        )

        static let addPassword = LocalizedStringResource(
            "Add password",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Sending to non-Proton accounts alert option"
        )
    }

    enum PasswordProtection {

        static let title = LocalizedStringResource(
            "Set Password",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title of the password protected screen"
        )

        static let description = LocalizedStringResource(
            "Set a password to encrypt this message for non- Proton Mail users.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Description of the password protected screen"
        )

        static let editPassword = LocalizedStringResource(
            "Edit password",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Context menu option to edit the password of a message in the composer."
        )

        static let messagePassword = LocalizedStringResource(
            "Message Password",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title of the text box to add a password"
        )

        static let passwordConditions = LocalizedStringResource(
            "Must be between 8 and 21 characters long",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Conditions the password must meet"
        )

        static let repeatPassword = LocalizedStringResource(
            "Repeat password",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title of the text box to repeat the added password"
        )

        static let passwordHint = LocalizedStringResource(
            "Password hint (Optional)",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title of the text box to add a hint to remember the password"
        )

        static let removePassword = LocalizedStringResource(
            "Remove Password",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Text for button that removes the password"
        )
    }
}
