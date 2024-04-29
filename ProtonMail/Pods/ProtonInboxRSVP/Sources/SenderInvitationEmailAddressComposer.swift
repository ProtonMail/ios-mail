// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

public enum SenderInvitationEmailAddressComposer {

    public static func senderEmail(fromUserAddressEmail addressEmail: String, invitedEmail: String) -> String {
        guard
            addressEmail != invitedEmail,
            let parsedAddressEmail = EmailParser.parsed(email: addressEmail),
            let parsedInvitedEmail = EmailParser.parsed(email: invitedEmail)
        else {
            return addressEmail
        }

        let composedLocalPart: String = [parsedAddressEmail.localPart, parsedInvitedEmail.label]
            .compactMap { $0 }
            .joined(separator: EmailParser.labelSeparatorSymbol)

        return [composedLocalPart, EmailParser.atSymbol, parsedAddressEmail.domainName].joined()
    }

    private enum EmailParser {

        struct AddressEmail {
            let localPart: String
            let domainName: String

            var label: String? {
                let localPartComponents = localPart.components(separatedBy: labelSeparatorSymbol)
                return localPartComponents.count > 1 ? localPartComponents.last : nil
            }
        }

        static let atSymbol = "@"
        static let labelSeparatorSymbol = "+"

        static func parsed(email: String) -> AddressEmail? {
            let emailComponents = email.components(separatedBy: atSymbol)

            guard let localPart = emailComponents[safe: 0], let domainName = emailComponents[safe: 1] else {
                return nil
            }

            return .init(localPart: localPart, domainName: domainName)
        }

    }

}
