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

import ProtonCore_TestingToolkit
import XCTest
@testable import ProtonMail

final class UserContainerTests: XCTestCase {
    func testDoesNotCreateRetainCycleWithEmbeddingUserManager() {
        let globalContainer = GlobalContainer()

        var strongRefToUser: UserManager? = UserManager(api: APIServiceMock(), userID: "foo", globalContainer: globalContainer)
        var strongRefToContainer: UserContainer? = strongRefToUser?.container
        var strongRefToDependency: AnyObject? = strongRefToContainer?.settingsViewsFactory

        // undo a side-effect of UserManager.init
        globalContainer.queueManager.unregisterHandler(for: "foo")

        weak var weakRefToUser: UserManager? = strongRefToUser
        weak var weakRefToContainer: UserContainer? = strongRefToContainer
        weak var weakRefToDependency: AnyObject? = strongRefToDependency

        XCTAssertNotNil(weakRefToUser)
        XCTAssertNotNil(weakRefToContainer)
        XCTAssertNotNil(weakRefToDependency)

        strongRefToUser = nil
        strongRefToContainer = nil
        strongRefToDependency = nil

        XCTAssertNil(weakRefToUser)
        XCTAssertNil(weakRefToContainer)
        XCTAssertNil(weakRefToDependency)
    }
}
