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

@testable import ProtonMail
import proton_mail_uniffi
import XCTest

final class CustomFolderTests: XCTestCase {

    func testPreorderTreeTraversal_whenSingleFolder_itReturnsTheFolder() {
        let name = "Folder"
        let sut = CustomFolder(folder: LocalLabel(name: name), children: [])

        let result = sut.preorderTreeTraversal()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].folder.name, name)
    }

    func testPreorderTreeTraversal_whenNestedFolders_itReturnsTheFlattenedArray() {
        let sut = CustomFolder(
            folder: LocalLabel(name: "F1"),
            children: [
                CustomFolder(
                    folder: LocalLabel(name: "F11"),
                    children: [
                        CustomFolder(folder: LocalLabel(name: "F111"), children: []),
                        CustomFolder(folder: LocalLabel(name: "F112"), children: [])
                    ]
                ),
                CustomFolder(folder: LocalLabel(name: "F12"), children: []),
                CustomFolder(folder: LocalLabel(name: "F13"), children: [
                    CustomFolder(folder: LocalLabel(name: "F131"), children: []),
                ])
            ]
        )

        let result = sut.preorderTreeTraversal()

        XCTAssertEqual(result.count, 7)
        XCTAssertEqual(result.map(\.folder.name), ["F1", "F11", "F111", "F112", "F12", "F13", "F131"])
    }
}

private extension LocalLabel {

    init(name: String) {
        self.init(
            id: UInt64.random(in: 1...UInt64.max),
            rid: nil,
            parentId: nil,
            name: name,
            path: nil,
            color: .init(), 
            labelType: .folder,
            order: UInt32.random(in: 1...UInt32.max),
            notify: Bool.random(),
            expanded: Bool.random(),
            sticky: Bool.random()
        )
    }
}
