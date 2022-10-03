//
//  MimeTypesTests.swift
//  Proton Mail - Created on 12/28/18.
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

@testable import ProtonMail
import XCTest

class MimeTypesTests: XCTestCase {

    func testClearFilename() {
        XCTAssertEqual("ima/ge.png".clear, "ima_ge.png")
        XCTAssertEqual("i:1#$ma/ge.png".clear, "i_1#$ma_ge.png")
        XCTAssertEqual("233598025 (2004|10|29).html".clear, "233598025 (2004|10|29).html")
        XCTAssertEqual("im?a/g<e.png".clear, "im?a_g<e.png")
        XCTAssertEqual("i*\"ma/g>e.png".clear, "i*\"ma_g>e.png")
        XCTAssertEqual("i{m}a/ge.png".clear, "i{m}a_ge.png")
    }

}
