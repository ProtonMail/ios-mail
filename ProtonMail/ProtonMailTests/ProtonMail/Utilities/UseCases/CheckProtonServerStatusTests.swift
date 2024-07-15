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

import ProtonCoreNetworking
import ProtonCoreTestingToolkitUnitTestsDoh
@testable import ProtonMail
import XCTest

final class CheckProtonServerStatusTests: XCTestCase {
    private var sut: CheckProtonServerStatus!
    private var mockURLSession: MockURLSessionProtocol!
    private var mockDoH: DohInterfaceMock!
    private var mockInternetConnection: MockInternetConnectionStatusProviderProtocol!

    private let dummyBaseUrl = "https://example.com"
    private var protonPingURL: URL { URL(string: "\(dummyBaseUrl)/core/v4/tests/ping")! }

    override func setUp() {
        super.setUp()
        mockURLSession = .init()
        mockDoH = .init()
        mockDoH.getCurrentlyUsedHostUrlStub.bodyIs { _ in return self.dummyBaseUrl }
        mockInternetConnection = .init()
        let dependencies = CheckProtonServerStatus.Dependencies(
            session: mockURLSession,
            doh: mockDoH,
            internetConnectionStatus: mockInternetConnection
        )
        sut = CheckProtonServerStatus(dependencies: dependencies)
    }

    override func tearDown() {
        super.tearDown()
        mockURLSession = nil
        mockDoH = nil
        mockInternetConnection = nil
        sut = nil
    }

    func testExecute_whenProtonServerPingSucceedsAndInternetConnected_itReturnsServerUp() async {
        mockInternetConnection.statusStub.fixture = .connected
        setUpURLSessionSuccess(for: protonPingURL)

        let protonStatus = await sut.execute()
        XCTAssertEqual(protonStatus, .serverUp)
    }

    func testExecute_whenProtonServerPingSucceedsAndInternetNotConnected_itReturnsServerUp() async {
        mockInternetConnection.statusStub.fixture = .notConnected
        setUpURLSessionSuccess(for: protonPingURL)

        let protonStatus = await sut.execute()
        XCTAssertEqual(protonStatus, .serverUp)
    }

    func testExecute_whenProtonServerPingFailsAndInternetConnected_itReturnsServerDown() async {
        mockInternetConnection.statusStub.fixture = .connected
        setUpURLSessionForFailure()

        let protonStatus = await sut.execute()
        XCTAssertEqual(protonStatus, .serverDown)
    }

    func testExecute_whenProtonServerPingFailsAndInternetNotConnected_itReturnsStatusUnknown() async {
        mockInternetConnection.statusStub.fixture = .notConnected
        setUpURLSessionForFailure()

        let protonStatus = await sut.execute()
        XCTAssertEqual(protonStatus, .unknown)
    }
}

private extension CheckProtonServerStatusTests {

    func setUpURLSessionSuccess(for url: URL) {
        mockURLSession.dataStub.bodyIs { _, request in
            guard
                let urlString = request.url?.absoluteString,
                urlString == url.absoluteString
            else {
                return (Data(), HTTPURLResponse(statusCode: 404))
            }
            return (Data(), HTTPURLResponse(statusCode: 200))
        }
    }

    func setUpURLSessionForFailure() {
        mockURLSession.dataStub.bodyIs { _, request in
            return (Data(), HTTPURLResponse(statusCode: 404))
        }
    }
}
