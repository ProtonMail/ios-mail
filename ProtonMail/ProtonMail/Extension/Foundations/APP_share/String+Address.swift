// Copyright (c) 2023 Proton Technologies AG
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

extension String {
    /**
     String extension check is email valid use the basic regex

     :returns: true | false
     */
    static let emailRegEx = "(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}" +
    "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" +
    "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-" +
    "z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5" +
    "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" +
    "9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" +
    "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
    static let emailTest = NSPredicate(format: "SELF MATCHES[c] %@", String.emailRegEx)

    func isValidEmail() -> Bool {
        return String.emailTest.evaluate(with: self)
    }

    /**
     * Canonicalize an email address following one of the known schemes
     * Emails that have the same canonical form end up in the same inbox
     * See https://confluence.protontech.ch/display/MBE/Canonize+email+addresses
     */
    func canonicalizeEmail(scheme: CanonicalizeScheme = .default) -> String {
        if case .default = scheme {
            return self.lowercased()
        }

        let (localPart, domain) = emailAddressParts()
        let cleanLocalPart = localPart.removePlusAliasLocalPart().lowercased()
        var normalizedLocalPart = cleanLocalPart
        if let regex = scheme.regex {
            normalizedLocalPart = normalizedLocalPart.preg_replace(regex, replaceto: "")
        }

        if let domain {
            return "\(normalizedLocalPart)@\(domain.lowercased())"
        } else {
            return normalizedLocalPart
        }
    }

    func emailAddressParts() -> (localPart: String, domain: String?) {
        guard isValidEmail(),
              let atIndex = lastIndex(of: "@") else { return (self, nil) }
        let localPart = String(self[startIndex..<atIndex])
        let domainIndex = self.index(after: atIndex)
        let domain = String(self[domainIndex..<endIndex])
        return (localPart, domain)
    }

    private func removePlusAliasLocalPart() -> String {
        components(separatedBy: "+").first ?? self
    }
}
