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

import Contacts
import InboxCore
import proton_app_uniffi

enum ContactFormatter {
    enum Address {
        static func formatted(from address: ContactDetailAddress) -> ContactDetailsItem {
            let mutableAddress = CNMutablePostalAddress()

            if let address = address.street {
                mutableAddress.street = address
            }
            if let city = address.city {
                mutableAddress.city = city
            }
            if let region = address.region {
                mutableAddress.state = region
            }
            if let postalCode = address.postalCode {
                mutableAddress.postalCode = postalCode
            }
            if let country = address.country {
                mutableAddress.country = country
            }

            let label = address.addrType.humanReadable(fallback: L10n.ContactDetails.Label.address.string)
            let formatter = CNPostalAddressFormatter()
            let formattedAddress = formatter.string(from: mutableAddress)

            return .init(label: label, value: formattedAddress, isInteractive: false)
        }
    }

    enum Date {
        static func formatted(from date: ContactDate, with label: String) -> ContactDetailsItem {
            let formattedDate: String

            switch date {
            case .string(let string):
                formattedDate = string
            case .date(let partialDate):
                var dateComponents = DateComponents()
                dateComponents.year = partialDate.year.map(Int.init)
                dateComponents.month = partialDate.month.map(Int.init)
                dateComponents.day = partialDate.day.map(Int.init)

                let date = DateEnvironment.calendarUTC.date(from: dateComponents).unsafelyUnwrapped

                formattedDate = formatter.string(from: date)
            }

            return .init(label: label, value: formattedDate, isInteractive: false)
        }

        private static let formatter: DateFormatter = {
            let formatter = DateFormatter.fromEnvironmentCalendar(timeZone: DateEnvironment.calendarUTC.timeZone)
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter
        }()
    }

    enum Gender {
        static func formatted(from gender: GenderKind) -> ContactDetailsItem {
            let label = L10n.ContactDetails.Label.gender.string

            return .init(label: label, value: gender.humanReadable.string, isInteractive: false)
        }
    }

    enum Telephone {
        static func formatted(from telephone: ContactDetailsTelephones) -> ContactDetailsItem {
            let label = telephone.telTypes.humanReadable(fallback: L10n.ContactDetails.Label.phone.string)

            return .init(label: label, value: telephone.number, isInteractive: true)
        }
    }

    enum URL {
        static func formatted(from vcardURL: VCardUrl) -> ContactDetailsItem {
            let label = vcardURL.urlType.humanReadable(fallback: L10n.ContactDetails.Label.url.string)

            return .init(label: label, value: vcardURL.url, isInteractive: true)
        }
    }

    enum Email {
        static func formatted(from email: ContactDetailsEmail) -> ContactDetailsItem {
            let label = email.emailType.humanReadable(fallback: L10n.ContactDetails.Label.email.string)

            return .init(label: label, value: email.email, isInteractive: true)
        }
    }
}

private extension Array where Element == VcardPropType {

    func humanReadable(fallback: String) -> String {
        first?.humanReadable.string ?? fallback
    }

}

private extension GenderKind {

    var humanReadable: LocalizedStringResource {
        switch self {
        case .male:
            L10n.ContactDetails.Gender.male
        case .female:
            L10n.ContactDetails.Gender.female
        case .other:
            L10n.ContactDetails.Gender.other
        case .notApplicable:
            L10n.ContactDetails.Gender.notApplicable
        case .unknown:
            L10n.ContactDetails.Gender.unknown
        case .none:
            L10n.ContactDetails.Gender.none
        case .string(let string):
            string.firstUppercased.stringResource
        }
    }

}

private extension VcardPropType {

    var humanReadable: LocalizedStringResource {
        switch self {
        case .home:
            L10n.ContactDetails.VcardType.home
        case .work:
            L10n.ContactDetails.VcardType.work
        case .text:
            L10n.ContactDetails.VcardType.text
        case .voice:
            L10n.ContactDetails.VcardType.voice
        case .fax:
            L10n.ContactDetails.VcardType.fax
        case .cell:
            L10n.ContactDetails.VcardType.cell
        case .video:
            L10n.ContactDetails.VcardType.video
        case .pager:
            L10n.ContactDetails.VcardType.pager
        case .textPhone:
            L10n.ContactDetails.VcardType.textPhone
        case .string(let string):
            string.firstUppercased.stringResource
        }
    }

}

private extension String {

    var firstUppercased: String {
        prefix(1).uppercased() + dropFirst()
    }

}
