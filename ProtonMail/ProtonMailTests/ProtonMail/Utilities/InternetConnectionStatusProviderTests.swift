@testable import ProtonMail
import XCTest

@available(iOS 12.0, *)
class InternetConnectionStatusProviderTests: XCTestCase {

    var sut: InternetConnectionStatusProvider!
    var notificationCenter: NotificationCenter!
    var reachabilityStub: ReachabilityStub!
    var emitedStatuses: [ConnectionStatus]!
    private let observerID = UUID()

    override func setUp() {
        super.setUp()

        notificationCenter = NotificationCenter()
        reachabilityStub = ReachabilityStub()
        reachabilityStub.currentReachabilityStatusStub = .NotReachable
        sut = InternetConnectionStatusProvider(notificationCenter: notificationCenter, reachability: reachabilityStub, connectionMonitor: nil)
        emitedStatuses = []
    }

    override func tearDown() {
        super.tearDown()

        notificationCenter = nil
        reachabilityStub = nil
        sut = nil
        emitedStatuses = []
    }

    func testRegisterConnectionStatus() {
        let expectation1 = expectation(description: "Closure is called")
        let callback: (ConnectionStatus) -> Void = { status in
            XCTAssertEqual(status, .connectedViaWiFi)
            expectation1.fulfill()
        }
        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi

        sut.registerConnectionStatus(observerID: observerID, callback: callback)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetConnectionStatusHasChanged() {
        sut.registerConnectionStatus(observerID: observerID) { [weak self] in
            self?.emitedStatuses.append($0)
        }

        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi
        notificationCenter.post(name: .reachabilityChanged, object: reachabilityStub)

        XCTAssertEqual(emitedStatuses, [.notConnected, .connectedViaWiFi])
    }

    func testInvalidNotificationReceived() {
        sut.registerConnectionStatus(observerID: observerID) { [weak self] in
            self?.emitedStatuses.append($0)
        }

        notificationCenter.post(name: .reachabilityChanged, object: nil)
        XCTAssertEqual(emitedStatuses, [.notConnected])
    }

    func testStopInternetConnectionStatusObservation() {
        sut.registerConnectionStatus(observerID: observerID) { [weak self] in
            self?.emitedStatuses.append($0)
        }

        sut.stopInternetConnectionStatusObservation()

        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi
        notificationCenter.post(name: .reachabilityChanged, object: reachabilityStub)

        XCTAssertEqual(emitedStatuses, [.notConnected])
    }

    func testCurrentStatus() {
        XCTAssertEqual(sut.currentStatus, .notConnected)

        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi

        XCTAssertEqual(sut.currentStatus, .connectedViaWiFi)
    }

    func testCannotRegisterTwice() {
        var firstCallbackCounter = 0
        var secondCallbackCounter = 0

        sut.registerConnectionStatus(observerID: observerID) { _ in
            firstCallbackCounter += 1
        }

        sut.registerConnectionStatus(observerID: observerID) { _ in
            secondCallbackCounter += 1
        }

        // the act of registering already fires the callback
        XCTAssertEqual(firstCallbackCounter, 1)
        XCTAssertEqual(secondCallbackCounter, 1)

        sut.updateNewStatusToAll(.connected)

        // note that only the 2nd counter has been incremented, because the 1st callback is no longer registered
        XCTAssertEqual(firstCallbackCounter, 1)
        XCTAssertEqual(secondCallbackCounter, 2)
    }

    func testUnregistering() {
        var callbackCounter = 0

        sut.registerConnectionStatus(observerID: observerID) { _ in
            callbackCounter += 1
        }

        // the act of registering already fires the callback
        XCTAssertEqual(callbackCounter, 1)

        sut.unregisterObserver(observerID: observerID)

        sut.updateNewStatusToAll(.connected)

        // note that the counter has not been incremented, because the callback has been unregistered
        XCTAssertEqual(callbackCounter, 1)
    }
}
