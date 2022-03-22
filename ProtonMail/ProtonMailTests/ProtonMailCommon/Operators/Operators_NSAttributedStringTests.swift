//
//  Operators_NSAttributedStringTests.swift
//  ProtonMailTests
//
//  Copyright (c) 2021 Proton AG
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
//

@testable import ProtonMail
import XCTest

class Operators_NSAttributedStringTests: XCTestCase {

    func testAdditionOperator() {
        let first = NSAttributedString(string: "first", attributes: [.foregroundColor: UIColor.red])
        let second = NSAttributedString(string: "second", attributes: [.foregroundColor: UIColor.blue])
        let result = first + second
        XCTAssertEqual(result.string, "firstsecond")

        let firstAttributes = result.attributes(
            at: 0,
            longestEffectiveRange: nil,
            in: .init(location: 0, length: 5)
        )

        XCTAssertEqual(firstAttributes.count, 1)
        XCTAssertEqual(firstAttributes[.foregroundColor] as? UIColor, .red)

        let secondAttributes = result.attributes(
            at: 5,
            longestEffectiveRange: nil,
            in: .init(location: 0, length: 6)
        )

        XCTAssertEqual(secondAttributes.count, 1)
        XCTAssertEqual(secondAttributes[.foregroundColor] as? UIColor, .blue)
    }

}
