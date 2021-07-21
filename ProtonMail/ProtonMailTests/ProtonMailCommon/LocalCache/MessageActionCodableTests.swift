//
//  MessageActionCodableTests.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import XCTest
@testable import ProtonMail

class MessageActionCodableTests: XCTestCase {

    func testAllCasesAreCovered() {
        let action = MessageAction.emptySpam
        switch action {
        case .saveDraft:
            break
        case .uploadAtt:
            break
        case .uploadPubkey:
            break
        case .deleteAtt:
            break
        case .read:
            break
        case .unread:
            break
        case .delete:
            break
        case .send:
            break
        case .emptyTrash:
            break
        case .emptySpam:
            break
        case .empty:
            break
        case .label:
            break
        case .unlabel:
            break
        case .folder:
            break
        case .updateLabel:
            break
        case .createLabel:
            break
        case .deleteLabel:
            break
        case .signout:
            break
        case .signin:
            break
        case .fetchMessageDetail:
            break
        case .updateAttKeyPacket:
            break
        // Warning: Newly added cases must be covered in one specific test case below to make sure the codable implementation is complete
        }
        XCTAssert(true, "All cases covered")
    }
    func testSaveDraft() throws {
        let action: MessageAction = .saveDraft(messageObjectID: "aDraft")
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testUploadAtt() throws {
        let action: MessageAction = .uploadAtt(attachmentObjectID: "AnAttachment")
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testUploadPubkey() throws {
        let action: MessageAction = .uploadPubkey(attachmentObjectID: "PubKeyAttachment")
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }
    
    func testUpdate() throws {
        let action: MessageAction = .updateAttKeyPacket(messageObjectID: "AObjectID", addressID: "AnAddressID")
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testDeleteAtt() throws {
        let action: MessageAction = .deleteAtt(attachmentObjectID: "DeleteAtt")
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testRead() throws {
        let action: MessageAction = .read(itemIDs: ["item1", "item2"], objectIDs: ["object1", "object2"])
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
        let action2: MessageAction = .read(itemIDs: [], objectIDs: [])
        let encoded2 = try JSONEncoder().encode(action2)
        let decoded2 = try JSONDecoder().decode(MessageAction.self, from: encoded2)
        XCTAssertEqual(action2, decoded2)
    }

    func testUnread() throws {
        let action: MessageAction = .unread(currentLabelID: "aLabelID", itemIDs: ["item1", "item2"], objectIDs: ["object1", "object2"])
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
        let action2: MessageAction = .unread(currentLabelID: "aLabelID", itemIDs: [], objectIDs: [])
        let encoded2 = try JSONEncoder().encode(action2)
        let decoded2 = try JSONDecoder().decode(MessageAction.self, from: encoded2)
        XCTAssertEqual(action2, decoded2)
    }

    func testDelete() throws {
        let action: MessageAction = .delete(currentLabelID: "anID", itemIDs: ["object1", "object2"])
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
        let action2: MessageAction = .delete(currentLabelID: nil, itemIDs: [])
        let encoded2 = try JSONEncoder().encode(action2)
        let decoded2 = try JSONDecoder().decode(MessageAction.self, from: encoded2)
        XCTAssertEqual(action2, decoded2)
    }

    func testSend() throws {
        let action: MessageAction = .send(messageObjectID: "sendID")
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testEmptyTrash() throws {
        let action: MessageAction = .emptyTrash
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testEmptySpam() throws {
        let action: MessageAction = .emptySpam
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testEmpty() throws {
        let action: MessageAction = .empty(currentLabelID: "anID")
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testLabel() throws {
        let action: MessageAction = .label(currentLabelID: "label", shouldFetch: true, itemIDs: ["bla"], objectIDs: ["foo"])
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
        let action2: MessageAction = .label(currentLabelID: "label", shouldFetch: nil, itemIDs: [], objectIDs: [])
        let encoded2 = try JSONEncoder().encode(action2)
        let decoded2 = try JSONDecoder().decode(MessageAction.self, from: encoded2)
        XCTAssertEqual(action2, decoded2)
    }

    func testUnlabel() throws {
        let action: MessageAction = .unlabel(currentLabelID: "label", shouldFetch: true, itemIDs: ["bla"], objectIDs: ["foo"])
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
        let action2: MessageAction = .unlabel(currentLabelID: "label", shouldFetch: nil, itemIDs: [], objectIDs: [])
        let encoded2 = try JSONEncoder().encode(action2)
        let decoded2 = try JSONDecoder().decode(MessageAction.self, from: encoded2)
        XCTAssertEqual(action2, decoded2)
    }

    func testFolder() throws {
        let action: MessageAction = .folder(nextLabelID: "next", itemIDs: ["items"], objectIDs: ["objects"])
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
        let action2: MessageAction = .folder(nextLabelID: "next", itemIDs: [], objectIDs: [])
        let encoded2 = try JSONEncoder().encode(action2)
        let decoded2 = try JSONDecoder().decode(MessageAction.self, from: encoded2)
        XCTAssertEqual(action2, decoded2)
    }

    func testUpdateLabel() throws {
        let action: MessageAction = .updateLabel(labelID: "labelID", name: "name", color: "color")
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testCreateLabel() throws {
        let action: MessageAction = .createLabel(name: "name", color: "color", isFolder: true)
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testDeleteLabel() throws {
        let action: MessageAction = .deleteLabel(labelID: "label")
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testSignout() throws {
        let action: MessageAction = .signout
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testSignin() throws {
        let action: MessageAction = .signin
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }

    func testFetchMessageDetail() throws {
        let action: MessageAction = .fetchMessageDetail
        let encoded = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(MessageAction.self, from: encoded)
        XCTAssertEqual(action, decoded)
    }
}
