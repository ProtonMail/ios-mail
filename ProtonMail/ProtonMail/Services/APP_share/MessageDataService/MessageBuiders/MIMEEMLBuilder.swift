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
import ProtonCoreCrypto
import ProtonCoreDataModel
import ProtonCoreHash
import SwiftSoup

struct MIMEEMLBuilder {
    let messageBody: String
    let preAttachments: [PreAttachment]
    /// [AttachmentID: base64 attachment body]
    let attachmentBodys: [String: Base64String]

    init(
        preAttachments: [PreAttachment],
        attachmentBodys: [String: Base64String],
        clearBody: String?
    ) {
        self.preAttachments = preAttachments
        self.attachmentBodys = attachmentBodys
        self.messageBody = clearBody ?? ""
    }

    func build() -> String {
        let (cleanBody, inlineDict) = extractInlines(from: messageBody)
        let mixedEML = buildMultipartMixed(cleanBody: cleanBody, inlineDict: inlineDict)
        return mixedEML
    }

}

// MARK: - multipart/mixed
extension MIMEEMLBuilder {
    private func buildMultipartMixed(cleanBody: String, inlineDict: [String: String]) -> String {
        let boundary = generateMessageBoundaryString()
        let alternativeEML = buildMultipartAlternativeEML(cleanBody: cleanBody, inlineDict: inlineDict)

        var eml: [String] = []
        eml.append("Content-Type: multipart/mixed;boundary=\(boundary)")
        eml.append("")
        eml.append("--\(boundary)")
        eml.append(alternativeEML)
        eml.append("--\(boundary)--")
        return eml.joined(separator: "\r\n")
    }
}

// MARK: - multipart/alternative
extension MIMEEMLBuilder {
    private func buildMultipartAlternativeEML(cleanBody: String, inlineDict: [String: String]) -> String {
        let boundary = generateMessageBoundaryString()
        let textEML = buildQuotedPrintableEML(for: cleanBody)
        let relatedEML = buildMultipartRelatedEML(cleanBody: cleanBody, inlineDict: inlineDict)

        var eml: [String] = []
        eml.append("Content-Type: multipart/alternative;boundary=\(boundary)")
        eml.append("")
        if let textEML {
            eml.append("--\(boundary)")
            eml.append(textEML)
            eml.append("")
        }
        eml.append("--\(boundary)")
        eml.append(relatedEML)
        eml.append("--\(boundary)--")
        return eml.joined(separator: "\r\n")
    }

    private func buildQuotedPrintableEML(for cleanBody: String) -> String? {
        var eml: [String] = []
        guard let document = Parser.parseAndLogErrors(cleanBody) else { return nil }
        document.outputSettings().prettyPrint(pretty: false)
        guard let html = try? document.body()?.html() else { return nil }
        let plainText = html
            .trim()
            .preg_replace("<br>", replaceto: "\n")
            .preg_replace("<[^>]+>", replaceto: "").trim()
            .preg_replace("&nbsp;", replaceto: " ")
        let encodingText = QuotedPrintable.encode(string: plainText)
        eml.append("Content-Transfer-Encoding: quoted-printable")
        eml.append("Content-Type: text/plain;charset=utf-8")
        eml.append("")
        eml.append(encodingText)

        return eml.joined(separator: "\r\n")
    }
}

// MARK: - multipart/related EML
extension MIMEEMLBuilder {
    private func buildMultipartRelatedEML(cleanBody: String, inlineDict: [String: String]) -> String {
        let boundary = generateMessageBoundaryString()
        let base64EML = buildBase64EML(for: cleanBody)
        let inlineEMLs = buildInlineEML(for: inlineDict)
        let attachmentEMLs = buildEMLForAttachment()

        var eml: [String] = []
        eml.append("Content-Type: multipart/related;boundary=\(boundary)")
        eml.append("")
        eml.append("--\(boundary)")
        eml.append(base64EML)
        for inlineEML in inlineEMLs {
            eml.append("--\(boundary)")
            eml.append(inlineEML)
        }
        for attachmentEML in attachmentEMLs {
            eml.append("--\(boundary)")
            eml.append(attachmentEML)
        }
        eml.append("--\(boundary)--")
        return eml.joined(separator: "\r\n")
    }

    private func buildBase64EML(for cleanBody: String) -> String {
        var eml: [String] = []
        eml.append("Content-Type: text/html;charset=utf-8")
        eml.append("Content-Transfer-Encoding: base64")
        eml.append("")
        let cleanBodyData = Data(cleanBody.utf8)
        let cleanBodyEncoded = Base64String(encoding: cleanBodyData)
        eml.append(cleanBodyEncoded.insert(every: 64, with: "\r\n"))
        return eml.joined(separator: "\r\n")
    }

    private func buildInlineEML(for inlines: [String: String]) -> [String] {
        if inlines.keys.isEmpty { return [] }
        var inlineEMLs: [String] = []
        for (contentID, dataURI) in inlines {
            guard let (type, encoding, fileData) = Self.extractInformation(from: dataURI) else { continue }
            let filename = String.randomString(8)
            var eml: [String] = []
            eml.append("Content-Type: \(type); filename=\"\(filename)\"; name=\"\(filename)\"")
            eml.append("Content-Transfer-Encoding: \(encoding)")
            eml.append("Content-Disposition: inline; filename=\"\(filename)\"; name=\"\(filename)\"")
            eml.append("Content-ID: <\(contentID)>")
            eml.append("")
            eml.append(fileData.insert(every: 64, with: "\r\n"))

            inlineEMLs.append(eml.joined(separator: "\r\n"))
        }
        return inlineEMLs
    }

    private func buildEMLForAttachment() -> [String] {
        var attachmentEMLs: [String] = []
        for information in preAttachments {
            guard let fileData = attachmentBodys[information.attachmentId] else { continue }
            let attachment = information.att
            var eml: [String] = []
            // The format is =?charset?encoding?encoded-text?=
            // encoding = B means base64
            let name = "=?utf-8?B?\(attachment.name.encodeBase64())?="
            let disposition = attachment.isInline ? "inline" : "attachment"

            eml.append("Content-Type: \(attachment.rawMimeType); filename=\"\(name)\"; name=\"\(name)\"")
            eml.append("Content-Transfer-Encoding: base64")
            eml.append("Content-Disposition: \(disposition); filename=\"\(name)\"")
            if attachment.isInline {
                eml.append("Content-ID: <\(attachment.getContentID() ?? "unknownID")>")
            }
            eml.append("")
            eml.append(fileData.insert(every: 64, with: "\r\n"))

            attachmentEMLs.append(eml.joined(separator: "\r\n"))
        }
        return attachmentEMLs
    }
}

extension MIMEEMLBuilder {
    /// Extract inlines data from message body and return clean body
    /// - Parameter messageBody: message body
    /// - Returns: 
    /// - body: body without inlines data string
    /// - inlineDict: inline image dataURI
    private func extractInlines(from messageBody: String) -> (body: String, inlineDict: [String: String]) {
        guard
            let document = Parser.parseAndLogErrors(messageBody),
            let inlines = try? document.select(#"img[src^="data"]"#).array(),
            !inlines.isEmpty
        else { return (messageBody, [:]) }

        /// [ContentID: base64Data]
        var inlineDict: [String: String] = [:]
        for element in inlines {
            let contentID = "\(String.randomString(8))@pm.me"
            guard let src = try? element.attr("src") else { continue }
            inlineDict[contentID] = src
            _ = try? element.attr("src", "cid:\(contentID)")
        }
        document.outputSettings().prettyPrint(pretty: false)
        guard let updatedBody = try? document.html() else { return (messageBody, [:]) }
        return (updatedBody, inlineDict)
    }

    /// - Parameter dataURI: "data:image/png;base64,iV........"
    static func extractInformation(from dataURI: String) -> (type: String, encoding: String, base64: Base64String)? {
        let pattern = #"^(.*?):(.*?);(.*?),([A-Za-z0-9+/]+={0,2})"#
        guard
            let regex = try? RegularExpressionCache.regex(for: pattern, options: [.allowCommentsAndWhitespace]),
            let match = regex.firstMatch(in: dataURI, range: .init(location: 0, length: dataURI.count)),
            match.numberOfRanges == 5
        else { return nil }

        // image/png
        let mimeType = dataURI.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
        // base64
        let encoding = dataURI.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
        // The maximum length is 64, should insert `\r\n` every 64 characters
        // Otherwise the EML is broken
        let base64RawString = dataURI.substring(with: match.range(at: 4))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let base64 = Base64String(alreadyEncoded: base64RawString)
        return (mimeType, encoding, base64)
    }

    private func generateMessageBoundaryString() -> String {
        var boundaryMsg = "uF5XZWCLa1E8CXCUr2Kg8CSEyuEhhw9WU222" // default
        if let random = try? Crypto.random(byte: 20), !random.isEmpty {
            boundaryMsg = HMAC.hexStringFromData(random)
        }
        return boundaryMsg
    }
}
