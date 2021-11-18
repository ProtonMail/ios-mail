// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import XCTest
@testable import ProtonMail

class ContactsUtilsTest: XCTestCase {

    func testWithoutEItemCase() {
        let data = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nitem1.EMAIL;TYPE=INTERNET:school@mail.com\r\nitem2.EMAIL;TYPE=INTERNET:iclould@mail.com\r\nitem3.EMAIL;TYPE=INTERNET:other@mail.com\r\nUID:C803E418-93A5-4816-B2ED-0A169F502BC4:ABPerson\r\nFN:Anc Fake\r\nEND:VCARD\r\n"
        let transferred = ContactsUtils.removeEItem(vCard2Data: data)
        XCTAssertEqual(data, transferred)
    }

    func testTransferSuccess() {
        let data = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nEItem1.EMAIL;TYPE=INTERNET,HOME,pref:home@mail.com\r\nEItem2.EMAIL;TYPE=INTERNET,WORK:work@mail.com\r\nitem1.EMAIL;TYPE=INTERNET:school@mail.com\r\nitem2.EMAIL;TYPE=INTERNET:iclould@mail.com\r\nitem3.EMAIL;TYPE=INTERNET:other@mail.com\r\nUID:C803E418-93A5-4816-B2ED-0A169F502BC4:ABPerson\r\nFN:Anc Fake\r\nEND:VCARD\r\n"
        let expected = "BEGIN:VCARD\r\nVERSION:4.0\r\nPRODID:pm-ez-vcard 0.0.1\r\nitem4.EMAIL;TYPE=INTERNET,HOME,pref:home@mail.com\r\nitem5.EMAIL;TYPE=INTERNET,WORK:work@mail.com\r\nitem1.EMAIL;TYPE=INTERNET:school@mail.com\r\nitem2.EMAIL;TYPE=INTERNET:iclould@mail.com\r\nitem3.EMAIL;TYPE=INTERNET:other@mail.com\r\nUID:C803E418-93A5-4816-B2ED-0A169F502BC4:ABPerson\r\nFN:Anc Fake\r\nEND:VCARD\r\n"
        let transferred = ContactsUtils.removeEItem(vCard2Data: data)
        XCTAssertEqual(expected, transferred)
    }

    func testEmptyInput() {
        let data = ""
        let transferred = ContactsUtils.removeEItem(vCard2Data: data)
        XCTAssertEqual(transferred, data)
    }
}
