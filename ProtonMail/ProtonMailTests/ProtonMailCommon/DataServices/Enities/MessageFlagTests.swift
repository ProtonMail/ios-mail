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

import XCTest
@testable import ProtonMail

final class MessageFlagTests: XCTestCase {

    func testDescription() {
        let flag = MessageFlag(rawValue: 4279238655)
        let expected = "Raw: 4279238655, contains:FLAG_RECEIVED, FLAG_SENT, FLAG_INTERNAL, FLAG_E2E, FLAG_AUTO, FLAG_REPLIED, FLAG_REPLIEDALL, FLAG_FORWARDED, FLAG_AUTOREPLIED, FLAG_IMPORTED, FLAG_OPENED, FLAG_RECEIPT_SENT, FLAG_NOTIFIED, FLAG_TOUCHED, FLAG_RECEIPT, FLAG_PROTON, FLAG_RECEIPT_REQUEST, FLAG_PUBLIC_KEY, FLAG_SIGN, FLAG_UNSUBSCRIBED, FLAG_SPF_FAIL, FLAG_DKIM_FAIL, FLAG_DMARC_FAILED, FLAG_HAM_MANUAL, FLAG_SPAM_AUTO, FLAG_SPAM_MANUAL, FLAG_AUTO_PHISHING, FLAG_MANUAL_PHISHING"
        XCTAssertEqual(flag.description, expected)
    }

}
