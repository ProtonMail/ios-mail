@testable import ProtonMail
import XCTest

@available(iOS 12.0, *)
class InternetConnectionStatusProviderTests: XCTestCase {

    var sut: InternetConnectionStatusProvider!
    var notificationCenter: NotificationCenter!
    var reachabilityStub: ReachabilityStub!
    var emitedStatuses: [ConnectionStatus]!
    var connectMonitorMock: MockConnectionMonitor!

    override func setUp() {
        super.setUp()

        notificationCenter = NotificationCenter()
        reachabilityStub = ReachabilityStub()
        sut = InternetConnectionStatusProvider(notificationCenter: notificationCenter, reachability: reachabilityStub, connectionMonitor: connectMonitorMock)
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

        sut.registerConnectionStatus(callback)
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetConnectionStatusHasChanged() {
        sut.registerConnectionStatus { [weak self] in
            self?.emitedStatuses.append($0)
        }

        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi
        notificationCenter.post(name: .reachabilityChanged, object: reachabilityStub)

        XCTAssertEqual(emitedStatuses, [.notConnected, .connectedViaWiFi])
    }

    func testInvalidNotificationReceived() {
        sut.registerConnectionStatus { [weak self] in
            self?.emitedStatuses.append($0)
        }

        notificationCenter.post(name: .reachabilityChanged, object: nil)
        XCTAssertEqual(emitedStatuses, [.notConnected])
    }

    func testStopInternetConnectionStatusObservation() {
        sut.registerConnectionStatus { [weak self] in
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

}
