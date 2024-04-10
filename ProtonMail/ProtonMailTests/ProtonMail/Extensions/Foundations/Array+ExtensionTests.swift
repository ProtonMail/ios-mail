// Copyright (c) 2021 Proton AG
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

final class Array_ExtensionTests: XCTestCase {

    // MARK: chunked

    func testChunked() {
        let array = Array(0...20)
        let chunk1 = array.chunked(into: 3)
        XCTAssertEqual(chunk1.count, 7)
        for chunk in chunk1 {
            XCTAssertEqual(chunk.count, 3)
        }

        let chunk2 = array.chunked(into: 10)
        XCTAssertEqual(chunk2.count, 3)
        XCTAssertEqual(chunk2[safe: 0]?.count, 10)
        XCTAssertEqual(chunk2[safe: 1]?.count, 10)
        XCTAssertEqual(chunk2[safe: 2]?.count, 1)
    }

    // MARK: unique

    func testUnique_whenDuplicateElements_itRemovesDuplicates() {
        let inputArray = [1, 2, 3, 1, 4, 5, 2]
        let expectedArray = [1, 2, 3, 4, 5]

        XCTAssertEqual(inputArray.unique { $0 }, expectedArray)
    }

    func testUnique_whenNoDuplicateElements_itReturnsTheSameArray() {
        let inputArray = [1, 2, 3, 4, 5]
        let expectedArray = [1, 2, 3, 4, 5]

        XCTAssertEqual(inputArray.unique { $0 }, expectedArray)
    }

    func testUnique_whenDuplicateElementsInCustomAttribute_itRemovesDuplicates() {
        struct CustomObject: Hashable {
            let name: String
            let age: Int
        }

        let object1 = CustomObject(name: "Mike", age: 20)
        let object2 = CustomObject(name: "Anna", age: 24)
        let object3 = CustomObject(name: "Sarah", age: 24)
        let object4 = CustomObject(name: "Mike", age: 30)
        
        let inputArray = [object1, object2, object3, object4]

        let expectedArrayByName = [object1, object2, object3]
        XCTAssertEqual(inputArray.unique { $0.name }, expectedArrayByName)

        let expectedArrayByAge = [object1, object2, object4]
        XCTAssertEqual(inputArray.unique { $0.age }, expectedArrayByAge)
    }
}
