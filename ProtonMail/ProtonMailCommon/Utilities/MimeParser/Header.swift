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

    init(_ string: String) {
        let components = string.components(separatedBy: ":")
        self.name = components.first ?? ""
        self.body = Array(components[1...]).joined(separator: ":").trimmingCharacters(in: .whitespaces)
        self.kind = Kind(rawValue: self.name.lowercased())
        self.raw = string
    }

    var keyValues: [String: String] {
        let trimThese = CharacterSet(charactersIn: "\"").union(.whitespacesAndNewlines)
        let commaComponents = self.body.components(separatedBy: ",")
        let seimcolonComponents = self.body.components(separatedBy: ";")
        let components = seimcolonComponents.count > 1 ? seimcolonComponents : commaComponents
        var results: [String: String] = [:]

        for component in components {
            let pieces = component.components(separatedBy: "=")
            guard pieces.count >= 2 else { continue }
            let key = pieces[0].trimmingCharacters(in: trimThese).components(separatedBy: .whitespaces).last!
            results[key] = Array(pieces[1...]).joined(separator: "=").trimmingCharacters(in: trimThese)
        }
        return results
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
        for header in self {
            if header.kind == kind {
                return header
            }
        }
        return nil
    }
}
