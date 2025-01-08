// Copyright (c) 2025 Proton Technologies AG
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
import InboxTesting
import proton_app_uniffi
import XCTest

final class MoveToActionPerformerTests: BaseTestCase {
    private var sut: MoveToActionPerformer!
    private var stubbedResult: VoidActionResult!

    override func setUp() {
        super.setUp()

        sut = .init(
            mailbox: .init(noPointer: .init()),
            moveToActions: .init(
                moveMessagesTo: { [unowned self] _, _, _ in stubbedResult },
                moveConversationsTo: { [unowned self] _, _, _ in stubbedResult }
            )
        )
    }

    override func tearDown() {
        sut = nil
        stubbedResult = nil

        super.tearDown()
    }

    func testOverridesErrorMessageIfFolderDoesNotExist() async {
        stubbedResult = .error(
            .other(.serverError(.unprocessableEntity(#"{"Code": 2501, "Error": "Label does not exist"}"#)))
        )

        await XCTAssertAsyncThrowsError(try await moveToAction()) { error in
            XCTAssertEqual(error.localizedDescription, "Folder does not exist")
        }
    }

    func testPropagatesBackendError() async {
        stubbedResult = .error(
            .other(.serverError(.unprocessableEntity(#"{"Code": 2503, "Error": "Operation timed out"}"#)))
        )

        await XCTAssertAsyncThrowsError(try await moveToAction()) { error in
            XCTAssertEqual(error.localizedDescription, "Operation timed out")
        }
    }

    private func moveToAction() async throws {
        try await sut.moveTo(destinationID: .init(value: 0), itemsIDs: [], itemType: .message)
    }
}
