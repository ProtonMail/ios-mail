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

import ProtonCore_DataModel
import XCTest

@testable import ProtonMail

final class BlockedSenderCacheUpdaterTests: XCTestCase {
    private var fetchStatusProvider: MockBlockedSenderFetchStatusProviderProtocol!
    private var internetStatusProvider: MockInternetConnectionStatusProviderProtocol!
    private var refetchAllBlockedSenders: MockRefetchAllBlockedSendersUseCase!
    private var sut: BlockedSenderCacheUpdater!

    private let userInfo: UserInfo = .dummy

    override func setUpWithError() throws {
        try super.setUpWithError()

        fetchStatusProvider = .init()
        internetStatusProvider = .init()
        refetchAllBlockedSenders = .init()

        sut = BlockedSenderCacheUpdater(
            dependencies: .init(
                fetchStatusProvider: fetchStatusProvider,
                internetConnectionStatusProvider: internetStatusProvider,
                refetchAllBlockedSenders: refetchAllBlockedSenders,
                userInfo: userInfo
            )
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        fetchStatusProvider = nil
        internetStatusProvider = nil
        refetchAllBlockedSenders = nil

        try super.tearDownWithError()
    }

    func testIsIdleAtFirst() {
        XCTAssertEqual(sut.state, .idle)
    }

    func testRequestingTheUpdate_whileOnline_triggersUpdate() {
        sut.requestUpdate()
        waitForSideEffectsToOccur()

        XCTAssertEqual(sut.state, .updateInProgress)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 1)
    }

    func testRequestingTheUpdate_whileNotIdle_doesNothing() {
        sut.requestUpdate()
        waitForSideEffectsToOccur()

        XCTAssertNotEqual(sut.state, .idle)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 1)

        sut.requestUpdate()
        waitForSideEffectsToOccur()

        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 1)
    }

    func testRequestingTheUpdate_whileOffline_triggersWaitingForOnlineState() {
        internetStatusProvider.currentStatusStub.fixture = .notConnected

        var didRegainConnectivity: (() -> Void)!

        internetStatusProvider.registerConnectionStatusStub.bodyIs { _, _, callback in
            // we're capturing callback to run it later, thus simulating regaining connectivity
            didRegainConnectivity = {
                callback(.connected)
            }
        }

        sut.requestUpdate()
        waitForSideEffectsToOccur()

        XCTAssertEqual(sut.state, .waitingToBecomeOnline)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 0)
        XCTAssertEqual(internetStatusProvider.registerConnectionStatusStub.callCounter, 1)

        didRegainConnectivity()
        waitForSideEffectsToOccur()

        XCTAssertEqual(sut.state, .updateInProgress)
        XCTAssertEqual(internetStatusProvider.unregisterObserverStub.callCounter, 1)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 1)
    }

    func testSuccessfulUpdate_triggersIdleState() {
        refetchAllBlockedSenders.executeStub.bodyIs { _, completion in
            completion(nil)
        }

        sut.requestUpdate()
        waitForSideEffectsToOccur()

        XCTAssertEqual(sut.state, .idle)
    }

    func testFailedUpdate_triggersWaitingToRetryStateInsteadOfRetryingImmediately() {
        refetchAllBlockedSenders.executeStub.bodyIs { _, completion in
            completion(NSError.badResponse())
        }

        sut.requestUpdate()
        waitForSideEffectsToOccur()

        XCTAssertEqual(sut.state, .waitingToRetryAfterError)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 1)
    }

    // MARK: delegate

    func testChangingStateNotifiesDelegate() {
        let delegate = MockBlockedSenderCacheUpdaterDelegate()

        sut.delegate = delegate

        refetchAllBlockedSenders.executeStub.bodyIs { _, completion in
            completion(nil)
        }

        sut.requestUpdate()
        waitForSideEffectsToOccur()

        XCTAssertEqual(
            delegate.blockedSenderCacheUpdaterStub.capturedArguments.map(\.second),
            [.updateRequested, .updateInProgress, .idle]
        )
    }

    // MARK: fetch status flag

    func testSuccessfulUpdate_storesCompletedFlag() {
        refetchAllBlockedSenders.executeStub.bodyIs { _, completion in
            completion(nil)
        }

        sut.requestUpdate()
        waitForSideEffectsToOccur()

        XCTAssertEqual(fetchStatusProvider.markBlockedSendersAsFetchedStub.callCounter, 1)
        XCTAssertEqual(
            fetchStatusProvider.markBlockedSendersAsFetchedStub.lastArguments?.value.rawValue,
            userInfo.userId
        )
    }

    func testFailedUpdate_doesntStoreCompletedFlag() {
        refetchAllBlockedSenders.executeStub.bodyIs { _, completion in
            completion(NSError.badResponse())
        }

        sut.requestUpdate()
        waitForSideEffectsToOccur()

        XCTAssertEqual(fetchStatusProvider.markBlockedSendersAsFetchedStub.callCounter, 0)
    }

    // Quick explanation: we decided to fetch only once and then rely on the `EventsService` to handle changes.
    func testRefusesToUpdateIfAlreadyCompletedOnce() {
        fetchStatusProvider.checkIfBlockedSendersAreFetchedStub.bodyIs { _, _ in
            true
        }

        sut.requestUpdate()
        waitForSideEffectsToOccur()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 0)
    }

    // MARK: helpers

    /// This method is needed because side effects happen on a background queue
    private func waitForSideEffectsToOccur() {
        Thread.sleep(forTimeInterval: 0.05)
    }
}
