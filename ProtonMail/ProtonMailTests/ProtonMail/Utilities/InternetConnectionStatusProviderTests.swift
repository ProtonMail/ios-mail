@testable import ProtonMail
import XCTest
import Network
import ProtonCore_TestingToolkit

class InternetConnectionStatusProviderTests: XCTestCase {

    var sut: InternetConnectionStatusProvider!
    var connectionMonitor: MockConnectionMonitor!
    var mockNWPath: MockNWPathProtocol!
    var connectionStatusReceiver: MockConnectionStatusReceiver!
    var mockDoH: DohInterfaceMock!
    var session: MockURLSessionProtocol!

    override func setUpWithError() throws {
        try super.setUpWithError()
        connectionStatusReceiver = MockConnectionStatusReceiver()
        connectionMonitor = .init()
        mockNWPath = .init()
        updateConnection(isConnected: false, interfaces: [.wiredEthernet])
        mockDoH = .init()
        session = .init()
        sut = InternetConnectionStatusProvider(
            connectionMonitor: connectionMonitor,
            doh: mockDoH,
            session: session
        )
    }

    override func tearDown() {
        super.tearDown()
        connectionMonitor = nil
        mockDoH = nil
        sut = nil
    }

    func testRegisterConnectionStatus() {
        sut.register(receiver: connectionStatusReceiver, fireWhenRegister: false)
        let expectation1 = expectation(description: "Closure is called")
        connectionStatusReceiver.connectionStatusHasChangedStub.bodyIs { _, newStatus in
            XCTAssertEqual(newStatus, .connectedViaWiFi)
            expectation1.fulfill()
        }
        updateConnection(isConnected: true, interfaces: [.wifi])
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUnregistering() {
        var statuses: [ConnectionStatus] = []
        let expectation1 = expectation(description: "Closure is called")
        connectionStatusReceiver.connectionStatusHasChangedStub.bodyIs { _, newStatus in
            statuses.append(newStatus)
            expectation1.fulfill()
        }
        sut.register(receiver: connectionStatusReceiver, fireWhenRegister: true)

        waitForExpectations(timeout: 1, handler: nil)
        sut.unRegister(receiver: connectionStatusReceiver)
        updateConnection(isConnected: true, interfaces: [.wifi])
        XCTAssertEqual(statuses, [.initialize])
    }

    func testCannotRegisterTwice() {
        var isUpdating = false
        let expectation1 = expectation(description: "Closure is called before updating status")
        expectation1.expectedFulfillmentCount = 2
        let expectation2 = expectation(description: "Closure is called after updating status")
        connectionStatusReceiver.connectionStatusHasChangedStub.bodyIs { callCounter, status in
            if isUpdating {
                // It won't register twice so only fired one time
                expectation2.fulfill()
            } else {
                // Closure is fired after register
                expectation1.fulfill()
            }
        }
        
        sut.register(receiver: connectionStatusReceiver, fireWhenRegister: true)
        sut.register(receiver: connectionStatusReceiver, fireWhenRegister: true)

        wait(for: [expectation1], timeout: 5)
        isUpdating = true
        sut.updateNewStatusToAll(.connected)
        wait(for: [expectation2], timeout: 5)
        XCTAssertEqual(connectionStatusReceiver.connectionStatusHasChangedStub.callCounter, 3)
    }

    func testHasConnection_whenConnectedViaVPN_andPingFails_itShouldReturnNotConnected() {
        sut.register(receiver: connectionStatusReceiver, fireWhenRegister: false)
        mockDoH.getCurrentlyUsedHostUrlStub.bodyIs { _ in
            return "https://pm.test"
        }

        let expectation1 = expectation(description: "status updated")
        connectionStatusReceiver.connectionStatusHasChangedStub.bodyIs { _, newStatus in
            XCTAssertEqual(newStatus, .notConnected)
            expectation1.fulfill()
        }

        mockNWPath.pathStatusStub.fixture = .satisfied
        mockNWPath.usesInterfaceTypeStub.bodyIs { _, interface in
            let expected: [NWInterface.InterfaceType] = [.wifi, .other]
            return expected.contains(interface)
        }
        session.dataTaskStub.bodyIs { _, request, handler in
            guard let link = request.url?.absoluteString else {
                XCTFail("Link shouldn't be nil")
                return MockURLSessionDataTaskProtocol()
            }
            XCTAssertEqual(link, "https://pm.test/core/tests/ping")
            let error = NSError(domain: "pm.test", code: -999)
            handler(nil, nil, error)
            return MockURLSessionDataTaskProtocol()
        }

        updateConnection(isConnected: true, interfaces: [.other])
        wait(for: [expectation1], timeout: 5)
    }

    func testHasConnection_whenConnectedViaVPN_andPingSucceeds_itShouldReturnConnected() {
        sut.register(receiver: connectionStatusReceiver, fireWhenRegister: false)
        mockDoH.getCurrentlyUsedHostUrlStub.bodyIs { _ in
            return "https://pm.test"
        }

        let expectation1 = expectation(description: "status updated")
        connectionStatusReceiver.connectionStatusHasChangedStub.bodyIs { _, newStatus in
            XCTAssertEqual(newStatus, .connected)
            expectation1.fulfill()
        }

        mockNWPath.pathStatusStub.fixture = .satisfied
        mockNWPath.usesInterfaceTypeStub.bodyIs { _, interface in
            let expected: [NWInterface.InterfaceType] = [.wifi, .other]
            return expected.contains(interface)
        }
        session.dataTaskStub.bodyIs { _, request, handler in
            guard let link = request.url?.absoluteString else {
                XCTFail("Link shouldn't be nil")
                return MockURLSessionDataTaskProtocol()
            }
            XCTAssertEqual(link, "https://pm.test/core/tests/ping")
            handler(nil, nil, nil)
            return MockURLSessionDataTaskProtocol()
        }

        updateConnection(isConnected: true, interfaces: [.other, .wifi])
        wait(for: [expectation1], timeout: 5)
    }
}

extension InternetConnectionStatusProviderTests {
    func updateConnection(isConnected: Bool, interfaces: [NWInterface.InterfaceType]) {
        mockNWPath.isPossiblyConnectedThroughVPNStub.fixture = interfaces.contains(.other)
        mockNWPath.usesInterfaceTypeStub.bodyIs { _, type in
            interfaces.contains(type)
        }
        mockNWPath.pathStatusStub.fixture = isConnected ? .satisfied : .unsatisfied
        connectionMonitor.pathUpdateClosureStub.setLastArguments?.a1?(mockNWPath)
    }
}
