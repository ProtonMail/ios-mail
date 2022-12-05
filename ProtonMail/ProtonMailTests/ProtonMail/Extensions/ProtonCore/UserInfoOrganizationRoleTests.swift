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
import ProtonCore_DataModel
@testable import ProtonMail

final class UserInfoOrganizationRoleTests: XCTestCase {
    var sut: UserInfo!

    override func setUp() {
        super.setUp()
        sut = UserInfo(maxSpace: nil,
                       usedSpace: nil,
                       language: nil,
                       maxUpload: nil,
                       role: nil,
                       delinquent: nil,
                       keys: nil,
                       userId: nil,
                       linkConfirmation: nil,
                       credit: nil,
                       currency: nil,
                       subscribed: nil)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testUserWithNoOrganizationRoleShouldNotBeAMember() {
        sut.role = UserInfo.OrganizationRole.none.rawValue
        XCTAssertFalse(sut.isMember)
    }

    func testUserInfoWithMemberOrganizationRoleShouldBeAMember() {
        sut.role = UserInfo.OrganizationRole.member.rawValue
        XCTAssertTrue(sut.isMember)
    }

    func testUserInfoWithOwnerOrganizationRoleShouldNotBeAMember() {
        sut.role = UserInfo.OrganizationRole.owner.rawValue
        XCTAssertFalse(sut.isMember)
    }
}
