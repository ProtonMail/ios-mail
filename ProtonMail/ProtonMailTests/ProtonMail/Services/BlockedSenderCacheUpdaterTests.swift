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

import ProtonCoreDataModel
import ProtonCoreTestingToolkitUnitTestsDataModel
import XCTest

@testable import ProtonMail

final class BlockedSenderCacheUpdaterTests: XCTestCase {
    private var fetchStatusProvider: MockBlockedSenderFetchStatusProviderProtocol!
    private var internetStatusProvider: MockInternetConnectionStatusProviderProtocol!
    private var connectionStatusReceiver: MockConnectionStatusReceiver!
    private var refetchAllBlockedSenders: MockRefetchAllBlockedSendersUseCase!
    private var sut: BlockedSenderCacheUpdater!

    private let userInfo: UserInfo = .dummy

    override func setUpWithError() throws {
        try super.setUpWithError()

        fetchStatusProvider = .init()
        internetStatusProvider = .init()
        refetchAllBlockedSenders = .init()
        connectionStatusReceiver = .init()
        internetStatusProvider.statusStub.fixture = .connected

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
        wait(self.refetchAllBlockedSenders.executeStub.callCounter == 1)

        XCTAssertEqual(sut.state, .updateInProgress)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 1)
    }

    @MainActor
    func testRequestingTheUpdate_whileNotIdle_doesNothing() async {
        sut.requestUpdate()
        wait(self.refetchAllBlockedSenders.executeStub.callCounter == 1)

        XCTAssertNotEqual(sut.state, .idle)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 1)

        sut.requestUpdate()
        await waitForSideEffectsToOccur()

        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 1)
    }

    func testRequestingTheUpdate_whileOffline_triggersWaitingForOnlineState() {
        internetStatusProvider.statusStub.fixture = .notConnected

        var statusReceiver: ConnectionStatusReceiver?
        internetStatusProvider.registerStub.bodyIs { _, receiver, _ in
            statusReceiver = receiver
        }

        sut.requestUpdate()
        wait(self.internetStatusProvider.registerStub.callCounter == 1)

        XCTAssertEqual(sut.state, .waitingToBecomeOnline)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 0)
        XCTAssertEqual(internetStatusProvider.registerStub.callCounter, 1)

        statusReceiver?.connectionStatusHasChanged(newStatus: .connected)
        wait(self.internetStatusProvider.unRegisterStub.callCounter == 1)

        XCTAssertEqual(sut.state, .updateInProgress)
        XCTAssertEqual(internetStatusProvider.unRegisterStub.callCounter, 1)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 1)
    }

    func testSuccessfulUpdate_triggersIdleState() {
        refetchAllBlockedSenders.executeStub.bodyIs { _, completion in
            completion(nil)
        }

        sut.requestUpdate()
        wait(self.sut.state == .idle)

        XCTAssertEqual(sut.state, .idle)
    }

    func testFailedUpdate_triggersWaitingToRetryStateInsteadOfRetryingImmediately() {
        refetchAllBlockedSenders.executeStub.bodyIs { _, completion in
            completion(NSError.badResponse())
        }

        sut.requestUpdate()
        wait(self.sut.state == .waitingToRetryAfterError)

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
        let expected: [BlockedSenderCacheUpdater.State] = [.updateRequested, .updateInProgress, .idle]
        wait(delegate.blockedSenderCacheUpdaterStub.capturedArguments.map(\.second) == expected)
    }

    // MARK: fetch status flag

    func testSuccessfulUpdate_storesCompletedFlag() throws {
        refetchAllBlockedSenders.executeStub.bodyIs { _, completion in
            completion(nil)
        }

        sut.requestUpdate()
        wait(self.fetchStatusProvider.markBlockedSendersAsFetchedStub.callCounter == 1)

        XCTAssertEqual(fetchStatusProvider.markBlockedSendersAsFetchedStub.callCounter, 1)

        let latestCall = try XCTUnwrap(fetchStatusProvider.markBlockedSendersAsFetchedStub.lastArguments)
        XCTAssert(latestCall.a1)
        XCTAssertEqual(latestCall.a2, UserID(userInfo.userId))
    }

    func testFailedUpdate_doesntStoreCompletedFlag() {
        refetchAllBlockedSenders.executeStub.bodyIs { _, completion in
            completion(NSError.badResponse())
        }

        sut.requestUpdate()
        wait(self.sut.state == .waitingToRetryAfterError)

        XCTAssertEqual(fetchStatusProvider.markBlockedSendersAsFetchedStub.callCounter, 0)
    }

    // Quick explanation: we decided to fetch only once and then rely on the `EventsService` to handle changes.
    func testRefusesToUpdateIfAlreadyCompletedOnce() {
        fetchStatusProvider.checkIfBlockedSendersAreFetchedStub.bodyIs { _, _ in
            true
        }

        sut.requestUpdate()
        wait(self.sut.state == .idle)

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(refetchAllBlockedSenders.executeStub.callCounter, 0)
    }

    // MARK: helpers

    /// This method is needed because side effects happen on a background queue
    private func waitForSideEffectsToOccur() async {
        await sleep(milliseconds: 100)
    }
}
