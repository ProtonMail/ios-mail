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
                "Tap + to add your first contact.",
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
            static let cancel = LocalizedStringResource(
                "Cancel",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Action title for cancelling deletion of given item."
            )
            static let confirm = LocalizedStringResource(
                "Confirm",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Action title for confirming deletion of given item."
            )

            enum Contact {
                static let title = LocalizedStringResource(
                    "Delete contact",
                    bundle: .atURL(Bundle.module.bundleURL),
                    comment: "Title for the alert shown when deleting a contact."
                )
                static let message = LocalizedStringResource(
                    "Deleting the contact will reload the list and no longer show the contact.",
                    bundle: .atURL(Bundle.module.bundleURL),
                    comment: "Message for the alert shown when deleting a contact."
                )
            }

            enum ContactGroup {
                static let title = LocalizedStringResource(
                    "Delete contact group",
                    bundle: .atURL(Bundle.module.bundleURL),
                    comment: "Title for the alert shown when deleting a contact group."
                )
                static let message = LocalizedStringResource(
                    "Deleting the contact group will reload the list and no longer show the contact group.",
                    bundle: .atURL(Bundle.module.bundleURL),
                    comment: "Message for the alert shown when deleting a contact group."
                )
            }
        }
    }
}
