// Copyright (c) 2022 Proton AG
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

@testable import ProtonMail
import XCTest

class NetworkTroubleShootViewModelTests: XCTestCase {
    var dohStub: DohStatusStub!
    var dohCacheStub: DohStub!
    var sut: NetworkTroubleShootViewModel!

    override func setUp() {
        super.setUp()
        dohStub = DohStatusStub()
        dohCacheStub = DohStub()
        sut = NetworkTroubleShootViewModel(doh: dohStub, dohSetting: dohCacheStub)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        dohStub = nil
        dohCacheStub = nil
    }

    func testGetDohStatus() {
        dohStub.status = .off
        XCTAssertEqual(sut.dohStatus, .off)

        dohStub.status = .on
        XCTAssertEqual(sut.dohStatus, .on)
    }

    func testSetDohStatus() {
        sut.dohStatus = .on
        XCTAssertEqual(dohStub.status, .on)
        XCTAssertTrue(dohCacheStub.isDohOn)

        sut.dohStatus = .off
        XCTAssertEqual(dohStub.status, .off)
        XCTAssertFalse(dohCacheStub.isDohOn)
    }

    func testGetItems() {
        XCTAssertEqual(sut.items.count, 8)
        XCTAssertEqual(sut.items, [
            .allowSwitch,
            .noInternetNotes,
            .ispNotes,
            .blockNotes,
            .antivirusNotes,
            .firewallNotes,
            .downtimeNotes,
            .otherNotes
        ])
    }

    func testGetTitle() {
        XCTAssertEqual(sut.title, LocalString._troubleshooting_title)
    }
}
