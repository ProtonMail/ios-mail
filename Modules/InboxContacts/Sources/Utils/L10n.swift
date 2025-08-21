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
    enum Contacts {
        enum EmptyState {
            static let title = LocalizedStringResource(
                "No contacts yet",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Contacts screen's empty state title."
            )
            static let subtitle = LocalizedStringResource(
                "You don't have any contacts.",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Contacts screen's empty state subtitle."
            )
        }
        static let title = LocalizedStringResource(
            "Contacts",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Title of the contacts screen that displays contacts and contact groups."
        )
        static func groupSubtitle(membersCount: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "\(membersCount) members",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Contact group row subtitle."
            )
        }

        enum DeletionAlert {
            static func title(name: String) -> LocalizedStringResource {
                LocalizedStringResource(
                    "Delete \(name)",
                    bundle: .atURL(Bundle.module.bundleURL),
                    comment: "Title for the alert shown when deleting a contact or contact group."
                )
            }
            enum Contact {
                static let message = LocalizedStringResource(
                    "This contact will be deleted from your contact list.",
                    bundle: .atURL(Bundle.module.bundleURL),
                    comment: "Message for the alert shown when deleting a contact."
                )
            }

            enum ContactGroup {
                static let message = LocalizedStringResource(
                    "This contact group will be deleted from your contact list.",
                    bundle: .atURL(Bundle.module.bundleURL),
                    comment: "Message for the alert shown when deleting a contact group."
                )
            }
        }

        enum Error {
            static let unknownContentId = LocalizedStringResource(
                "Attachment not found. Refresh the page or upload it again.",
                comment: "Error message."
            )
            static let unknownLabel = LocalizedStringResource(
                "Label does not exist. You can create it as a new label.",
                comment: "Error message."
            )
            static let unknownMessage = LocalizedStringResource(
                "Message was not found",
                comment: "Error message."
            )
        }

        enum CreateInWebPrompt {
            static let title = LocalizedStringResource(
                "Available in web",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Title of the prompt informing the user that this action is only available in the web app."
            )
            static let subtitle = LocalizedStringResource(
                "Creating contacts or groups in the app is not yet ready. For now, you can create them in the web app and they’ll sync to your device.",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Subtitle explaining that creating contacts or groups is not yet supported in the app and must be done on the web."
            )
            static let actionButtonTitle = LocalizedStringResource(
                "Create in web",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label for the button that opens the web app to create a contact or group."
            )
        }
    }
    enum ContactDetails {
        static let newMessage = LocalizedStringResource(
            "Message",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Contact details’ “Message” button title for creating a new message to the given contact."
        )
        static let call = LocalizedStringResource(
            "Call",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Contact details’ “Call” button title for calling the given contact."
        )
        static let share = LocalizedStringResource(
            "Share",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Contact details’ “Share” button title for sharing the given contact’s information."
        )

        enum Label {
            static let address = LocalizedStringResource(
                "Address",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Address label in contact details."
            )
            static let anniversary = LocalizedStringResource(
                "Anniversary",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Anniversary label in contact details."
            )
            static let birthday = LocalizedStringResource(
                "Birthday",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Birthday label in contact details."
            )
            static let email = LocalizedStringResource(
                "Email",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Email label in contact details."
            )
            static let gender = LocalizedStringResource(
                "Gender",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Gender label in contact details."
            )
            static let language = LocalizedStringResource(
                "Language",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Language label in contact details."
            )
            static let member = LocalizedStringResource(
                "Member",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Member label in contact details."
            )
            static let note = LocalizedStringResource(
                "Note",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Note label in contact details."
            )
            static let organization = LocalizedStringResource(
                "Organization",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Organization label in contact details."
            )
            static let phone = LocalizedStringResource(
                "Phone",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Phone label in contact details."
            )
            static let role = LocalizedStringResource(
                "Role",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Role label in contact details."
            )
            static let timeZone = LocalizedStringResource(
                "Time zone",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Time zone label in contact details."
            )
            static let title = LocalizedStringResource(
                "Title",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Title label in contact details."
            )
            static let url = LocalizedStringResource(
                "URL",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "URL label in contact details."
            )
        }

        enum Gender {
            static let male = LocalizedStringResource(
                "Male",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label representing the male gender in contact details."
            )
            static let female = LocalizedStringResource(
                "Female",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label representing the female gender in contact details."
            )
            static let other = LocalizedStringResource(
                "Other",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label representing a non-binary or other gender in contact details."
            )
            static let notApplicable = LocalizedStringResource(
                "Not applicable",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label used when gender is not applicable in contact details."
            )
            static let unknown = LocalizedStringResource(
                "Unknown",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label used when gender is unknown in contact details."
            )
            static let none = LocalizedStringResource(
                "None",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label used when no gender is specified in contact details."
            )
        }

        enum VcardType {
            static let home = LocalizedStringResource(
                "Home",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label representing a home contact detail type (e.g., phone, address)."
            )
            static let work = LocalizedStringResource(
                "Work",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label representing a work contact detail type (e.g., phone, address)."
            )
            static let text = LocalizedStringResource(
                "Text",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label indicating that the contact method supports text messaging."
            )
            static let voice = LocalizedStringResource(
                "Voice",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label indicating that the contact method supports voice calls."
            )
            static let fax = LocalizedStringResource(
                "Fax",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label indicating that the contact method is a fax number."
            )
            static let cell = LocalizedStringResource(
                "Cell",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label indicating a mobile or cellular contact number."
            )
            static let video = LocalizedStringResource(
                "Video",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label indicating that the contact method supports video calls."
            )
            static let pager = LocalizedStringResource(
                "Pager",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label indicating a pager contact method."
            )
            static let textPhone = LocalizedStringResource(
                "Text phone",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Label indicating a specialized phone for text communication (e.g., for the hearing impaired)."
            )
        }
    }

    enum ContactGroupDetails {
        enum NewMessageButton {
            static let title = LocalizedStringResource(
                "Send group message",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Title of the button used to initiate sending a message to a contact group."
            )
            static func subtitle(contactsCount: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "\(contactsCount) contacts",
                    bundle: .atURL(Bundle.module.bundleURL),
                    comment: "Subtitle showing the number of contacts in the group. Used under the 'Send group message' button."
                )
            }
        }
    }
}
