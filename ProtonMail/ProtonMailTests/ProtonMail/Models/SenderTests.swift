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

import XCTest

@testable import ProtonMail

class SenderTests: XCTestCase {
    func test_fromMessage_withRandomData() throws {
        let isProton = Bool.random() ? Int.random(in: 0...1) : nil
        let isSimpleLogin = Bool.random() ? Int.random(in: 0...1) : nil
        let shouldDisplaySenderImage = Bool.random() ? Int.random(in: 0...1) : nil
        let bimiRandomString = Bool.random() ? String.randomString(10) : nil
        let jsonString = makeJSON(isProton: isProton,
                                  isSimpleLogin: isSimpleLogin,
                                  shouldDisplaySenderImage: shouldDisplaySenderImage,
                                  bimiSelector: bimiRandomString)
        let auth = try Sender.decodeDictionary(jsonString: jsonString)
        XCTAssertEqual(auth.isFromProton, isProton == 1)
        XCTAssertEqual(auth.isFromSimpleLogin, isSimpleLogin == 1)
        XCTAssertEqual(auth.shouldDisplaySenderImage, shouldDisplaySenderImage == 1)
        if let bimiRandomString {
            XCTAssertEqual(auth.bimiSelector, bimiRandomString)
        } else {
            XCTAssertNil(auth.bimiSelector)
        }
    }

    func test_fromConversation_withRandomData() throws {
        let isProton0 = Bool.random() ? Int.random(in: 0...1) : nil
        let isSimpleLogin0 = Bool.random() ? Int.random(in: 0...1) : nil
        let shouldDisplaySenderImage0 = Bool.random() ? Int.random(in: 0...1) : nil
        let bimiRandomString0 = Bool.random() ? String.randomString(10) : nil
        let isProton1 = Bool.random() ? Int.random(in: 0...1) : nil
        let isSimpleLogin1 = Bool.random() ? Int.random(in: 0...1) : nil
        let shouldDisplaySenderImage1 = Bool.random() ? Int.random(in: 0...1) : nil
        let bimiRandomString1 = Bool.random() ? String.randomString(10) : nil
        let jsonString0 = makeJSON(isProton: isProton0,
                                  isSimpleLogin: isSimpleLogin0,
                                  shouldDisplaySenderImage: shouldDisplaySenderImage0,
                                  bimiSelector: bimiRandomString0)
        let jsonString1 = makeJSON(isProton: isProton1,
                                  isSimpleLogin: isSimpleLogin1,
                                  shouldDisplaySenderImage: shouldDisplaySenderImage1,
                                  bimiSelector: bimiRandomString1)
        let json = "[\(jsonString0),\(jsonString1)]"
        let auth = try Sender.decodeListOfDictionaries(jsonString: json)
        XCTAssertEqual(auth.count, 2)
        XCTAssertEqual(auth[0].isFromProton, isProton0 == 1)
        XCTAssertEqual(auth[0].isFromSimpleLogin, isSimpleLogin0 == 1)
        XCTAssertEqual(auth[0].shouldDisplaySenderImage, shouldDisplaySenderImage0 == 1)
        if let bimiRandomString0 {
            XCTAssertEqual(auth[0].bimiSelector, bimiRandomString0)
        } else {
            XCTAssertNil(auth[0].bimiSelector)
        }
        XCTAssertEqual(auth[1].isFromProton, isProton1 == 1)
        XCTAssertEqual(auth[1].isFromSimpleLogin, isSimpleLogin1 == 1)
        XCTAssertEqual(auth[1].shouldDisplaySenderImage, shouldDisplaySenderImage1 == 1)
        if let bimiRandomString1 {
            XCTAssertEqual(auth[1].bimiSelector, bimiRandomString1)
        } else {
            XCTAssertNil(auth[1].bimiSelector)
        }
    }
}

extension SenderTests {
    private func makeJSON(isProton: Int?, isSimpleLogin: Int?, shouldDisplaySenderImage: Int?, bimiSelector: String?) -> String {
        var jsonDict = [String: Any]()
        jsonDict["Name"] = String.randomString(10)
        jsonDict["Address"] = String.randomString(10)
        jsonDict["DisplaySenderImage"] = shouldDisplaySenderImage
        jsonDict["IsProton"] = isProton
        jsonDict["IsSimpleLogin"] = isSimpleLogin
        if let bimiSelector {
            jsonDict["BimiSelector"] = bimiSelector
        }
        return jsonDict.toString()!
    }
}
