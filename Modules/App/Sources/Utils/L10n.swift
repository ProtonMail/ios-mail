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
enum L10n {
    enum Action {
        enum Address {
            static let addToContacts = LocalizedStringResource(
                "Add to contacts",
                comment: "Action title for adding email address to contacts in the address action sheet."
            )
            static let blockContact = LocalizedStringResource(
                "Block this contact",
                comment: "Action title for blocking email address in the address action sheet."
            )
            static let call = LocalizedStringResource(
                "Call",
                comment: "Action title for calling phone number in the address action sheet."
            )
            static let copyAddress = LocalizedStringResource(
                "Copy address",
                comment: "Action title for copying email address to clipboard in the address action sheet."
            )
            static let copyName = LocalizedStringResource(
                "Copy name",
                comment: "Action title for copying address name to clipboard in the address action sheet."
            )
            static let newMessage = LocalizedStringResource(
                "Message",
                comment: "Action title for creating new message in the address action sheet."
            )
        }

        enum Print {
            static let error = LocalizedStringResource(
                "Could not print requested e-mail",
                comment: "Error message when printing fails."
            )

            static func plusMore(count: Int) -> LocalizedStringResource {
                .init(
                    "+\(count) more",
                    comment: "At the end of a list of items, showing how many more are hidden."
                )
            }
        }

        enum Send {
            static let editScheduledAlertTitle = LocalizedStringResource(
                "Edit and reschedule",
                comment: "Alert title for editing a scheduled message."
            )
            static let editScheduledAlertMessage = LocalizedStringResource(
                "This message will be moved to Drafts so you can edit it. You'll need to reschedule when it will be sent.",
                comment: "Alert message for editing a scheduled message."
            )
            static let editScheduledAlertConfimationButton = LocalizedStringResource(
                "Edit draft",
                comment: "Alert confirmation button title for editing a scheduled message."
            )
            static let editScheduleNetworkIsRequired = LocalizedStringResource(
                "You need to be online to edit scheduled messages",
                comment: "Toast message when editing fails because there is no internet connection."
            )
            static let forward = LocalizedStringResource(
                "Forward",
                comment: "Action title for forwarding given message in the action sheet."
            )
            static let reply = LocalizedStringResource(
                "Reply",
                comment: "Action title for replying to a sender of given message in the action sheet."
            )
            static let replyAll = LocalizedStringResource(
                "Reply all",
                comment: "Action title for replying to a sender and all receipients of given message in the action sheet."
            )
        }

        enum UndoSendError {
            static let sendCannotBeUndone = LocalizedStringResource(
                "Too late to undo send. Message was sent.",
                comment: "Error in the context of undoing a sent message"
            )

            static let draftNotFound = LocalizedStringResource(
                "Cannot undo send. Message was discarded or already sent.",
                comment: "Error in the context of undoing a sent message"
            )
        }

        enum UndoScheduleSendError {
            static let messageDoesNotExist = LocalizedStringResource(
                "Cannot cancel schedule send. Message was discarded or already sent.",
                comment: "Error in the context of undoing a scheduled message: the message no longer exists (discarded or already sent)."
            )
            static let messageNotScheduled = LocalizedStringResource(
                "Cannot cancel schedule send. Message was not scheduled.",
                comment: "Error in the context of undoing a scheduled message: the message was never scheduled."
            )
            static let messageAlreadySent = LocalizedStringResource(
                "Cannot cancel schedule send. Message was already sent.",
                comment: "Error in the context of undoing a scheduled message: the message has already been sent."
            )
        }

        static let deletePermanently = LocalizedStringResource(
            "Delete permanently",
            comment: "Action title for permanent deletion of message/conversation in the action sheet."
        )
        static let labelAs = LocalizedStringResource(
            "Label as…",
            comment: "Action title for labeling message/conversation in the action sheet."
        )
        static let markAsRead = LocalizedStringResource(
            "Mark as read",
            comment: "Action title for marking message/conversation as read in the action sheet."
        )
        static let markAsUnread = LocalizedStringResource(
            "Mark as unread",
            comment: "Action title for marking message/conversation as unread in the action sheet."
        )
        static let moveTo = LocalizedStringResource(
            "Move to…",
            comment: "Action title for moving message/conversation in the action sheet."
        )
        static let moveToArchive = LocalizedStringResource(
            "Archive",
            comment: "Action title for moving message/conversation to the `Archive` folder in the action sheet."
        )
        static let moveToInbox = LocalizedStringResource(
            "Move to inbox",
            comment: "Action title for moving message/conversation to the `Inbox` folder in the action sheet."
        )
        static let moveToInboxFromSpam = LocalizedStringResource(
            "Not spam",
            comment: "Action title for moving message/conversation from the `Spam` to the `Inbox` folder in the action sheet."
        )
        static let moveToSpam = LocalizedStringResource(
            "Move to spam",
            comment: "Action title for moving message/conversation to the `Spam` folder in the action sheet."
        )
        static let moveToTrash = LocalizedStringResource(
            "Move to trash",
            comment: "Action title for moving message/conversation to the `Trash` folder in the action sheet."
        )
        static let notSpam = LocalizedStringResource(
            "Not spam",
            comment: "Action title for moving a message out of `Spam` to `Inbox`"
        )
        static let print = LocalizedStringResource(
            "Print",
            comment: "Action title for printing given message in the action sheet."
        )
        static let pin = LocalizedStringResource("Pin", comment: "Message pin action title.")
        static let unpin = LocalizedStringResource("Unpin", comment: "Message unpin action title.")
        static let renderInLightMode = LocalizedStringResource(
            "View message in light mode",
            comment: "Action title for viewing given message in light mode in the action sheet."
        )
        static let renderInDarkMode = LocalizedStringResource(
            "View message in dark mode",
            comment: "Action title for viewing given message in dark mode in the action sheet."
        )
        static let reportPhishing = LocalizedStringResource(
            "Report phishing",
            comment: "Action title for reporting phishing message in the action sheet."
        )
        static let saveAsPDF = LocalizedStringResource(
            "Save as PDF",
            comment: "Action title for saving message as PDF file in the action sheet."
        )
        static let snooze = LocalizedStringResource(
            "Snooze",
            comment: "Action title for marking message as snoozed in the action sheet."
        )
        static let star = LocalizedStringResource(
            "Star",
            comment: "Action title for marking message/conversation as starred in the action sheet."
        )
        static let unstar = LocalizedStringResource(
            "Unstar",
            comment: "Action title for removing message/conversation from starred items in the action sheet."
        )
        static let viewHeaders = LocalizedStringResource(
            "View headers",
            comment: "Action title for viewing given message's headers in the action sheet."
        )
        static let viewHTML = LocalizedStringResource(
            "View HTML",
            comment: "Action title for viewing given message's HTML in the action sheet."
        )
        static let alsoArchive = LocalizedStringResource(
            "Also archive?",
            comment: "Title of switcher in the label as action sheet."
        )

        enum Delete {
            enum Alert {
                static func title(itemsCount: Int) -> LocalizedStringResource {
                    .init(
                        "Delete \(itemsCount) messages",
                        comment: "Title of alert displayed after delete permanently action tap."
                    )
                }

                static func message(itemsCount: Int) -> LocalizedStringResource {
                    .init(
                        "Are you sure you want to delete these \(itemsCount) messages permanently?",
                        comment: "Message of alert displayed after delete permanently action tap."
                    )
                }
            }
        }

        enum ReportPhishing {
            enum Alert {
                static let title = LocalizedStringResource(
                    "Confirm phishing report",
                    comment: "Title of alert displayed after report phishing action tap."
                )
                static let message = LocalizedStringResource(
                    "Reporting a message as a phishing attempt will send the message to us, so we can analyze it and improve our filters. This means that we will be able to see the contents of the message in full.",
                    comment: "Message of alert displayed after report phishing action tap."
                )
            }
        }
    }

    enum EventLoopError {
        static let eventLoopErrorMessage = LocalizedStringResource(
            "We encountered an issue while syncing your mail with the event loop. Please share the logs with our support team for further investigation. Try logging out and logging back in to resolve the issue.",
            comment: "Event loop failed because an unexpected error."
        )
        static let eventSyncingError = LocalizedStringResource(
            "Issue syncing your content. Check your connection or sign in again.",
            comment: "Event loop failed due to an issue syncing content."
        )
    }

    enum Common {
        static let markAsLegitimate = LocalizedStringResource(
            "Mark as legitimate",
            comment: "Used when the user marks an email as legitimate, including confirming legitimacy, overriding phishing detection, or overriding spam detection."
        )
        static let next = LocalizedStringResource("Next", comment: "`Next` action title.")
        static let save = LocalizedStringResource("Save", comment: "`Save` action title.")
    }

    enum LegacyMigration {
        static let migrationFailed = LocalizedStringResource(
            "Issue updating your account. Please sign in again.",
            comment: "Error toast of the welcome screen."
        )
    }

    enum Mailbox {
        enum EmptyState {
            static let message = LocalizedStringResource(
                "Seems like you are all caught up for now",
                comment: "Mailbox empty state message."
            )
            static let title = LocalizedStringResource("No messages", comment: "Mailbox empty state title.")
            static let titleForUnread = LocalizedStringResource(
                "No unread messages",
                comment: "Mailbox empty state title when unread filter is enabled."
            )
        }

        enum EmptyOutbox {
            static let title = LocalizedStringResource(
                "Nothing in Outbox",
                comment: "Outbox empty state title."
            )
            static let message = LocalizedStringResource(
                "All messages have been sent",
                comment: "Outbox empty state message."
            )
        }

        enum Error {
            static let mailboxErrorMessage = LocalizedStringResource(
                "We encountered an issue while preparing the mailbox. Please share the logs with our support team for further investigation.",
                comment: "Mailbox failed because an unexpected error."
            )
            static let issuesLoadingMailboxContent = LocalizedStringResource(
                "Issue loading your content. Please try refreshing or sign in again.",
                comment: "Loading items in your mailbox returns an error."
            )
        }

        enum Item {
            static func expiresIn(value: String) -> LocalizedStringResource {
                .init(
                    "Expires in \(value)",
                    comment: "Message indicating when email is gonna be expired."
                )
            }
            static let expiresInLessThanOneMinute = LocalizedStringResource(
                "Expires in less than 1 minute",
                comment: "Message indicating the item will expire shortly"
            )
            static func snoozedTill(value: String) -> LocalizedStringResource {
                .init(
                    "Snoozed till \(value)",
                    comment: "Message indicating till when email is snoozed."
                )
            }
            static let noRecipient = LocalizedStringResource("(No Recipient)", comment: "No recipent placeholder.")
            static let sending = LocalizedStringResource(
                "Sending..",
                comment: "Title of a tag displayed for each message that is in the outbox with sending status."
            )
            static let sendingFailure = LocalizedStringResource(
                "Failed to Send",
                comment: "Title of a tag displayed for each message that failed to send."
            )
        }

        enum SystemFolder {
            static let allMail = LocalizedStringResource(
                "All Mail",
                comment: "`Menu title of all emails in the sidebar."
            )
            static let scheduled = LocalizedStringResource(
                "Scheduled",
                comment: "Menu title of all scheduled emails in the sidebar."
            )
            static let archive = LocalizedStringResource(
                "Archive",
                comment: "Menu title of all archived emails in the sidebar."
            )
            static let drafts = LocalizedStringResource(
                "Drafts",
                comment: "Menu title of drafts in the sidebar."
            )
            static let inbox = LocalizedStringResource(
                "Inbox",
                comment: "Menu title of all received emails in the sidebar."
            )
            static let outbox = LocalizedStringResource(
                "Outbox",
                comment: "Menu title of all outbox emails in the sidebar."
            )
            static let sent = LocalizedStringResource(
                "Sent",
                comment: "Menu title of sent emails in the sidebar."
            )
            static let snoozed = LocalizedStringResource(
                "Snoozed",
                comment: "Menu title of all snoozed emails in the sidebar."
            )
            static let spam = LocalizedStringResource(
                "Spam",
                comment: "Menu title of all emails marked as spam in the sidebar."
            )
            static let starred = LocalizedStringResource(
                "Starred",
                comment: "Menu title of all emails marked as starred in the sidebar."
            )
            static let trash = LocalizedStringResource(
                "Trash",
                comment: "Menu title of all deleted emails in the sidebar."
            )
        }

        enum VoiceOver {
            static func attachments(count: Int) -> LocalizedStringResource {
                .init(
                    "mailbox.systemFolder.voiceOver.attachments",
                    defaultValue: "\(count) attachments",
                    comment: "Voice over reads the number of attachments on an item."
                )
            }

            static let unread = LocalizedStringResource(
                "mailbox.systemFolder.voiceOver.unread",
                defaultValue: "Unread",
                comment: "Voice over reads out loud when an item is unread"
            )
        }

        static let compose = LocalizedStringResource(
            "Compose",
            comment: "The compose button title for creating new email."
        )
        static func selected(emailsCount: Int) -> LocalizedStringResource {
            .init(
                "\(emailsCount) Selected",
                comment: "Header indicating number of selected emails in given system folder."
            )
        }
        static let unread = LocalizedStringResource(
            "Unread",
            comment: "Badge title indicating how many emails are unread in given system folder."
        )
        static let selectAll = LocalizedStringResource(
            "Select all",
            comment: "Button title allowing to select all items in a mailbox."
        )
        static let unselectAll = LocalizedStringResource(
            "Unselect all",
            comment: "Button title allowing to deselect all items in a mailbox."
        )
        static let selectionLimitReached = LocalizedStringResource(
            "Maximum selection reached",
            comment: "Toast when attempting to select more than the maximum number of items."
        )
    }

    enum NoConnection {
        static let title = LocalizedStringResource(
            "Your device is offline",
            comment: "Title of the offline mode placeholder."
        )
        static let subtitle = LocalizedStringResource(
            "The message will download when device is back online",
            comment: "Subtitle of the offline mode placeholder."
        )
    }

    enum MessageBanner {
        enum LegitMessageConfirmationAlert {
            static let title = LocalizedStringResource(
                "Mark email as legitimate",
                comment: "Title of the alert asking the user to confirm marking an email as legitimate."
            )
            static let message = LocalizedStringResource(
                "We apologize. This might have been a mistake from our side. Please confirm if you want to mark this email as legitimate.",
                comment: "Message shown in the alert explaining the reason for the 'Mark as legitimate' action."
            )
        }

        static func autoDeleteTitle(remainingTime: String) -> LocalizedStringResource {
            .init(
                "This message will auto-delete in \(remainingTime)",
                comment: "Banner indicating when a message will automatically be deleted."
            )
        }
        static let blockedSenderAction = LocalizedStringResource(
            "Unblock",
            comment: "Action to unblock the sender."
        )
        static let blockedSenderTitle = LocalizedStringResource(
            "You blocked this sender",
            comment: "Banner informing the user that they have blocked this sender."
        )
        static let embeddedImagesAction = LocalizedStringResource(
            "Display",
            comment: "Action to display embedded images."
        )
        static let embeddedImagesTitle = LocalizedStringResource(
            "Display embedded images?",
            comment: "Banner asking if the user wants to display images embedded in the email."
        )
        static func expiryTitle(formattedTime: String) -> LocalizedStringResource {
            .init(
                "This message will expire in \(formattedTime)",
                comment: "Banner indicating when a message will expire and no longer be accessible."
            )
        }
        static let phishingAttemptTitle = LocalizedStringResource(
            "Our system flagged this message as a phishing attempt. Please check to ensure that it is legitimate.",
            comment: "Banner warning the user that the system detected a possible phishing attempt."
        )
        static let remoteContentAction = LocalizedStringResource(
            "Download",
            comment: "Action to download remote content in the email."
        )
        static let remoteContentTitle = LocalizedStringResource(
            "Download images and other remote content?",
            comment: "Banner asking if the user wants to download remote content such as images from external sources."
        )
        static let scheduledSendTitle = LocalizedStringResource(
            "This message will be sent",
            comment: "Banner showing the scheduled send time for an email."
        )
        static let scheduledSendAction = LocalizedStringResource(
            "Edit message",
            comment: "Action to modify a scheduled message."
        )
        static func snoozedTitle(formattedTime: String) -> LocalizedStringResource {
            .init(
                "Snoozed until \(formattedTime)",
                comment: "Banner indicating when a snoozed email will reappear in the inbox."
            )
        }
        static let snoozedAction = LocalizedStringResource(
            "Unsnooze",
            comment: "Action to restore a snoozed email immediately."
        )
        static let spamTitle = LocalizedStringResource(
            "This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded.",
            comment: "Banner warning the user that the email failed authentication checks and may be spoofed."
        )
        static let unsubscribeNewsletterAction = LocalizedStringResource(
            "Unsubscribe",
            comment: "Action to unsubscribe from the mailing list."
        )
        static let unsubscribeNewsletterTitle = LocalizedStringResource(
            "This message is from a mailing list.",
            comment: "Banner indicating that the email is from a mailing list."
        )
    }

    enum EmptyFolderBanner {
        enum Alert {
            static func emptyFolderTitle(folderName: String) -> LocalizedStringResource {
                .init(
                    "Empty \(folderName) Folder",
                    comment: """
                        Empty Spam/Trash Banner: Title for the confirmation alert when the user 
                        is about to empty the specified location (e.g., Spam or Trash).
                        """
                )
            }

            static func emptyFolderMessage(folderName: String) -> LocalizedStringResource {
                .init(
                    "Are you sure you want to permanently delete all messages in the \(folderName) folder? This action cannot be undone.",
                    comment: """
                        Empty Spam/Trash Banner: Message for the confirmation alert asking the user to confirm 
                        permanent deletion of all messages in the specified location (e.g., Spam or Trash).
                        """
                )
            }
        }
        static func emptyNowAction(folderName: String) -> LocalizedStringResource {
            .init(
                "Empty \(folderName) now",
                comment: "Empty Spam/Trash Banner: Action button for deleting all items in the specified location (e.g., Spam or Trash)."
            )
        }
        static let upgradeAction = LocalizedStringResource(
            "Upgrade to Auto-delete",
            comment: "Empty Spam/Trash Banner: Action button to upgrade the account for auto-delete functionality."
        )
        static let freeUserTitle = LocalizedStringResource(
            "Upgrade to automatically remove emails that have been in Trash or Spam for over 30 days.",
            comment: "Empty Spam/Trash Banner: Title shown to free users, encouraging them to upgrade to auto-delete."
        )
        static let paidUserAutoDeleteOnTitle = LocalizedStringResource(
            "Messages in Trash and Spam will be automatically deleted after 30 days.",
            comment: "Empty Spam/Trash Banner: Title for paid users with auto-delete turned on."
        )
        static let paidUserAutoDeleteOffTitle = LocalizedStringResource(
            "Auto-delete is turned off. Messages in trash and spam will remain until you delete them manually.",
            comment: "Empty Spam/Trash Banner: Title for paid users with auto-delete turned off."
        )
    }

    enum MessageDetails {
        static let bcc = LocalizedStringResource("Bcc: ", comment: "`BCC` in the messsage details.")
        static let cc = LocalizedStringResource("Cc: ", comment: "`CC` in the messsage details.")
        static let from = LocalizedStringResource("From: ", comment: "`From` in the message details.")
        static let to = LocalizedStringResource("To: ", comment: "`To` in the message details.")
        static let on = LocalizedStringResource("On: ", comment: "`On` as in on a given date.")
        static func attachments(count: Int) -> LocalizedStringResource {
            .init("\(count) attachments", comment: "The number of a message attachments.")
        }
        static let draft = LocalizedStringResource(
            "(Draft)",
            comment: "Draft suffix displayed in covnersation view."
        )
        static let draftNoRecipientsPlaceholder = LocalizedStringResource(
            "To: ...",
            comment: "Placeholder for a draft in the conversation view when the draft has no recipients."
        )
        static let hideDetails = LocalizedStringResource(
            "Hide details",
            comment: "Title of the button that hide details of a message."
        )
    }

    enum Folders {
        static let doesNotExist = LocalizedStringResource(
            "Could not move to folder. Folder may have been deleted or moved.",
            comment: "Error when trying to move a message to a folder that no longer exists."
        )
    }

    enum Notifications {
        static let title1 = LocalizedStringResource(
            "Don’t miss an email",
            comment: "Title of the authorization prompt"
        )

        static let title2 = LocalizedStringResource(
            "Don’t miss the reply",
            comment: "Title of the authorization prompt"
        )

        static let body1 = LocalizedStringResource(
            "Notifications help you keep on top of your inbox even when you’re in another app.",
            comment: "Body of the authorization prompt"
        )

        static let body2 = LocalizedStringResource(
            "A reply to your email? An important message? Get notified the moment they arrive.",
            comment: "Body of the authorization prompt"
        )

        static let cta = LocalizedStringResource(
            "Allow notifications",
            comment: "Button to authorizate notifications"
        )

        static let dismiss = LocalizedStringResource("Dismiss", comment: "Alert dismiss button")
    }

    enum PINLock {
        enum Error {
            static let tooLong = LocalizedStringResource(
                "PIN cannot exceed 21 digits",
                comment: "Error message when setting up PIN"
            )

            static let tooShort = LocalizedStringResource(
                "PIN must be at least 4 digits",
                comment: "Error message when setting up PIN"
            )

            static let malformed = LocalizedStringResource(
                "PIN must be 4–21 digits long and consist only of numbers",
                comment: "Error message when setting up PIN"
            )
        }

        static let invalidPIN = LocalizedStringResource(
            "Incorrect PIN. Please try again.",
            comment: "Error message when a user enters an invalid PIN"
        )
        static let tooManyAttempts = LocalizedStringResource(
            "Too many incorrect attempts. Please wait before trying again.",
            comment: "Error message when a user enters invalid PIN too many times."
        )
        static let tooFrequentAttempts = LocalizedStringResource(
            "Too many attempts too quickly. Please wait before trying again.",
            comment: "Displayed when the user tries to validate their PIN too frequently."
        )
    }

    enum ReportProblem {
        static let mainTitle = LocalizedStringResource(
            "Report a problem",
            comment: "Report a problem screen main title."
        )
        static let generalInfo = LocalizedStringResource(
            "Reports are not end-to-end encrypted, please do not send any sensitive information.",
            comment: "Report a problem screen, top information."
        )
        static let summary = LocalizedStringResource(
            "Summary (required)",
            comment: "Title of summary text field."
        )
        static let summaryPlaceholder = LocalizedStringResource(
            "The Mail app crashes when opening emails with large attachments.",
            comment: "Placeholder of summary text field."
        )
        static let summaryValidationError = LocalizedStringResource(
            "This field must be more than 10 characters",
            comment: "Summary field validation error"
        )
        static let stepsToReproduce = LocalizedStringResource(
            "Steps to reproduce",
            comment: "Title of steps to reproduce text field."
        )
        static let stepsToReproducePlaceholder = LocalizedStringResource(
            "1. Find an email with a large attachment (ex: video)\n2. Open the email\n3. Wait for the email to load",
            comment: "Placeholder of steps to reproduce text field."
        )
        static let expectedResults = LocalizedStringResource(
            "Expected results",
            comment: "Title of expected results text field."
        )
        static let expectedResultsPlaceholder = LocalizedStringResource(
            "Opening the email should show the message content and the attachments.",
            comment: "Placeholder of expected results text field."
        )
        static let actualResults = LocalizedStringResource(
            "Actual results",
            comment: "Title of actual results text field."
        )
        static let actualResultsPlaceholder = LocalizedStringResource(
            "The Mail app crashes after loading for a few seconds.",
            comment: "Placeholder of actual results text field."
        )
        static let sendErrorLogs = LocalizedStringResource(
            "Send error logs",
            comment: "Title of row with toggle where a user can decide whether to send logs."
        )
        static let submit = LocalizedStringResource(
            "Submit",
            comment: "Title of the button used to submit the form."
        )
        static let logsInfo = LocalizedStringResource(
            "A log is a type of file that shows us the actions you took that led to an error. We’ll only ever use them to help our engineers fix bugs.",
            comment: "Information displayed under send error logs switch."
        )
        static let logsAdditionalInfo = LocalizedStringResource(
            "Error logs help us to get to the bottom of your issue. If you don't include them, we might not be able to investigate fully.",
            comment: "Information displayed in the bottom of the screen when send error logs switch is dislabed."
        )
        static let successToast = LocalizedStringResource(
            "Problem report sent",
            comment: "Toast displayed after the report was successfully sent"
        )
        static let failureToast = LocalizedStringResource(
            "There was an error sending the report, please try again.",
            comment: "Toast displayed after the report failed to send"
        )
        static let offlineFailureToast = LocalizedStringResource(
            "You are currently offline, please try again with internet connection.",
            comment: "Toast displayed after the report failed to send in offline."
        )
        enum DismissConfirmationAlert {
            static let title = LocalizedStringResource(
                "Are you sure you want to close this window?",
                comment: "Report problem dismiss confirmation alert title."
            )
            static let message = LocalizedStringResource(
                "Any information you’ve entered will be lost.",
                comment: "Report problem dismiss confirmation alert message."
            )
        }
    }

    enum Search {
        static let searchPlaceholder = LocalizedStringResource(
            "Search",
            comment: "Search textbox placeholder"
        )
        static let noResultsTitle = LocalizedStringResource(
            "No matches",
            comment: "Search result is empty title"
        )
        static let noResultsSubtitle = LocalizedStringResource(
            "You can either update your search query or clear it.",
            comment: "Search result is empty subtitle"
        )
    }

    enum Session {
        enum Transition {
            static let title = LocalizedStringResource(
                "Loading your mailbox...",
                comment: "Text shown when user session is being initialized."
            )

            static let body = LocalizedStringResource(
                "We’re almost there. Thanks for your patience!",
                comment: "Text shown when user session is being initialized."
            )
        }
    }

    enum Settings {
        enum App {
            static let title = LocalizedStringResource(
                "App customisations",
                comment: "Title of the App settings screen."
            )
            static let deviceSectionTitle = LocalizedStringResource(
                "Device",
                comment: "Device section title in app settings. The section contains configuration like notifications, language, appearance. (App settings)"
            )
            static let notifications = LocalizedStringResource(
                "Notifications",
                comment: "Notifications setting title in app settings."
            )
            static let language = LocalizedStringResource(
                "Language",
                comment: "Language setting title in app settings."
            )
            static let appearance = LocalizedStringResource(
                "Appearance",
                comment: "Appearance setting title in app settings."
            )
            static let system = LocalizedStringResource(
                "System",
                comment: "One of the appearance option to set in app settings."
            )
            static let dark = LocalizedStringResource(
                "Dark",
                comment: "One of the appearance option to set in app settings."
            )
            static let light = LocalizedStringResource(
                "Light",
                comment: "One of the appearance option to set in app settings."
            )
            static let appLock = LocalizedStringResource(
                "App lock",
                comment: "App lock setting title in app settings."
            )
            static let combinedContacts = LocalizedStringResource(
                "Combined contacts",
                comment: "Combined Contacts setting title in app settings."
            )
            static let combinedContactsInfo = LocalizedStringResource(
                "Turn this feature on to auto-complete email addresses using contacts from all your signed in accounts.",
                comment: "Combined Contacts setting additional info in app settings."
            )
            static let mailExperience = LocalizedStringResource(
                "Mail experience",
                comment: "Mail experience section title in app settings."
            )
            static let swipeToNextEmail = LocalizedStringResource(
                "Swipe to next email",
                comment: "Swipe to next email setting title in app settings."
            )
            static let swipeToNextEmailInfo = LocalizedStringResource(
                "Quickly move to the next or previous message in your inbox.",
                comment: "Swipe to next email setting additional info in app settings."
            )
            static let advanced = LocalizedStringResource(
                "Advanced",
                comment: "Advanced section title in app settings."
            )
            static let alternativeRouting = LocalizedStringResource(
                "Alternative routing",
                comment: "Alternative routing setting title in app settings."
            )
            static let alternativeRoutingInfo = LocalizedStringResource(
                "If Proton sites are blocked, this lets the app try other network paths to reach them. It can help bypass firewalls or connection issues. We recommend keeping it on for better reliability.",
                comment: "Alternative routing additional info in app settings."
            )
            static let none = LocalizedStringResource(
                "Don't lock",
                comment: "App lock option."
            )
            static let faceID = LocalizedStringResource(
                "Secure with Face ID",
                comment: "App lock option."
            )
            static let touchID = LocalizedStringResource(
                "Secure with Touch ID",
                comment: "App lock option."
            )
            static let pinCode = LocalizedStringResource(
                "Secure with PIN",
                comment: "App lock option."
            )
            static let protectionSelectionListFooterInformation = LocalizedStringResource(
                "All app lock settings, including the PIN, will reset when you sign out of the app",
                comment: "Protection selection list footer information."
            )
            static let changePINcode = LocalizedStringResource(
                "Change PIN",
                comment: "Change PIN code title."
            )
            static let repeatPIN = LocalizedStringResource(
                "Repeat PIN",
                comment: "Repeat PIN code title."
            )
            static let repeatedPINValidationError = LocalizedStringResource(
                "The PIN codes must match!",
                comment: "Not matching PIN validation error message."
            )
            static let setPINScreenTitle = LocalizedStringResource(
                "Set PIN",
                comment: "Set PIN code screen title."
            )
            static let setPINInputTitle = LocalizedStringResource(
                "New PIN",
                comment: "Set PIN code screen PIN input title."
            )
            static let setPINInformation = LocalizedStringResource(
                "Min 4 characters and max 21 characters",
                comment: "Information displayed under the PIN input."
            )
            static let verifyPINInputTitle = LocalizedStringResource(
                "Current PIN",
                comment: "Verify PIN code screen PIN input title."
            )
            static let verifyPINScreenTitle = LocalizedStringResource(
                "Confirm PIN",
                comment: "Verify PIN code screen title."
            )
            static let autoLock = LocalizedStringResource(
                "Auto-lock",
                comment: "Auto lock button and screen title."
            )
            static let immediately = LocalizedStringResource(
                "Immediately",
                comment: "Auto option."
            )
            static let autoLockNever = LocalizedStringResource(
                "Never",
                comment: "Auto option."
            )
            static func autoLock(minutes: UInt8) -> LocalizedStringResource {
                .init("After \(minutes) minutes", comment: "Auto lock option.")
            }
            static let changePassword = LocalizedStringResource(
                "Change password",
                comment: "Option in the Settings screen."
            )
            static let changeLoginPassword = LocalizedStringResource(
                "Change main password",
                comment: "Option in the Settings screen (if the user has two passwords)."
            )
            static let changeMailboxPassword = LocalizedStringResource(
                "Change second password",
                comment: "Option in the Settings screen (if the user has two passwords)."
            )
            static let securityKeys = LocalizedStringResource(
                "Security keys",
                comment: "Security keys row title"
            )
        }

        static let subscription = LocalizedStringResource(
            "Subscription",
            comment: "Subscription menu title in the settings."
        )
        static let title = LocalizedStringResource("Settings", comment: "Settings menu title.")
        static let account = LocalizedStringResource("Account", comment: "Title of a section in Settings.")
        static let preferences = LocalizedStringResource("Preferences", comment: "Title of a section in Settings.")
        static let email = LocalizedStringResource("Mailbox preferences", comment: "Title of the Email settings item.")
        static let foldersAndLabels = LocalizedStringResource(
            "Folders and labels",
            comment: "Title of the Folders and labels settings item."
        )
        static let filters = LocalizedStringResource(
            "Spam and filters",
            comment: "Title of the Filters settings item."
        )
        static let privacyAndSecurity = LocalizedStringResource(
            "Privacy and security",
            comment: "Title of the Privacy and security settings item."
        )

        static let signInOnAnotherDevice = LocalizedStringResource("Sign in on another device")
    }

    enum Sidebar {
        static let createLabel = LocalizedStringResource(
            "Create a label",
            comment: "Button in the sidebar menu that redirects a user to the create label screen."
        )
        static let createFolder = LocalizedStringResource(
            "Create a folder",
            comment: "Button in the sidebar menu that redirects a user to the create folder screen."
        )
        static let contacts = LocalizedStringResource(
            "Contacts",
            comment: "Button in the sidebar menu that redirects a user to the contacts screen."
        )
        static let bugReport = LocalizedStringResource(
            "Report a problem",
            comment: "Button in the sidebar menu that redirects a user to the bug report screen."
        )
    }

    enum Snooze {
        static let customSnoozeSheetTitle = LocalizedStringResource(
            "Snooze message",
            comment: "Title of the sheet for configuring custom snooze settings."
        )
        static let snoozeUntil = LocalizedStringResource(
            "Snooze until",
            comment: "Title of the sheet for snooze settings."
        )
        static let unsnoozeButtonTitle = LocalizedStringResource(
            "Unsnooze",
            comment: "Unsnooze button title on snooze sheet."
        )
        static let customButtonTitle = LocalizedStringResource(
            "Custom",
            comment: "Custom button title on snooze sheet."
        )
        static let customButtonSubtitle = LocalizedStringResource(
            "Pick time and date",
            comment: "Custom button subtitle on snooze sheet."
        )
        static let snoozeTomorrow = LocalizedStringResource(
            "Tomorrow",
            comment: "Predefined snooze option that postpones item until tomorrow."
        )
        static let snoozeLaterThisWeek = LocalizedStringResource(
            "Later this week",
            comment: "Predefined snooze option that postpones item until later in the current week."
        )
        static let snoozeNextWeek = LocalizedStringResource(
            "Next week",
            comment: "Predefined snooze option that postpones item until the following week."
        )
        static let snoozeThisWeekend = LocalizedStringResource(
            "This weekend",
            comment: "Predefined snooze option that postpones item until the upcoming weekend."
        )
        static let upsellButtonSubtitle = LocalizedStringResource(
            "Upgrade for full flexibility",
            comment: "Custom button subtitle for a free user on snooze sheet."
        )
        static let smallUpsellButtonSubtitle = LocalizedStringResource(
            "Upgrade to Mail Plus",
            comment: "Custom button subtitle for a free user on snooze sheet."
        )
        static let conversationUnsnoozed = LocalizedStringResource(
            "Conversation unsnoozed",
            comment: "Toast message after unsnooze action"
        )
    }

    enum Toast {
        static let deleted = LocalizedStringResource(
            "Deleted.",
            comment: "Title of information toast about a message deletion"
        )
        static func movedTo(destination: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "Moved to \(destination).",
                comment: "Title of a message move information toast"
            )
        }
    }

    enum Notification {
        enum EmailNotSent {
            static let title = LocalizedStringResource(
                "Email not sent",
                comment: "Notification that is displayed when background time is up and at least one message is unsent."
            )
            static let body = LocalizedStringResource(
                "Some emails couldn't be sent. Open the app to finish sending.",
                comment: "Notification that is displayed when background time is up and at least one message is unsent."
            )
        }
    }

    enum CreateFolderOrLabel {
        static let title = LocalizedStringResource(
            "Create folder or label",
            comment: "Title of the web view presenting custom folders and labels"
        )
    }

    static func messages(count: Int) -> LocalizedStringResource {
        .init("\(count) messages", comment: "Number of messages in a conversation.")
    }
    static let official = LocalizedStringResource("Official", comment: "Proton official badge title.")
}
