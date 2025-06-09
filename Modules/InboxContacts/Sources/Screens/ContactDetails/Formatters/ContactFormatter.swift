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

import proton_app_uniffi

enum ContactFormatter {
    enum Address {
        static func formatted(from address: ContactDetailAddress) -> ContactDetailsItem {
            let codeAndCity: String = [address.postalCode, address.city]
                .compactMap(\.?.nonEmpty)
                .joined(separator: " ")
            let formattedAddress: String = [address.street, codeAndCity]
                .compactMap(\.?.nonEmpty)
                .joined(separator: ", ")
            let label = address.addrType.displayType(fallback: "Address")

            return .init(label: label, value: formattedAddress, isInteractive: true)
        }
    }

    enum Gender {
        static func formatted(from gender: GenderKind) -> ContactDetailsItem {
            .init(label: "Gender", value: gender.humanReadable, isInteractive: false)
        }
    }

    enum Telephone {
        static func formatted(from telephone: ContactDetailsTelephones) -> ContactDetailsItem {
            let label = telephone.telTypes.displayType(fallback: "Phone")

            return .init(label: label, value: telephone.number, isInteractive: true)
        }
    }

    enum URL {
        static func formatted(from vcardURL: VCardUrl) -> ContactDetailsItem {
            let label = vcardURL.urlType.displayType(fallback: "URL")

            return .init(label: label, value: vcardURL.url, isInteractive: true)
        }
    }
}

private extension Array where Element == VcardPropType {

    func displayType(fallback: String) -> String {
        first?.displayType ?? fallback
    }

}

private extension GenderKind {

    var humanReadable: String {
        switch self {
        case .male:
            "Male"
        case .female:
            "Female"
        case .other:
            "Other"
        case .notApplicable:
            "Not applicable"
        case .unknown:
            "Unknown"
        case .none:
            "None"
        case .string(let string):
            string
        }
    }

}

private extension VcardPropType {

    var displayType: String {
        switch self {
        case .home:
            "Home"
        case .work:
            "Work"
        case .text:
            "Text"
        case .voice:
            "Voice"
        case .fax:
            "Fax"
        case .cell:
            "Cell"
        case .video:
            "Video"
        case .pager:
            "Pager"
        case .textPhone:
            "Text phone"
        case .string(let string):
            string
        }
    }

}

private extension String {

    var nonEmpty: String? {
        isEmpty ? nil : self
    }

}
