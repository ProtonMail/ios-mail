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

        enum Send {
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
                        comment: "Title of alert action displayed after delete permanently action tap."
                    )
                }

                static func message(itemsCount: Int) -> LocalizedStringResource {
                    .init(
                        "Are you sure you want to delete these \(itemsCount) messages permanently?",
                        comment: "Title of alert action displayed after delete permanently action tap."
                    )
                }
            }
        }
    }

    enum Common {
        static let done = LocalizedStringResource("Done", comment: "`Done` action title.")
        static let cancel = LocalizedStringResource("Cancel", comment: "`Cancel` action title.")
        static let delete = LocalizedStringResource("Delete", comment: "`Delete` action title.")
    }

    enum Labels {
        static let alsoArchive = LocalizedStringResource(
            "Also archive?",
            comment: "Switch title for moving message to `Archive` folder."
        )
        static let newLabel = LocalizedStringResource(
            "Create new label",
            comment: "Action title for creating new label."
        )
        static let title = LocalizedStringResource("Labels", comment: "Labels screen title.")
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
        }

        enum SystemFolder {
            static let allDrafts = LocalizedStringResource(
                "All Drafts",
                comment: "Menu title of all drafts in the sidebar."
            )
            static let allMail = LocalizedStringResource(
                "All Mail",
                comment: "`Menu title of all emails in the sidebar."
            )
            static let allScheduled = LocalizedStringResource(
                "Scheduled",
                comment: "Menu title of all scheduled emails in the sidebar."
            )
            static let allSent = LocalizedStringResource(
                "All Sent",
                comment: "Menu title of all sent emails in the sidebar."
            )
            static let archive = LocalizedStringResource(
                "Archive",
                comment: "Menu title of all archived emails in the sidebar."
            )
            static let draft = LocalizedStringResource(
                "Draft",
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
    }

    enum MessageDetails {
        static let bcc = LocalizedStringResource("Bcc", comment: "`BCC` in the messsage details.")
        static let cc = LocalizedStringResource("Cc", comment: "`CC` in the messsage details.")
        static let date = LocalizedStringResource("Date", comment: "`Date` in the message details.")
        static let from = LocalizedStringResource("From", comment: "`From` in the message details.")
        static let label = LocalizedStringResource("Label", comment: "`Label` in the message details.")
        static let location = LocalizedStringResource("Location",comment: "`Location` in the message details.")
        static let other = LocalizedStringResource(
            "Other",
            comment: "`Other` in the message details (e.g. starred, pinned messages)."
        )
        static let to = LocalizedStringResource("To", comment: "`To` in the message details.")
        static func attachments(count: Int) -> LocalizedStringResource {
            .init("\(count) attachments", comment: "The number of a message attachments.")
        }
    }

    enum Folders {
        static let newFolder = LocalizedStringResource(
            "Create new folder",
            comment: "Action title for creating new folder."
        )
        static let title = LocalizedStringResource("Move to..", comment: "Folders title screen.")
    }

    enum Search {
        static let searchPlaceholder = LocalizedStringResource(
            "Search",
            comment: "Search textbox placeholder"
        )
        static let cancel = LocalizedStringResource(
            "search.dismiss",
            defaultValue: "Cancel",
            comment: "Search screen dismiss"
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

    enum Settings {
        static let accountSettings = LocalizedStringResource(
            "Account Settings",
            comment: "Account settings screen title."
        )
        static let subscription = LocalizedStringResource(
            "Subscription",
            comment: "Subscription menu title in the settings."
        )
        static let title = LocalizedStringResource("Settings", comment: "Settings menu title.")
        static let account = LocalizedStringResource("Account", comment: "Title of a section in Settings.")
        static let preferences = LocalizedStringResource("Preferences", comment: "Title of a section in Settings.")
        static let email = LocalizedStringResource("Email", comment: "Title of the Email settings item.")
        static let emailSubtitle = LocalizedStringResource(
            "Email and mailbox preferences",
            comment: "Subtitle of the Email settings item."
        )
        static let foldersAndLabels = LocalizedStringResource(
            "Folders and labels",
            comment: "Title of the Folders and labels settings item."
        )
        static let foldersAndLabelsSubtitle = LocalizedStringResource(
            "Mailbox organization",
            comment: "Subtitle of the Folders and labels settings item."
        )
        static let filters = LocalizedStringResource(
            "Spam and custom filters",
            comment: "Title of the Filters settings item."
        )
        static let filtersSubtitle = LocalizedStringResource(
            "Automatic actions and sorting",
            comment: "Subtitle of the Filters settings item."
        )
        static let privacyAndSecurity = LocalizedStringResource(
            "Privacy and security",
            comment: "Title of the Privacy and security settings item."
        )
        static let privacyAndSecuritySubtitle = LocalizedStringResource(
            "Email tracking protection",
            comment: "Subtitle of the Privacy and security settings item."
        )
        static let appSettingsTitle = LocalizedStringResource(
            "App",
            comment: "Title of the App settings item."
        )
        static let appSettingsSubtitle = LocalizedStringResource(
            "Mobile app customization",
            comment: "Subtitle of the App settings item."
        )
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
            "Bug report",
            comment: "Button in the sidebar menu that redirects a user to the bug report screen."
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

    enum CreateFolderOrLabel {
        static let title = LocalizedStringResource(
            "Create folder or label",
            comment: "Title of the web view presenting custom folders and labels"
        )
    }

    static func files(attachmentsCount: Int) -> LocalizedStringResource {
        .init("\(attachmentsCount) files", comment: "The number of attachments on conversation details screen.")
    }
    static let official = LocalizedStringResource("Official", comment: "Proton official badge title.")
}
