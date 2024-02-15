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

import Foundation

extension String {

    /**
     Canonicalize given email address depends on the domain
     */
    public var canonicalizedEmailAddress: String {
        guard contains("@") else {
            return self
        }
        let mailComponents = self.components(separatedBy: "@")
        var userPart = mailComponents[0]
        let domainPart = mailComponents[1]

        let reverseDomainParts = String(domainPart.reversed()).components(separatedBy: ".")

        let topLevelDomain = String(reverseDomainParts[0].reversed()).lowercased()
        let secondLevelDomain: String = {
            let secondLevel = reverseDomainParts.count > 1 ? reverseDomainParts[1] : ""
            return String(secondLevel.reversed()).lowercased()
        }()

        let domainRegex = DOMAIN_CANONIZE_REGEX[secondLevelDomain]?[topLevelDomain] ?? REGEX_NONE
        userPart = userPart.performRegularExpressionAndReplace(domainRegex, to: "")

        return [userPart, domainPart].joined(separator: "@").lowercased()
    }

    private func performRegularExpressionAndReplace(_ pattern: String, to string: String) -> String {
        if pattern.isEmpty {
            return self
        }

        let options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let replacedString = regex.stringByReplacingMatches(in: self,
                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                range: NSRange(location: 0, length: count),
                withTemplate: string
            )
            if !replacedString.isEmpty, replacedString.count > 0 {
                return replacedString
            }
        } catch {}
        return self
    }

    private var REGEX_PROTONMAIL: String { "\\+.*$|\\.|-|_" }
    private var REGEX_GMAIL: String { "\\+.*$|\\." }
    private var REGEX_PLUS: String { "\\+.*$" }
    private var REGEX_NONE: String { "" }
    private var DOMAIN_CANONIZE_REGEX: [String: [String: String]] {
        ["proton": ["black": REGEX_PROTONMAIL, "dev": REGEX_PROTONMAIL, "me": REGEX_PROTONMAIL],
         "protonmail": ["com": REGEX_PROTONMAIL, "ch": REGEX_PROTONMAIL, "dev": REGEX_PROTONMAIL],
         "pm": ["me": REGEX_PROTONMAIL],
         "gmail": ["com": REGEX_GMAIL],
         "yahoo": ["com": REGEX_NONE, "fr": REGEX_NONE, "co.uk": REGEX_NONE],
         "hotmail": ["com": REGEX_PLUS, "fr": REGEX_PLUS, "co.uk": REGEX_PLUS],
         "aol": ["com": REGEX_NONE],
         "outlook": ["com": REGEX_PLUS],
         "tutanota": ["com": REGEX_NONE],
         "gmx": ["de": REGEX_NONE],
         "yandex": ["ru": REGEX_PLUS],
         "mail": ["ru": REGEX_PLUS]]
    }

}
