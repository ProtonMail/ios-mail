//
//  MIMEMessage.Part.Header.swift
//  Marcel
//
//  Created by Ben Gottlieb on 9/1/17.
//  Copyright © 2017 Stand Alone, inc. All rights reserved.
//

import Foundation

struct Header: CustomStringConvertible, CustomDebugStringConvertible {
    enum Kind: String {
        case returnPath = "return-path"
        case received = "received"
        case authenticationResults = "authentication-results"
        case receivedSPF = "received-spf"
        case subject, from, to, date, sender
        case replyTo = "reply-to"
        case messageID = "message-id"
        case mailer = "x-mailer"
        case listUnsubscribe = "list-unsubscribe"
        case contentType = "content-type"
        case contentTransferEncoding = "content-transfer-encoding"
        case dkimSignature = "DKIM-Signature"
        case contentID = "content-id"
        case contentDisposition = "content-disposition"
    }

    let raw: String
    let name: String
    let kind: Kind?
    let body: String
    let keyValues: [String: String]

    init(_ string: String) {
        let components = string.components(separatedBy: ":")
        self.name = components.first ?? ""
        self.body = Array(components[1...]).joined(separator: ":").trimmingCharacters(in: .whitespaces)
        self.kind = Kind(rawValue: self.name.lowercased())
        self.raw = string

        let trimThese = CharacterSet(charactersIn: "\"").union(.whitespacesAndNewlines)
        let commaComponents = self.body.components(separatedBy: ",")
        let seimcolonComponents = self.body.components(separatedBy: ";")
        let kvComponents = seimcolonComponents.count > 1 ? seimcolonComponents : commaComponents

        keyValues = kvComponents.reduce(into: [:], { results, component in
            let pieces = component.components(separatedBy: "=")
            guard pieces.count >= 2 else { return }
            guard let key = pieces[0]
                .trimmingCharacters(in: trimThese)
                .components(separatedBy: .whitespaces)
                .last else { return }
            results[key] = Array(pieces[1...])
                .joined(separator: "=")
                .trimmingCharacters(in: trimThese)
                .removingBinaryEncoding
        })
    }

    var description: String {
        if let kind = self.kind {
            return "\(kind.rawValue): \(self.body)"
        }
        return "\"\(self.name)\": \(self.body)"
    }

    var debugDescription: String { return self.description }
}

extension Array where Element == Header {
    init(string: String) {
        self = string
            .components(separatedBy: "\r\n")
            .filter { !$0.isEmpty }
            .map(Header.init)
    }

    subscript(_ kind: Header.Kind) -> Header? {
        self.first(where: { $0.kind == kind })
    }
}

private extension String {
    static let binaryEncodingRegex: NSRegularExpression = {
        let pattern = #"""
=\?
(?<charset>[^?]*)
\?
(?<encoding>[BQ])
\?
(?<encodedText>[^?]*)
\?=
"""#
        do {
            return try NSRegularExpression(
                pattern: pattern,
                options: [.allowCommentsAndWhitespace, .caseInsensitive]
            )
        } catch {
            fatalError("\(error)")
        }
    }()

    var removingBinaryEncoding: Self {
        var output = self
        var startingIndex = output.startIndex

        while true {
            let nsRange =  NSRange(startingIndex..<output.endIndex, in: output)
            
            guard
                let match = Self.binaryEncodingRegex.firstMatch(in: output, range: nsRange),
                let rangeToReplace = Range(match.range, in: output)
            else {
                break
            }

            let charset = output.substring(with: match.range(withName: "charset"))
            let encoding = output.substring(with: match.range(withName: "encoding"))
            let encodedText = output.substring(with: match.range(withName: "encodedText"))

            let decodedText: String?

            switch encoding.uppercased() {
            case "B":
                let stringEncoding = String.Encoding(ianaCharSetName: charset) ?? .utf8
                if let data = Data(base64Encoded: encodedText) {
                    decodedText = String(data: data, encoding: stringEncoding)
                } else {
                    decodedText = nil
                }
            case "Q":
                decodedText = encodedText.replacingOccurrences(of: "=", with: "%").removingPercentEncoding
            default:
                decodedText = nil
            }

            if let decodedText {
                output.replaceSubrange(rangeToReplace, with: decodedText)
            } else if !ProcessInfo.isRunningUnitTests {
                PMAssertionFailure("Decoding error - charset:\(charset), encoding:\(encoding)")
            }

            // this is to avoid infinite loops
            startingIndex = output.index(after: rangeToReplace.lowerBound)
        }

        return output
    }
}

private extension String.Encoding {
    init?(ianaCharSetName: String) {
        let cfStringEncoding = CFStringConvertIANACharSetNameToEncoding(ianaCharSetName as CFString)

        guard cfStringEncoding != kCFStringEncodingInvalidId else {
            return nil
        }

        let nsStringEncoding = CFStringConvertEncodingToNSStringEncoding(cfStringEncoding)
        self.init(rawValue: nsStringEncoding)
    }
}
