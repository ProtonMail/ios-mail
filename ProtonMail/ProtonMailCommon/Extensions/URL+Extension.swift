//
//  URL+Extension.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

extension URL {
    mutating func excludeFromBackup() {
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try setResourceValues(resourceValues)
        } catch let ex as NSError {
            assert(false, " path: \(absoluteString) excludeFromBackup error: \(ex)")
        }
    }

    struct MailtoData {
        var to: [String] = []
        var cc: [String] = []
        var bcc: [String] = []
        var subject: String?
        var body: String?
    }

    func parseMailtoLink() -> MailtoData? {

        func splitMails(_ email: String) -> [String] {
            return email.split(separator: ",").map(String.init)
        }

        guard let urlComponment = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return nil
        }

        guard urlComponment.scheme == "mailto" else {
            return nil
        }

        let queryItems = urlComponment.queryItems

        var result = MailtoData()

        // to
        result.to = urlComponment.path.isEmpty ? [] : splitMails(urlComponment.path)

        queryItems?.forEach({ (queryItem) in
            guard let value = queryItem.value else {
                return
            }
            switch queryItem.name {
            case "cc":
                result.cc += splitMails(value)
            case "bcc":
                result.bcc += splitMails(value)
            case "subject" where result.subject == nil:
                result.subject = value
            case "body" where result.body == nil:
                result.body = value
            default:
                break
            }
        })

        return result
    }

    func removeProtonSchemeIfNeeded() -> URL {
        guard self.scheme == "pm-incoming-mail" else {
            return self
        }

        var link = "https:/\(self.path)"
        if let query = self.query {
            link = "\(link)?\(query)"
        }
        if let newURL = URL(string: link) {
            return newURL
        }
        // Not sure how this situation could happen
        return self
    }
}
