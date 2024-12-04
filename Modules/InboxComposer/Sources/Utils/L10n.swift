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

        static let subject =  LocalizedStringResource(
            "Subject:",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "Composer subject."
        )
    }

    enum Contacts {
        static let title = LocalizedStringResource(
            "Composer",
            bundle: .atURL(Bundle.module.bundleURL),
            comment: "This is a testing string."
        )

        static func groupSubtitle(membersCount: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "\(membersCount) members",
                bundle: .atURL(Bundle.module.bundleURL),
                comment: "Contact group row subtitle in contact picker."
            )
        }
    }
}
