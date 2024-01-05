// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and ProtonCore.
//
// ProtonCore is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonCore is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonCore. If not, see https://www.gnu.org/licenses/.

@testable import ProtonCoreEventsLoop
import XCTest

class EnvironmentTests: XCTestCase {

    func testLoopOperationQueueFactory_ReturnsQueueOfTypeOperationQueue() {
        assertKindOf(Environment.loopOperationQueueFactory(), OperationQueue.self)
    }

    func testMainSchedulerOperationQueueFactory_ReturnsQueueOfTypeOperationQueue() {
        assertKindOf(Environment.mainSchedulerOperationQueueFactory(), OperationQueue.self)
    }

    func testCurrentDate_ReturnsDateAtCurrentTime() {
        XCTAssertEqual(Environment.currentDate().timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.0001)
    }

}
