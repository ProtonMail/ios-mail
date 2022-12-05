//
//  SendMessageAPITest.swift
//  ProtonMailTests
//
//  Created by AnsonChen on 2022/9/16.
//

import ProtonCore_Crypto
import ProtonCore_Networking
import XCTest
@testable import ProtonMail

final class SendMessageAPITest: XCTestCase {

    private func prepareDataAndTest(plainText: Bool,
                                    scheme: PGPScheme,
                                    algorithm: Algorithm,
                                    mime: SendMIMEType,
                                    expectedBody: String,
                                    shouldHaveAttachments: Bool) throws {
        let messageID = UUID().uuidString
        let expirationTime = Int32.random(in: 1...5)
        let delaySecond = Int.random(in: 1...9)
        let deliveryTime = Date()
        let messagePackage = AddressPackage(email: "test@pm.me",
                                            bodyKeyPacket: "test body packet",
                                            scheme: scheme,
                                            plainText: plainText)
        let clearBody = ClearBodyPackage(key: "clear body key", algo: algorithm)
        let attachmentID = UUID().uuidString
        let attachment = ClearAttachmentPackage(attachmentID: attachmentID,
                                                encodedSession: "encoded session",
                                                algo: algorithm)
        let clearMIMEBody = ClearBodyPackage(key: "mime body key", algo: algorithm)
        let sut = SendMessage(messageID: messageID,
                          expirationTime: expirationTime,
                          delaySeconds: delaySecond,
                          messagePackage: [messagePackage],
                          body: "This is body",
                          clearBody: clearBody,
                          clearAtts: [attachment],
                          mimeDataPacket: "mime package",
                          clearMimeBody: clearMIMEBody,
                          plainTextDataPacket: "plain text",
                          clearPlainTextBody: nil,
                          authCredential: nil,
                          deliveryTime: deliveryTime)
        XCTAssertEqual(sut.method, HTTPMethod.post)
        XCTAssertEqual(sut.path, "\(MessageAPI.path)/\(messageID)")

        let jsonDict = try XCTUnwrap(sut.parameters)
        XCTAssertEqual(jsonDict["DeliveryTime"] as? Int, Int(deliveryTime.timeIntervalSince1970))
        XCTAssertEqual(jsonDict["DelaySeconds"] as? Int, delaySecond)
        XCTAssertEqual(jsonDict["ExpiresIn"] as? Int32, expirationTime)
        let packages = try XCTUnwrap(jsonDict["Packages"] as? [[String: Any]])
        XCTAssertEqual(packages.count, 1)

        let addressInfo = try XCTUnwrap(packages.first)
        XCTAssertEqual(addressInfo["Body"] as? String, expectedBody)
        XCTAssertEqual(addressInfo["MIMEType"] as? String, mime.rawValue)
        XCTAssertEqual(addressInfo["Type"] as? Int, scheme.rawValue)

        if shouldHaveAttachments {
            let attachmentInfos = try XCTUnwrap(addressInfo["AttachmentKeys"] as? [String: Any])
            let theAttachment = try XCTUnwrap(attachmentInfos[attachmentID] as? [String: String])
            XCTAssertEqual(theAttachment["Key"], "encoded session")
            XCTAssertEqual(theAttachment["Algorithm"], algorithm.rawValue)
        } else {
            XCTAssertNil(addressInfo["AttachmentKeys"])
        }
    }

    func testPlainTextCase() throws {
        let schemes: [PGPScheme] = [.proton, .encryptedToOutside, .cleartextInline, .pgpInline]
        for scheme in schemes {
            let shouldHaveAttachments = [PGPScheme.cleartextInline, PGPScheme.cleartextMIME].contains(scheme)
            try prepareDataAndTest(plainText: true,
                                   scheme: scheme,
                                   algorithm: .AES128,
                                   mime: .plainText,
                                   expectedBody: "plain text",
                                   shouldHaveAttachments: shouldHaveAttachments)
        }
    }

    func testHTMLCase() throws {
        let schemes: [PGPScheme] = [.proton, .encryptedToOutside, .cleartextInline, .pgpInline]
        for scheme in schemes {
            let shouldHaveAttachments = [PGPScheme.cleartextInline, PGPScheme.cleartextMIME].contains(scheme)
            try prepareDataAndTest(plainText: false,
                                   scheme: scheme,
                                   algorithm: .CAST5,
                                   mime: .html,
                                   expectedBody: "This is body",
                                   shouldHaveAttachments: shouldHaveAttachments)
        }
    }

    func testMIMECase() throws {
        let schemes: [PGPScheme] = [.cleartextMIME, .pgpMIME]
        for scheme in schemes {
            try prepareDataAndTest(plainText: false,
                                   scheme: scheme,
                                   algorithm: .AES192,
                                   mime: .mime,
                                   expectedBody: "mime package",
                                   shouldHaveAttachments: false)
        }
    }
}
