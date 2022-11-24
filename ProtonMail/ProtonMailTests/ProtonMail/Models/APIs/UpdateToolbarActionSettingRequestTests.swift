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

class UpdateToolbarActionSettingRequestTests: XCTestCase {
    func testInit() throws {
        let messageActions: [ServerToolbarAction] = [.viewHTML, .moveToSpam]
        let conversationActions: [ServerToolbarAction] = [.starOrUnstar, .moveToArchive]
        let listViewActions: [ServerToolbarAction] = [.moveToTrash, .markAsReadOrUnread]

        let sut = try XCTUnwrap(UpdateToolbarActionSettingRequest(
            message: messageActions,
            conversation: conversationActions,
            listView: listViewActions
        ))

        XCTAssertEqual(sut.method, .put)
        XCTAssertEqual(sut.path, "/mail/v4/settings/mobilesettings")
        let parameter = try XCTUnwrap(sut.parameters)
        let msgActions = try XCTUnwrap(parameter["MessageToolbar"] as? [String])
        XCTAssertEqual(msgActions, messageActions.map(\.rawValue))

        let conActions = try XCTUnwrap(parameter["ConversationToolbar"] as? [String])
        XCTAssertEqual(conActions, conversationActions.map(\.rawValue))

        let listActions = try XCTUnwrap(parameter["ListToolbar"] as? [String])
        XCTAssertEqual(listActions, listViewActions.map(\.rawValue))
    }

    func testInit_withNil() throws {
        let sut = UpdateToolbarActionSettingRequest(
            message: nil,
            conversation: nil,
            listView: nil
        )
        XCTAssertNil(sut)
    }
}
