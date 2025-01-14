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

        static let draftLoadedOffline =  LocalizedStringResource(
            "You're currently offline. This draft may not be up-to-date.",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Draft might not be up-to-date when loaded"
        )

        static let send =  LocalizedStringResource(
            "Send",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Message send button."
        )

        static let to =  LocalizedStringResource(
            "To:",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer to recipients."
        )

        static let from =  LocalizedStringResource(
            "From:",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer from field."
        )

        static let subject =  LocalizedStringResource(
            "Subject:",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer subject."
        )

        static let draftSaved =  LocalizedStringResource(
            "Draft saved",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message when dismissing the screen."
        )

        static let messageSending =  LocalizedStringResource(
            "Message will be sent shortly", // FIXME: Using this for v2
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message when sent is tapped."
        )

        static let messageSent =  LocalizedStringResource(
            "Message sent",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer toast message after sent."
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
    }
}
