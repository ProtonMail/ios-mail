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
@testable import proton_app_uniffi
import XCTest

final class UnreadItemsCountLiveQueryTests: XCTestCase {

    func testAllocatingSUT_DoesNotLeakMemory() async throws {
        let mailbox = try await Mailbox.testInstance()
        let sut = UnreadItemsCountLiveQuery(mailbox: mailbox, dataUpdate: { _ in })

        await sut.setUpLiveQuery()

        assertDoesNotLeakMemory(instance: sut)
    }

}

private extension XCTestCase {

    func assertDoesNotLeakMemory(
        instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance of type: \(String(describing: instance)) does not deallocate – potential memory leak",
                file: file,
                line: line
            )
        }
    }

}

private extension Mailbox {

    static func testInstance() async throws -> Mailbox {
        let mailUserSession = AppContext.shared.activeUserSession!

        return try await Mailbox.inbox(ctx: mailUserSession)
    }

}
