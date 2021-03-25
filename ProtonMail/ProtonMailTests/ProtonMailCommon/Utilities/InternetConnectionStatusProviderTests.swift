@testable import ProtonMail
import XCTest

class InternetConnectionStatusProviderTests: XCTestCase {

    var sut: InternetConnectionStatusProvider!
    var notificationCenter: NotificationCenter!
    var reachabilityStub: ReachabilityStub!
    var emitedStatuses: [NetworkStatus]!

    override func setUp() {
        super.setUp()

        notificationCenter = NotificationCenter()
        reachabilityStub = ReachabilityStub()
        sut = InternetConnectionStatusProvider(notificationCenter: notificationCenter, reachability: reachabilityStub)
        emitedStatuses = []
    }

    override func tearDown() {
        super.tearDown()

        notificationCenter = nil
        reachabilityStub = nil
        sut = nil
        emitedStatuses = []
    }

    func testGetConnectionStatusHasChanged() {
        sut.getConnectionStatuses { [weak self] in
            self?.emitedStatuses.append($0)
        }

        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi
        notificationCenter.post(name: .reachabilityChanged, object: reachabilityStub)

        XCTAssertEqual(emitedStatuses, [.NotReachable, .ReachableViaWiFi])
    }

    func testInvalidNotificationReceived() {
        sut.getConnectionStatuses { [weak self] in
            self?.emitedStatuses.append($0)
        }

        notificationCenter.post(name: .reachabilityChanged, object: nil)
        XCTAssertEqual(emitedStatuses, [.NotReachable])
    }

    func testStopInternetConnectionStatusObservation() {
        sut.getConnectionStatuses { [weak self] in
            self?.emitedStatuses.append($0)
        }

        sut.stopInternetConnectionStatusObservation()

        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi
        notificationCenter.post(name: .reachabilityChanged, object: reachabilityStub)

        XCTAssertEqual(emitedStatuses, [.NotReachable])
    }

    func testCurrentStatus() {
        XCTAssertEqual(sut.currentStatus, .NotReachable)

        reachabilityStub.currentReachabilityStatusStub = .ReachableViaWiFi

        XCTAssertEqual(sut.currentStatus, .ReachableViaWiFi)
    }

}
