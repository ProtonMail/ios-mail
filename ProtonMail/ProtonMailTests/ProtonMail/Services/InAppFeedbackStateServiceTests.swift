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

class InAppFeedbackStateServiceTests: XCTestCase {

    var sut: InAppFeedbackStateService!
    override func setUp() {
        super.setUp()
        sut = InAppFeedbackStateService()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testRegisterDelegate() {
        let delegateMock = InAppFeedbackStateServiceDelegateMock()
        sut.register(delegate: delegateMock)
        XCTAssertEqual(sut.delegates.count, 1)
    }

    func testNotifyDelegates() {
        let delegateMock = InAppFeedbackStateServiceDelegateMock()
        sut.register(delegate: delegateMock)
        sut.notifyDelegatesAboutFlagChange()
        XCTAssertTrue(delegateMock.isInAppFeedbackFeatureFlagMethodCalled)
        XCTAssertFalse(delegateMock.enableStatus)
    }

    func testHandleNewFeatureFlags_remoteIsTrue_localIsFalse_resultIsFalse() {
        sut = InAppFeedbackStateService(localFeatureFlag: false)
        sut.handleNewFeatureFlags([FeatureFlagKey.inAppFeedback.rawValue: 1])
        XCTAssertFalse(sut.isEnable)
    }

    func testHandleNewFeatureFlags_remoteIsTrue_localIsTrue_resultIsTrue() {
        sut = InAppFeedbackStateService(localFeatureFlag: true)
        sut.handleNewFeatureFlags([FeatureFlagKey.inAppFeedback.rawValue: 1])
        XCTAssertTrue(sut.isEnable)
    }

    func testHandleNewFeatureFlags_remoteIsFalse_localIsTrue_resultIsFalse() {
        sut = InAppFeedbackStateService(localFeatureFlag: true)
        sut.handleNewFeatureFlags([FeatureFlagKey.inAppFeedback.rawValue: 0])
        XCTAssertFalse(sut.isEnable)
    }

    func testHandleNewFeatureFlags_remoteUnsupportedValue_localIsTrue_resultIsFalse() {
        sut = InAppFeedbackStateService(localFeatureFlag: true)
        sut.handleNewFeatureFlags([FeatureFlagKey.inAppFeedback.rawValue: 3])
        XCTAssertFalse(sut.isEnable)
    }

    func testHandleNewFeatureFlags_remoteIsEmpty_noUpdate() {
        sut = InAppFeedbackStateService(localFeatureFlag: true)
        sut.handleNewFeatureFlags([FeatureFlagKey.inAppFeedback.rawValue: 1])
        XCTAssertTrue(sut.isEnable)
        sut.handleNewFeatureFlags([:])
        XCTAssertTrue(sut.isEnable)
    }
}

class InAppFeedbackStateServiceDelegateMock: InAppFeedbackStateServiceDelegate {
    var isInAppFeedbackFeatureFlagMethodCalled = false
    var enableStatus = false

    func inAppFeedbackFeatureFlagHasChanged(enable: Bool) {
        isInAppFeedbackFeatureFlagMethodCalled = true
        enableStatus = enable
    }
}
