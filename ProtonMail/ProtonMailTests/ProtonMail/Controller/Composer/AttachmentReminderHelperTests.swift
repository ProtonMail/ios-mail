// Copyright (c) 2022 Proton Technologies AG
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

final class AttachmentReminderHelperTests: XCTestCase {

    func testHasAttachKeyword() {
        var content = "Hi please see the attachment and see included"
        XCTAssertTrue(AttachReminderHelper.hasAttachKeyword(content: content, language: .english))

        content = "dsield voir fichier joint eiflsfpe "
        XCTAssertTrue(AttachReminderHelper.hasAttachKeyword(content: content, language: .french))

        content = "dsield siehe Anhang joint eiflsfpe "
        XCTAssertTrue(AttachReminderHelper.hasAttachKeyword(content: content, language: .german))

        content = "dsield ver archivo incluido lsfpe "
        XCTAssertTrue(AttachReminderHelper.hasAttachKeyword(content: content, language: .spanish))

        content = "dsield ver archivo прикрепленный файл lsfpe "
        XCTAssertTrue(AttachReminderHelper.hasAttachKeyword(content: content, language: .russian))

        content = "dsield ver \u{00e8} allegato файл lsfpe "
        XCTAssertTrue(AttachReminderHelper.hasAttachKeyword(content: content, language: .italian))

        content = " feolse fiels ver ver inclu\u{00ed}do fiels"
        XCTAssertTrue(AttachReminderHelper.hasAttachKeyword(content: content, language: .portuguese))

        content = "dsield ver anexado eiflsfpe "
        XCTAssertTrue(AttachReminderHelper.hasAttachKeyword(content: content, language: .portugueseBrazil))

        content = "dsield ver zie bijlage eiflsfpe "
        XCTAssertTrue(AttachReminderHelper.hasAttachKeyword(content: content, language: .dutch))

        content = "dsield ver patrz w za\u{0142}\u{0105}czeniu zie bijlage eiflsfpe "
        XCTAssertTrue(AttachReminderHelper.hasAttachKeyword(content: content, language: .polish))
        XCTAssertFalse(AttachReminderHelper.hasAttachKeyword(content: content, language: .japanese))
    }

}
