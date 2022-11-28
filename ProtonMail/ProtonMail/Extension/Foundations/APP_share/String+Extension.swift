//
//  StringExtension.swift
//  Proton Mail - Created on 2/23/15.
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

extension String {
    func contains(check s: String) -> Bool {
        return self.range(of: s, options: NSString.CompareOptions.caseInsensitive) != nil ? true : false
    }

    func hasRe () -> Bool {
        let re = LocalString._composer_short_reply
        let checkCount = re.count
        if self.count < checkCount {
            return false
        }
        let index = self.index(self.startIndex, offsetBy: checkCount)
        let check = String(self[..<index])
        return check.range(of: re, options: [.caseInsensitive, .anchored]) != nil
    }

    func hasFwd () -> Bool {
        let fwd = LocalString._composer_short_forward
        let checkCount = fwd.count
        if self.count < checkCount {
            return false
        }
        let index = self.index(self.startIndex, offsetBy: checkCount)
        let check = String(self[..<index])
        return check.range(of: fwd, options: [.caseInsensitive, .anchored]) != nil
    }

    func hasFw () -> Bool {
        let fw = LocalString._composer_short_forward_shorter
        let checkCount = fw.count
        if self.count < checkCount {
            return false
        }
        let index = self.index(self.startIndex, offsetBy: checkCount)
        let check = String(self[..<index])
        return check.range(of: fw, options: [.caseInsensitive, .anchored]) != nil
    }

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
     String extension for remove the whitespaces begain&end
     
     Example:
     " adsf " => "adsf"
     
     :returns: trimed string value
     */
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func ln2br() -> String {
        let out = self.replacingOccurrences(of: "\r\n", with: "<br />")
        return out.replacingOccurrences(of: "\n", with: "<br />")
    }

    func rmln() -> String {
        return  self.replacingOccurrences(of: "\n", with: "")
    }

    func lr2lrln() -> String {
        return self.replacingOccurrences(of: "\r", with: "\r\n")
            .replacingOccurrences(of: "\r\n\n", with: "\r\n")
    }

    /**
     String extension decode some encoded htme tags
     
     :returns: String
     */
    func decodeHtml() -> String {
        self.preg_replace_none_regex("&amp;", replaceto: "&")
            .preg_replace_none_regex("&quot;", replaceto: "\"")
            .preg_replace_none_regex("&#039;", replaceto: "'")
            .preg_replace_none_regex("&#39;", replaceto: "'")
            .preg_replace_none_regex("&lt;", replaceto: "<")
            .preg_replace_none_regex("&gt;", replaceto: ">")
    }

    func encodeHtml() -> String {
        self.preg_replace_none_regex("&", replaceto: "&amp;")
            .preg_replace_none_regex("\"", replaceto: "&quot;")
            .preg_replace_none_regex("'", replaceto: "&#039;")
            .preg_replace_none_regex("<br>", replaceto: "\r\n")
            .preg_replace("<br\\s{0,}/{0,1}>", replaceto: "\r\n")
            .preg_replace_none_regex("<", replaceto: "&lt;")
            .preg_replace_none_regex(">", replaceto: "&gt;")
            .preg_replace_none_regex("\r\n", replaceto: "<br />")
    }

    func preg_replace_none_regex(_ pattern: String, replaceto: String) -> String {
        self.replacingOccurrences(of: pattern, with: replaceto, options: .caseInsensitive, range: nil)
    }

    func preg_replace (_ pattern: String, replaceto: String) -> String {
        let options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let replacedString = regex.stringByReplacingMatches(in: self,
                                                                options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                                                range: NSRange(location: 0, length: self.count),
                                                                withTemplate: replaceto)
            if !replacedString.isEmpty && replacedString.count > 0 {
                return replacedString
            }
        } catch {
        }
        return self
    }

    func preg_match(_ pattern: String) -> Bool {
        let options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            return regex.firstMatch(in: self,
                                    options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                    range: NSRange(location: 0, length: self.count)) != nil
        } catch {
        }
        return false
    }

    func hasRemoteImage() -> Bool {
        if self.preg_match("\\ssrc='(?!cid:)|\\ssrc=\"(?!(cid:|data:image))|xlink:href=|poster=|background=|url\\(|url&#40;|url&#x28;|url&lpar;") {
            return true
        }
        return false
    }

    static func randomString(_ len: Int) -> String {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString: NSMutableString = NSMutableString(capacity: len)
        let length = UInt32(letters.length)
        for _ in 0 ..< len {
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        return randomString as String
    }

    static func randomEmailAddress() -> String {
        let name = String.randomString(Int.random(in: 1...7))
        let domain = String.randomString(Int.random(in: 1...7))
        return "\(name)@\(domain).com"
    }

    static func randomPhone(_ len: Int) -> String {
        let letters: NSString = "0123456789"
        let randomString: NSMutableString = NSMutableString(capacity: len)
        let length = UInt32(letters.length)
        for _ in 0 ..< len {
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        return randomString as String
    }

    func encodeBase64() -> String {
        Data(utf8).encodeBase64()
    }

    func decodeBase64() -> Data {
        let decodedData = Data(base64Encoded: self, options: NSData.Base64DecodingOptions(rawValue: 0))
        return decodedData!
    }

    func parseObject() -> [String: String] {
        if self.isEmpty {
            return [:]
        }
        do {
            let data: Data! = self.data(using: String.Encoding.utf8)
            let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: String] ?? [:]
            return decoded
        } catch {
        }
        return [:]
    }

    func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        }
        return nil
    }

    func batchAddingPercentEncoding(withAllowedCharacters allowedCharacters: CharacterSet) -> String? {
        let batchSize = 100
        var batchPosition = startIndex
        var escaped = ""
        while batchPosition != endIndex {
            let range = batchPosition ..< (index(batchPosition, offsetBy: batchSize, limitedBy: endIndex) ?? endIndex)

            guard let percentEncodedSubstring = String(self[range]).addingPercentEncoding(withAllowedCharacters: allowedCharacters) else {
                return nil
            }
            escaped.append(percentEncodedSubstring)
            batchPosition = range.upperBound
        }
        return escaped
    }

    // This is function only for composer
    // If we have chance to refactor, move this to the composer
    func removeMailToIfNeeded() -> String {
        let trimedString = self.trim()
        if trimedString.starts(with: "mailto:") {
            return trimedString.preg_replace_none_regex("mailto:", replaceto: "")
        }
        // Contact name could contain white space
        // If the string doesn't start with mailto
        // should return the original string
        return self
    }
}

extension Array where Element == String {
    func asCommaSeparatedList(trailingSpace: Bool) -> String {
        filter { !$0.trim().isEmpty }.joined(separator: trailingSpace ? ", " : ",")
    }
}

extension String {
    /**
     String extension parse a json string to a list of dict
     
     :returns: [ [String:String] ]
     */
    func parseJson() -> [[String: Any]]? {
        if self.isEmpty {
            return []
        }

        do {
            if let data = self.data(using: String.Encoding.utf8) {
                let decoded = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
                return decoded
            }
        } catch {
        }
        return nil
    }

    /**
     String extension formating the Json format contact for forwarding email.
     
     :returns: String
     */
    func formatJsonContact(_ mailto: Bool = false) -> String {
        var lists: [String] = []

        if let recipients: [[String: Any]] = self.parseJson() {
            for dict: [String: Any] in recipients {
                if mailto {
                    lists.append(dict.getName() + " &lt;<a href=\"mailto:\(dict.getAddress())\" class=\"\">\(dict.getAddress())</a>&gt;")
                } else {
                    lists.append(dict.getName() + "&lt;\(dict.getAddress())&gt;")
                }
            }
        }
        return lists.joined(separator: ",")
    }

    func toContact() -> ContactVO? {
        var out: ContactVO?
        let recipients: [String: String] = self.parseObject()

        let name = recipients["Name"] ?? ""
        let address = recipients["Address"] ?? ""

        if !address.isEmpty {
            out = ContactVO(id: "", name: name, email: address)
        }
        return out
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any { // email name
    func getAddress() -> String {    // this function only for the To CC BCC list parsing
        if let key = "Address" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }

    func getName() -> String {    // this function only for the To CC BCC list parsing
        if let key = "Name" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }
}
