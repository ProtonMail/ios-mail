// Copyright (c) 2022 Proton Technologies AG
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

final class ContentBlockRuleBuilderTest: XCTestCase {
    func testRule() throws {
        var rule = ContentBlockRuleBuilder.Rule()
            .addTrigger(key: .urlFilter, value: "url filter")
            .addAction(key: .type, value: .block)
        var result = rule.export()
        let filter = try XCTUnwrap(result["trigger"]?["url-filter"])
        XCTAssertEqual(filter, "url filter")

        var action = try XCTUnwrap(result["action"]?["type"])
        XCTAssertEqual(action, "block")

        rule = rule.addAction(key: .type, value: .ignorePreviousRules)
        result = rule.export()
        action = try XCTUnwrap(result["action"]?["type"])
        XCTAssertEqual(action, "ignore-previous-rules")
    }

    func testContentBlock() throws {
        let blocker = ContentBlockRuleBuilder()
            .add(
                rule: .init()
                    .addTrigger(key: .urlFilter, value: ".*")
                    .addAction(key: .type, value: .block)
            )
            .add(
                rule: .init()
                    .addTrigger(key: .urlFilter, value: "proton.ch")
                    .addAction(key: .type, value: .ignorePreviousRules)
            )
        let result = try XCTUnwrap(blocker.export())
        let data = Data(result.utf8)
        let dict = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [[String: [String: String]]])
        XCTAssertEqual(dict.count, 2)
        let expect1 = [
            "trigger": ["url-filter": ".*"],
            "action": ["type": "block"]
        ]
        let expect2 = [
            "trigger": ["url-filter": "proton.ch"],
            "action": ["type": "ignore-previous-rules"]
        ]
        if dict.first?["action"]?["type"] == "block" {
            XCTAssertEqual(dict.first, expect1)
            XCTAssertEqual(dict[1], expect2)
        } else {
            XCTAssertEqual(dict.first, expect2)
            XCTAssertEqual(dict[1], expect1)
        }
    }

}
