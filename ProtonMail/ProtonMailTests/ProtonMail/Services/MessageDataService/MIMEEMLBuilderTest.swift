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

import ProtonCoreUIFoundations
import XCTest
import SwiftSoup
@testable import ProtonMail

final class MIMEEMLBuilderTest: XCTestCase {
    private var sut: MIMEEMLBuilder!

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testBuild_withoutAttachmentsAndInlines() throws {
        let body = generateMessageBody(numOfInlines: 0, uploadedCIDs: [])
        sut = MIMEEMLBuilder(preAttachments: [], attachmentBodys: [:], clearBody: body)
        let eml = sut.build()
        try validate(eml: eml, preAttachments: [], attachmentBodys: [:], numOfInlines: 0, uploadedCIDs: [])
    }

    func testBuild_withoutAttachments_hasInlines() throws {
        let numOfInlines = Int.random(in: 1...3)
        let body = generateMessageBody(numOfInlines: numOfInlines, uploadedCIDs: [])
        sut = MIMEEMLBuilder(preAttachments: [], attachmentBodys: [:], clearBody: body)
        let eml = sut.build()
        try validate(eml: eml, preAttachments: [], attachmentBodys: [:], numOfInlines: numOfInlines, uploadedCIDs: [])
    }

    func testBuild_withAttachments_withoutInlines() throws {
        let numOfInlines = 0
        let numOfAttachment = Int.random(in: 1...3)
        let body = generateMessageBody(numOfInlines: numOfInlines, uploadedCIDs: [])
        let (preAttachments, attachmentBodys) = generateAttachment(num: numOfAttachment, withAdditional: [])
        sut = MIMEEMLBuilder(preAttachments: preAttachments, attachmentBodys: attachmentBodys, clearBody: body)
        let eml = sut.build()
        try validate(
            eml: eml,
            preAttachments: preAttachments,
            attachmentBodys: attachmentBodys,
            numOfInlines: numOfInlines,
            uploadedCIDs: []
        )
    }

    func testBuild_withAttachmentsAndInlines() throws {
        let numOfInlines = Int.random(in: 1...3)
        let numOfAttachment = Int.random(in: 1...3)
        let body = generateMessageBody(numOfInlines: numOfInlines, uploadedCIDs: [])
        let (preAttachments, attachmentBodys) = generateAttachment(num: numOfAttachment, withAdditional: [])
        sut = MIMEEMLBuilder(preAttachments: preAttachments, attachmentBodys: attachmentBodys, clearBody: body)
        let eml = sut.build()
        try validate(
            eml: eml,
            preAttachments: preAttachments,
            attachmentBodys: attachmentBodys,
            numOfInlines: numOfInlines,
            uploadedCIDs: []
        )
    }

    // There are 2 possible inline type
    // 1. based64 format, <img src="data:image/png:base64,xxxx">
    // 2. the inline has uploaded, <img src="cid:abc">
    func testBuild_withAttachments_inlines_andUploadedInlines() throws {
        let numOfInlines = Int.random(in: 1...3)
        let numOfAttachment = Int.random(in: 1...3)
        let numOfUploadedInlines = Int.random(in: 1...3)
        let uploadedCIDs = generateCIDs(num: numOfUploadedInlines)
        let body = generateMessageBody(numOfInlines: numOfInlines, uploadedCIDs: uploadedCIDs)
        let (preAttachments, attachmentBodys) = generateAttachment(num: numOfAttachment, withAdditional: uploadedCIDs)
        sut = MIMEEMLBuilder(preAttachments: preAttachments, attachmentBodys: attachmentBodys, clearBody: body)
        let eml = sut.build()
        try validate(
            eml: eml,
            preAttachments: preAttachments,
            attachmentBodys: attachmentBodys,
            numOfInlines: numOfInlines,
            uploadedCIDs: uploadedCIDs
        )
    }

    func testBuild_withAttachments_andUploadedInlines_zeroBase64Inlines() throws {
        let numOfInlines = 0
        let numOfAttachment = Int.random(in: 1...3)
        let numOfUploadedInlines = Int.random(in: 1...3)
        let uploadedCIDs = generateCIDs(num: numOfUploadedInlines)
        let body = generateMessageBody(numOfInlines: numOfInlines, uploadedCIDs: uploadedCIDs)
        let (preAttachments, attachmentBodys) = generateAttachment(num: numOfAttachment, withAdditional: uploadedCIDs)
        sut = MIMEEMLBuilder(preAttachments: preAttachments, attachmentBodys: attachmentBodys, clearBody: body)
        let eml = sut.build()
        try validate(
            eml: eml,
            preAttachments: preAttachments,
            attachmentBodys: attachmentBodys,
            numOfInlines: numOfInlines,
            uploadedCIDs: uploadedCIDs
        )
    }
}

// MARK: - Validate EML
extension MIMEEMLBuilderTest {
    private func validate(
        eml: String,
        preAttachments: [PreAttachment],
        attachmentBodys: [String: Base64String],
        numOfInlines: Int,
        uploadedCIDs: [String]
    ) throws {
        let mixedBoundary = getBoundary(from: eml, type: "mixed")
        let mixedContents = getContent(in: eml, boundary: mixedBoundary)
        guard mixedContents.count == 1, let alternative = mixedContents.first else {
            throw MIMEBuilderTestError.failure("Mixed should only have alternative")
        }

        let alternativeBoundary = getBoundary(from: alternative, type: "alternative")
        let alternativeContent = getContent(in: alternative, boundary: alternativeBoundary)
        guard let quotedPart = alternativeContent[safe: 0], let related = alternativeContent[safe: 1] else {
            throw MIMEBuilderTestError.failure("QuotedPrintable part or multipart/related doesn't exist")
        }
        validate(quotedPart: quotedPart, hasInline: numOfInlines > 0 || !uploadedCIDs.isEmpty)
        try validate(
            relatedPart: related,
            preAttachments: preAttachments,
            attachmentBodys: attachmentBodys,
            numOfInlines: numOfInlines, 
            uploadedCIDs: uploadedCIDs
        )
    }

    private func validate(quotedPart: String, hasInline: Bool) {
        if hasInline {
            let expected = "Content-Transfer-Encoding: quoted-printable\r\nContent-Type: text/plain;charset=utf-8\r\n\r\nline 1\r\nline 2\r\n"
            XCTAssertEqual(quotedPart, expected)
        } else {
            let expected = "Content-Transfer-Encoding: quoted-printable\r\nContent-Type: text/plain;charset=utf-8\r\n\r\nline 1\r\nline 2 =\r\n{{inline}}\r\n"
            XCTAssertEqual(quotedPart, expected)
        }
    }

    private func validate(
        relatedPart: String,
        preAttachments: [PreAttachment],
        attachmentBodys: [String: Base64String],
        numOfInlines: Int,
        uploadedCIDs: [String]
    ) throws {
        let relatedBoundary = getBoundary(from: relatedPart, type: "related")
        let contents = getContent(in: relatedPart, boundary: relatedBoundary)
        guard contents.count == 1 + preAttachments.count + numOfInlines else {
            throw MIMEBuilderTestError.failure("Sub contents in multipart/related part doesn't expect")
        }
        guard let body = contents.first else {
            throw MIMEBuilderTestError.failure("Should have base64 html body")
        }
        let cids = try validateBase64HTMLBodyAndReturnInlineCIDs(
            body: body,
            numOfInlines: numOfInlines,
            numOfUploadedCIDs: uploadedCIDs.count
        )
        let inlineContents = contents.filter { $0.contains(check: "Content-Disposition: inline") }
        let attachmentContents = contents.filter { $0.contains(check: "Content-Disposition: attachment") }

        try validateInlines(components: inlineContents, cids: cids)
        try validateAttachment(
            components: attachmentContents,
            preAttachment: preAttachments,
            attachmentBodys: attachmentBodys, 
            numOfUploadedCIDs: uploadedCIDs.count
        )
    }

    private func validateBase64HTMLBodyAndReturnInlineCIDs(
        body: String,
        numOfInlines: Int,
        numOfUploadedCIDs: Int
    ) throws -> [String] {
        let components = body.components(separatedBy: "\r\n")
        guard components.count >= 4 else {
            throw MIMEBuilderTestError.failure("Number doesn't correct")
        }
        XCTAssertEqual(components[0], "Content-Type: text/html;charset=utf-8")
        XCTAssertEqual(components[1], "Content-Transfer-Encoding: base64")
        let base64 = components[3...].joined()

        guard
            let html = String(data: base64.decodeBase64(), encoding: .utf8),
            let document = try? SwiftSoup.parse(html)
        else {
            throw MIMEBuilderTestError.failure("Parse html failed")
        }

        let images = (try? document.select("img").array()) ?? []

        let cids = images.compactMap({ try? $0.attr("src") })
        guard cids.count == numOfInlines + numOfUploadedCIDs else {
            throw MIMEBuilderTestError.failure("Number of inlines doesn't correct")
        }

        return cids
    }

    private func validateInlines(components: [String], cids: [String]) throws {
        guard components.count == cids.count else {
            throw MIMEBuilderTestError.failure("Number doesn't correct")
        }

        for component in components {
            let separated = component.components(separatedBy: "\r\n")
            guard separated.count > 5 else {
                throw MIMEBuilderTestError.failure("Number doesn't correct")
            }
            XCTAssertTrue(separated[0].hasPrefix("Content-Type: image/jpeg; filename="))
            XCTAssertEqual(separated[1], "Content-Transfer-Encoding: base64")
            XCTAssertTrue(separated[2].hasPrefix("Content-Disposition: inline; filename="))

            let contentID = String(separated[3][13..<27])
            guard cids.contains("cid:\(contentID)") else {
                throw MIMEBuilderTestError.failure("Unrecognized contentID")
            }
            let base64DataArray = Array(separated[5...])
            let expected = getBase64StringForInlineImage()
                .insert(every: 64, with: "\r\n")
                .components(separatedBy: "\r\n")
            XCTAssertEqual(base64DataArray, expected)
        }
    }

    private func validateAttachment(
        components: [String],
        preAttachment: [PreAttachment],
        attachmentBodys: [String: Base64String],
        numOfUploadedCIDs: Int
    ) throws {
        guard components.count == preAttachment.count - numOfUploadedCIDs else {
            throw MIMEBuilderTestError.failure("Number doesn't correct")
        }

        for component in components {
            let separated = component.components(separatedBy: "\r\n")
            guard 
                separated.count > 5,
                let base64Filename = getBase64Filename(from: separated[0])
            else {
                throw MIMEBuilderTestError.failure("Number doesn't correct")
            }
            let decodedFilename = String(data: base64Filename.decodeBase64(), encoding: .utf8)
            guard
                let attachment = preAttachment.first(where: { $0.att.name == decodedFilename }),
                let base64Body = attachmentBodys[attachment.attachmentId]
            else {
                throw MIMEBuilderTestError.failure("Can't find the specific attachment")
            }

            let header = "Content-Type: image/png; filename=\"=?utf-8?B?\(base64Filename)?=\"; name=\"=?utf-8?B?\(base64Filename)?=\""
            XCTAssertEqual(separated[0], header)
            XCTAssertEqual(separated[1], "Content-Transfer-Encoding: base64")
            let disposition = "Content-Disposition: attachment; filename=\"=?utf-8?B?\(base64Filename)?=\""
            XCTAssertEqual(separated[2], disposition)
            let base64DataArray = Array(separated[4...])
            let expected = base64Body
                .insert(every: 64, with: "\r\n")
                .components(separatedBy: "\r\n")
            XCTAssertEqual(base64DataArray, expected)
        }
    }
}

extension MIMEEMLBuilderTest {
    private func getBase64StringForAttachment() -> Base64String {
        let icon: UIImage = IconProvider.replyAll
        let data = icon.jpegData(compressionQuality: 0.8)!
        return Base64String(encoding: data)
    }

    private func generateAttachment(num: Int, withAdditional inlineCIDs: [String]) -> ([PreAttachment], [String: Base64String]) {
        var preAttachments: [PreAttachment] = []
        var attachmentBodys: [String: Base64String] = [:]

        for i in 0..<num {
            let attachmentID = String.randomString(8)
            let name = String.randomString(3)
            let entity = AttachmentEntity(
                id: AttachmentID(attachmentID),
                rawMimeType: "image/png",
                attachmentType: .image,
                name: name,
                userID: UserID("a"),
                messageID: MessageID("m"),
                isSoftDeleted: false,
                fileSize: 1,
                keyChanged: false,
                objectID: .init(rawValue: .init()),
                order: i,
                contentId: "a"
            )
            let attachment = PreAttachment(id: attachmentID, session: Data(), algo: .AES256, att: entity)
            preAttachments.append(attachment)
            attachmentBodys[attachmentID] = getBase64StringForAttachment()
        }

        for cid in inlineCIDs {
            let attachmentID = String.randomString(8)
            let name = String.randomString(3)
            let info = [
                "content-id": "<\(cid)>",
                "content-disposition": "inline",
            ]
            guard 
                let jsonData = try? JSONSerialization.data(withJSONObject: info, options: .prettyPrinted),
                let jsonString = String(data: jsonData, encoding: .utf8)
            else {
                XCTFail("Convert to data failed")
                continue
            }
            let entity = AttachmentEntity(
                headerInfo: jsonString,
                id: AttachmentID(attachmentID),
                rawMimeType: "image/jpeg",
                attachmentType: .image,
                name: name,
                userID: UserID("a"),
                messageID: MessageID("m"),
                isSoftDeleted: false,
                fileSize: 1,
                keyChanged: false,
                objectID: .init(rawValue: .init()),
                order: 0,
                contentId: nil
            )
            let attachment = PreAttachment(id: attachmentID, session: Data(), algo: .AES256, att: entity)
            preAttachments.append(attachment)
            attachmentBodys[attachmentID] = getBase64StringForInlineImage()
        }
        return (preAttachments, attachmentBodys)
    }

    private func getBase64StringForInlineImage() -> Base64String {
        let icon: UIImage = IconProvider.reply
        let data = icon.jpegData(compressionQuality: 0.8)!
        return Base64String(encoding: data)
    }

    private func generateMessageBody(numOfInlines: Int, uploadedCIDs: [String]) -> String {
        let body = "<html><head></head><body><div>line 1</div><br><div>line 2 </div><br><div>{{inline}}</div></body></html>"
        if numOfInlines == 0 && uploadedCIDs.isEmpty { return body }
        var inlines: [String] = []
        for _ in 0..<numOfInlines {
            let element = "<img src=\"data:image/jpeg;base64,\(getBase64StringForInlineImage().encoded)\">"
            inlines.append(element)
        }
        for cid in uploadedCIDs {
            let element = "<img src=\"cid:\(cid)\">"
            inlines.append(element)
        }
        return body.replacingOccurrences(of: "{{inline}}", with: "\(inlines.joined())")
    }

    private func generateCIDs(num: Int) -> [String] {
        (0..<num).map({ _ in "\(String.randomString(8))@pm.me" })
    }

    private func getContent(in source: String, boundary: String) -> [String] {
        var capturedSubstrings: [String] = []
        do {
            let pattern = try NSRegularExpression(
                pattern: "--\(boundary)\\r\\n(.*?)(?=\\r\\n--\(boundary)|$)",
                options: .dotMatchesLineSeparators
            )
            let matches = pattern.matches(
                in: source,
                options: [],
                range: NSRange(location: 0, length: source.utf16.count)
            )

            for match in matches {
                if let range = Range(match.range(at: 1), in: source) {
                    let capturedSubstring = String(source[range])
                    capturedSubstrings.append(capturedSubstring)
                }
            }

            return capturedSubstrings
        } catch {
            return []
        }
    }

    private func getBoundary(from source: String, type: String) -> String {
        let boundaryRegex = "multipart/\(type);boundary=([a-z0-9]*)"
        guard let boundary = source.preg_match(resultInGroup: 1, boundaryRegex) else {
            XCTFail("Get boundary string failed")
            return ""
        }
        return boundary
    }

    private func getBase64Filename(from header: String) -> String? {
        // "Content-Type: image/png; filename=\"=?utf-8?B?d2pm?=\"; name=\"=?utf-8?B?d2pm?=\""
        let pattern = #"filename=\"=\?utf-8\?B\?(.*?)\?=\""#
        guard let name = header.preg_match(resultInGroup: 1, pattern) else {
            XCTFail("Get filename failed")
            return nil
        }
        return name
    }

    enum MIMEBuilderTestError: Error {
        case failure(String)
    }
}
