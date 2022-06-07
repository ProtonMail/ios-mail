//
//  ConversationCoreDataModelTests.swift
//  Proton MailTests - Created on 2020.
//
//
//  Copyright (c) 2020 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.
//

import XCTest
@testable import ProtonMail
import Groot

class ConversationCoreDataModelTests: XCTestCase {
    var conversation: Conversation!
    
    override func setUp() {
        let coredata = CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer)
        guard let metaConversation = conversationObjetcTestData.parseObjectAny() else {
            return
        }

        self.conversation = try! GRTJSONSerialization.object(withEntityName: Conversation.Attributes.entityName,
                                                          fromJSONDictionary: metaConversation,
                                                          in: coredata.rootSavingContext) as? Conversation
        _ = coredata.rootSavingContext.saveUpstreamIfNeeded()
    }

    func testConversationCreationInCoreData() throws {
        let managedObj = self.conversation
        XCTAssertNotNil(managedObj)
        let conversation = managedObj!
        XCTAssertEqual(conversation.conversationID, "7roRxUKBEBHTl22o-47jRh4A6i_uR4UNUX_az_zCmFR10yw6Nu40z-Pl8QRm-dzoVb6OdQ==")
        XCTAssertEqual(conversation.order, 300704832180)
        XCTAssertEqual(conversation.subject, "Fwd: Test photo")
        XCTAssertEqual(conversation.numMessages, 1)
        XCTAssertEqual(conversation.numUnread, 0)
        XCTAssertEqual(conversation.numAttachments, 5)
        
        XCTAssertEqual(conversation.size, 17711047)
        XCTAssertEqual(conversation.contextNumMessages, 1)
        XCTAssertEqual(conversation.contextNumUnread, 0)
        XCTAssertEqual(conversation.contextNumAttachments, 5)
        XCTAssertEqual(conversation.contextSize, 17711047)
        
        XCTAssertEqual(conversation.contextLabels.count, 2)
        let contextlabel1 = conversation.contextLabels.allObjects[0] as? ContextLabel
        XCTAssertNotNil(contextlabel1)
//        XCTAssertEqual(contextlabel1!.conversations, conversation)
        
        let contextlabel2 = conversation.contextLabels.allObjects[1] as? ContextLabel
        XCTAssertNotNil(contextlabel2)
//        XCTAssertEqual(contextlabel2!.conversations, conversation)
        
        XCTAssertNotNil(conversation.contextTime)
        XCTAssertEqual(conversation.contextTime?.timeIntervalSince1970, 1605861149)
        
        XCTAssertNotNil(conversation.time)
        XCTAssertEqual(conversation.time?.timeIntervalSince1970, 1605861149)
        
        XCTAssertNil(conversation.expirationTime)
        
        XCTAssertNotNil(conversation.senders)
        XCTAssertNotEqual(conversation.senders, "")
        
        XCTAssertNotNil(conversation.recipients)
        XCTAssertNotEqual(conversation.recipients, "")
    }
    
    func testGetNumUnread() {
        let sut = self.conversation
        XCTAssertEqual(sut?.getNumUnread(labelID: "0"), 0)
        XCTAssertEqual(sut?.getNumUnread(labelID: "5"), 2)
        XCTAssertEqual(sut?.getNumUnread(labelID: "9"), 0)
    }
    
    func testIsUnread() {
        let sut = self.conversation!
        XCTAssertFalse(sut.isUnread(labelID: "0"))
        XCTAssertTrue(sut.isUnread(labelID: "5"))
        XCTAssertFalse(sut.isUnread(labelID: "9"))
    }
    
    func testGetNumMessages() {
        let sut = self.conversation!
        XCTAssertEqual(sut.getNumMessages(labelID: "0"), 1)
        XCTAssertEqual(sut.getNumMessages(labelID: "5"), 9)
        XCTAssertEqual(sut.getNumMessages(labelID: "9"), 0)
    }
    
    func testGetTime() {
        let sut = self.conversation!
        XCTAssertEqual(sut.getTime(labelID: "0"), Date(timeIntervalSince1970: 1605861149))
        XCTAssertEqual(sut.getTime(labelID: "5"), Date(timeIntervalSince1970: 1605861149))
        XCTAssertNil(sut.getTime(labelID: "9"))
    }
    
    func testSingleMarkAsChangesUnread() {
        let unReadNumber = self.conversation.numUnread.intValue
        let sut = self.conversation!
        sut.applySingleMarkAsChanges(unRead: true, labelID: "0")
        for label in sut.contextLabels {
            if let l = label as? ContextLabel {
                if l.labelID == "0" {
                    XCTAssertEqual(l.unreadCount, 1)
                    return
                }
            }
        }
        XCTAssertEqual(sut.numUnread.intValue, unReadNumber + 1)
        XCTFail()
    }
    
    func testSingleMarkAsChangesRead() {
        let unReadNumber = self.conversation.numUnread.intValue
        let sut = self.conversation!
        sut.applySingleMarkAsChanges(unRead: false, labelID: "0")
        for label in sut.contextLabels {
            if let l = label as? ContextLabel {
                if l.labelID == "0" {
                    XCTAssertEqual(l.unreadCount, 0)
                    return
                }
            }
        }
        XCTAssertEqual(sut.numUnread.intValue, unReadNumber - 1)
        XCTFail()
    }
    
    func testMarkAsChangesUnread() {
        let unReadNumber = self.conversation.numUnread.intValue
        let sut = self.conversation!
        sut.applyMarksAsChanges(unRead: true, labelID: "5")
        for label in sut.contextLabels {
            if let l = label as? ContextLabel {
                if l.labelID == "5" {
                    XCTAssertEqual(l.unreadCount, 3)
                }
            }
        }
        XCTAssertEqual(sut.numUnread.intValue, unReadNumber + 1)
    }
    
    func testMarkAsChangesRead() {
        let sut = self.conversation!
        sut.applyMarksAsChanges(unRead: false, labelID: "5")
        for label in sut.contextLabels {
            if let l = label as? ContextLabel {
                if l.labelID == "5" {
                    XCTAssertEqual(l.unreadCount, 0)
                }
            }
        }
        XCTAssertEqual(sut.numUnread.intValue, 0)
    }
    
    func testApplyLabelChangesOnOneMessage() {
        let sut = self.conversation!
        sut.applyLabelChangesOnOneMessage(labelID: Message.Location.starred.rawValue, apply: true)
        
        let target = sut.contextLabels.compactMap({$0 as? ContextLabel}).filter({$0.labelID == Message.Location.starred.rawValue})
        XCTAssertEqual(target.count, 1)
        XCTAssertEqual(sut.contextLabels.count, 3)
    }
    
    func testApplyLabelChangesOnOneMessageWithExistLabel() {
        let sut = self.conversation!
        let originalMessageCount = sut.contextLabels.compactMap({$0 as? ContextLabel}).filter({$0.labelID == Message.Location.inbox.rawValue}).first?.messageCount ?? -1
        
        sut.applyLabelChangesOnOneMessage(labelID: Message.Location.inbox.rawValue, apply: true)
        
        let target = sut.contextLabels.compactMap({$0 as? ContextLabel}).filter({$0.labelID == Message.Location.inbox.rawValue}).first
        XCTAssertNotNil(target)
        XCTAssertEqual(target!.messageCount.intValue, originalMessageCount.intValue + 1)
    }
    
    func testUnApplyLabelChangesOnOneMessage() {
        let sut = self.conversation!
        sut.applyLabelChangesOnOneMessage(labelID: Message.Location.starred.rawValue, apply: true)
        
        let target = sut.contextLabels.compactMap({$0 as? ContextLabel}).filter({$0.labelID == Message.Location.starred.rawValue})
        XCTAssertEqual(target.count, 1)
        XCTAssertEqual(sut.contextLabels.count, 3)
        
        sut.applyLabelChangesOnOneMessage(labelID: Message.Location.starred.rawValue, apply: false)
        
        let targetDeleted = sut.contextLabels.compactMap({$0 as? ContextLabel}).filter({$0.labelID == Message.Location.starred.rawValue})
        XCTAssertEqual(targetDeleted.count, 0)
        XCTAssertEqual(sut.contextLabels.count, 2)
    }
    
    func testUnApplyLabelChangesOnOneMessageWithExistLabel() {
        let sut = self.conversation!
        
        let originalMessageCount = sut.contextLabels.compactMap({$0 as? ContextLabel}).filter({$0.labelID == Message.Location.allmail.rawValue}).first?.messageCount ?? -1
        
        sut.applyLabelChangesOnOneMessage(labelID: Message.Location.allmail.rawValue, apply: false)
        
        let target = sut.contextLabels.compactMap({$0 as? ContextLabel}).filter({$0.labelID == Message.Location.allmail.rawValue})
        XCTAssertEqual(target.count, 1)
        XCTAssertEqual(target.first!.messageCount.intValue, originalMessageCount.intValue - 1)
        XCTAssertEqual(sut.contextLabels.count, 2)
    }
    
    func testApplyLabelChanges() {
        let sut = self.conversation!
        
        let originalMessageCount = sut.numMessages.intValue
        sut.applyLabelChanges(labelID: Message.Location.starred.rawValue, apply: true)
        
        let target = sut.contextLabels.compactMap({$0 as? ContextLabel}).filter({$0.labelID == Message.Location.starred.rawValue}).first
        XCTAssertNotNil(target)
        XCTAssertEqual(target!.messageCount.intValue, originalMessageCount)
    }
    
    func testUnappleLabelChanges() {
        let sut = self.conversation!
        
        sut.applyLabelChanges(labelID: Message.Location.inbox.rawValue, apply: false)
        
        XCTAssertFalse(sut.contains(of: Message.Location.inbox.rawValue))
    }
    
    func testApplyLabelChangesToExsistLabel() {
        let sut = self.conversation!
        
        let inboxLabelMessageCount = sut.contextLabels.compactMap({ $0 as? ContextLabel }).filter({$0.labelID == Message.Location.inbox.rawValue}).first?.messageCount.intValue ?? -1
        XCTAssertNotEqual(inboxLabelMessageCount, -1)
        
        let originalMessageCount = sut.numMessages.intValue
        sut.applyLabelChanges(labelID: Message.Location.inbox.rawValue, apply: true)
        
        let target = sut.contextLabels.compactMap({$0 as? ContextLabel}).filter({$0.labelID == Message.Location.inbox.rawValue}).first
        XCTAssertNotNil(target)
        XCTAssertEqual(target!.messageCount.intValue, originalMessageCount)
    }
}
