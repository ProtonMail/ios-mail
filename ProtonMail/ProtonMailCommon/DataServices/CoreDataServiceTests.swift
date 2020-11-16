//
//  CoreDataServiceTests.swift
//  ProtonMail - Created on 12/19/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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
import Groot

class CoreDataServiceTests: XCTestCase {
    
    override func setUp() {
    }
    override func tearDown() {
        
    }
    
    
    func testMessageTableWithEmptyValues() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        //        try? FileManager.default.removeItem(at:  CoreDataStore.tempUrl)
        let coredata = CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer)
        let metadata = """
     {
        "IsForwarded" : 0,
        "IsEncrypted" : 1,
        "ExpirationTime" : 0,
        "ReplyTo" : {
            "Address" : "contact@protonmail.ch",
            "Name" : "ProtonMail"
        },
        "Subject" : "Important phishing warning for all ProtonMail users",
        "Size" : 2217,
        "ToList" : "null",
        "Order" : 200441873160,
        "IsRepliedAll" : 0,
        "ExternalID" : "MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch",
        "AddressID" : "hbBwBsOdTi5cDhhZcF28yrJ50AZQ8jhXF4d0P7OaUcCS5iv2N8hN_FjvAyPMt8EiP5ch_E_81gHZAjK4D3gfzw==",
        "Location" : 0,
        "LabelIDs" : [
        "0",
        "5",
        "10"
        ],
        "Time" : 1525279399,
        "NumAttachments" : 0,
        "SenderAddress" : "contact@protonmail.ch",
        "MIMEType" : "texthtml",
        "Starred" : 1,
        "Unread" : 0,
        "ID" : "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==",
        "ConversationID" : "3Spjf96LXv8EDUylCxJkKsL7x9IgBac_0z416buSBBMwAkbh_dHh2Ng7O6ss70yhlaLBht0hiJqvqbxoBKtb9Q==",
        "Flags" : 13,
        "SenderName" : "ProtonMail",
        "SpamScore" : 0,
        "Type" : 0,
        "CCList" : "nil",
        "Sender" : {
            "Address" : "contact@protonmail.ch",
            "Name" : "ProtonMail"
        },
        "IsReplied" : 0
    }
    """
        
        let metadata1 = """
         {
            "IsForwarded" : 0,
            "BCCList" : [
            ],
            "Size" : 2217,
            "ToList" : [
            {
            "Address" : "feng88@protonmail.com",
            "Name" : "",
            "Group" : ""
            }
            ],
            "IsReplied" : 0
        }
        """
        guard let metaMsg = metadata.parseObjectAny() else {
            return
        }
        
        let managedObj = try? GRTJSONSerialization.object(withEntityName: Message.Attributes.entityName,
                                                          fromJSONDictionary: metaMsg,
                                                          in: coredata.mainManagedObjectContext) as? Message
        // apply the label changes
        
        let error = coredata.mainManagedObjectContext.saveUpstreamIfNeeded()
        XCTAssertNil(error)
        XCTAssertNotNil(managedObj)
        guard let message = managedObj as? Message else {
            XCTAssertNotNil(nil)
            return
        }
        XCTAssertEqual(message.messageID, "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==")
        XCTAssertEqual(message.body, "")
        XCTAssertEqual(message.spamScore, 0)
        XCTAssertEqual(message.mimeType, "texthtml")
        //        print(message.toList)
        //        print(message.ccList)
        //        print(message.bccList)
    }
    
    func testBackgroudContext() {
        return //TODO::FIXME. this test fails
        for i in 1 ... 50 {
            // Put setup code here. This method is called before the invocation of each test method in the class.
            try? FileManager.default.removeItem(at:  CoreDataStore.tempUrl)
            
            let coredata = CoreDataService(container: CoreDataStore.shared.testPersistentContainer)
            let metadata = """
 {
    "IsForwarded" : 0,
    "IsEncrypted" : 1,
    "ExpirationTime" : 0,
    "ReplyTo" : {
        "Address" : "contact@protonmail.ch",
        "Name" : "ProtonMail"
    },
    "Subject" : "Important phishing warning for all ProtonMail users",
    "BCCList" : [
    ],
    "Size" : 2217,
    "ToList" : [
    {
    "Address" : "feng88@protonmail.com",
    "Name" : "",
    "Group" : ""
    }
    ],
    "Order" : 200441873160,
    "IsRepliedAll" : 0,
    "ExternalID" : "MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch",
    "AddressID" : "hbBwBsOdTi5cDhhZcF28yrJ50AZQ8jhXF4d0P7OaUcCS5iv2N8hN_FjvAyPMt8EiP5ch_E_81gHZAjK4D3gfzw==",
    "Location" : 0,
    "LabelIDs" : [
    "0",
    "5",
    "10"
    ],
    "Time" : 1525279399,
    "NumAttachments" : 0,
    "SenderAddress" : "contact@protonmail.ch",
    "MIMEType" : "texthtml",
    "Starred" : 1,
    "Unread" : 0,
    "ID" : "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==",
    "ConversationID" : "3Spjf96LXv8EDUylCxJkKsL7x9IgBac_0z416buSBBMwAkbh_dHh2Ng7O6ss70yhlaLBht0hiJqvqbxoBKtb9Q==",
    "Flags" : 13,
    "SenderName" : "ProtonMail",
    "SpamScore" : 0,
    "Type" : 0,
    "CCList" : [
    ],
    "Sender" : {
        "Address" : "contact@protonmail.ch",
        "Name" : "ProtonMail"
    },
    "IsReplied" : 0
}
"""
            guard let metaMsg = metadata.parseObjectAny() else {
                return
            }
            
            let managedObj = try? GRTJSONSerialization.object(withEntityName: "Message",
                                                              fromJSONDictionary: metaMsg, in: coredata.mainManagedObjectContext)
            XCTAssertNotNil(managedObj)
            
            guard let message1 = managedObj as? Message else {
                XCTAssertNotNil(nil)
                return
            }
            XCTAssertEqual(message1.messageID, "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==")
            XCTAssertEqual(message1.body, "")
            XCTAssertEqual(message1.spamScore, 0)
            XCTAssertEqual(message1.mimeType, "texthtml")
            let details = """
 {
    "IsForwarded" : 0,
    "IsEncrypted" : 1,
    "ExpirationTime" : 0,
    "ReplyTo" : {
        "Address" : "contact@protonmail.ch",
        "Name" : "ProtonMail"
    },
    "Subject" : "Important phishing warning for all ProtonMail users",
    "BCCList" : [
    ],
    "Size" : 2217,
    "ParsedHeaders" : {
        "Subject" : "Important phishing warning for all ProtonMail users",
        "X-Pm-Content-Encryption" : "end-to-end",
        "To" : "feng88@protonmail.com",
        "X-Auto-Response-Suppress" : "OOF",
        "Precedence" : "bulk",
        "X-Original-To" : "feng88@protonmail.com",
        "Mime-Version" : "1.0",
        "Return-Path" : "<contact@protonmail.ch>",
        "Content-Type" : "texthtml",
        "Delivered-To" : "feng88@protonmail.com",
        "From" : "ProtonMail <contact@protonmail.ch>",
        "Received" : "from mail.protonmail.ch by mail.protonmail.ch; Wed, 02 May 2018 12:43:19 -0400",
        "Message-Id" : "<MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch>",
        "Date" : "Wed, 02 May 2018 12:43:19 -0400",
        "X-Pm-Origin" : "internal"
    },
    "ToList" : [
    {
    "Address" : "feng88@protonmail.com",
    "Name" : "",
    "Group" : ""
    }
    ],
    "Order" : 200441873160,
    "IsRepliedAll" : 0,
    "ExternalID" : "MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch",
    "AddressID" : "hbBwBsOdTi5cDhhZcF28yrJ50AZQ8jhXF4d0P7OaUcCS5iv2N8hN_FjvAyPMt8EiP5ch_E_81gHZAjK4D3gfzw==",
    "Location" : 0,
    "LabelIDs" : [
    "0",
    "5",
    "10"
    ],
    "Time" : 1525279399,
    "ReplyTos" : [
    {
    "Address" : "contact@protonmail.ch",
    "Name" : "ProtonMail"
    }
    ],
    "NumAttachments" : 0,
    "SenderAddress" : "contact@protonmail.ch",
    "MIMEType" : "texthtml11111",
    "Starred" : 1,
    "Unread" : 0,
    "ID" : "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==",
    "ConversationID" : "3Spjf96LXv8EDUylCxJkKsL7x9IgBac_0z416buSBBMwAkbh_dHh2Ng7O6ss70yhlaLBht0hiJqvqbxoBKtb9Q==",
    "Body" : "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----",
    "Flags" : 13,
    "Header" : "Date: Wed, 02 May 2018 12:43:19 this is a header",
    "SenderName" : "ProtonMail",
    "SpamScore" : 0,
    "Attachments" : [
    ],
    "Type" : 0,
    "CCList" : [
    ],
    "Sender" : {
        "Address" : "contact@protonmail.ch",
        "Name" : "ProtonMail"
    },
    "IsReplied" : 0
}
"""
            let messageID = "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q=="
            guard let out = details.parseObjectAny() else {
                return
            }
            
            let messagedetails = try? GRTJSONSerialization.object(withEntityName: "Message",
                                                                  fromJSONDictionary: out,
                                                                  in: coredata.testbackgroundManagedObjectContext)
            XCTAssertNotNil(messagedetails)
            
            try! coredata.testbackgroundManagedObjectContext.save()
            //try! coredata.testbackgroundManagedObjectContext.saveUpstreamIfNeeded()
            
            guard let message2 = messagedetails as? Message else {
                XCTAssertNotNil(nil)
                return
            }
            XCTAssertEqual(message2.messageID, messageID)
            XCTAssertEqual(message2.body, "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----")
            XCTAssertEqual(message2.spamScore, 0)
            XCTAssertEqual(message2.mimeType, "texthtml11111")

            guard let beforeMerge1 = Message.messageForMessageID(messageID,
                                                                 inManagedObjectContext: coredata.testbackgroundManagedObjectContext) else {
                XCTAssertNotNil(nil)
                return
            }
            XCTAssertEqual(beforeMerge1.messageID, messageID)
            XCTAssertEqual(beforeMerge1.body, "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----")
            XCTAssertEqual(beforeMerge1.spamScore, 0)
            //        XCTAssertEqual(beforeMerge1.mimeType, "texthtml")
            XCTAssertEqual(beforeMerge1.mimeType, "texthtml11111")
            

            ///
            guard let beforeMerge = Message.messageForMessageID(messageID,
                                                                inManagedObjectContext: coredata.mainManagedObjectContext) else {
                XCTAssertNotNil(nil)
                return
            }
            XCTAssertEqual(beforeMerge.messageID, messageID)
            //        XCTAssertEqual(beforeMerge.body, "")
            XCTAssertEqual(beforeMerge.body, "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----", "stop at index: \(i)")
            XCTAssertEqual(beforeMerge.spamScore, 0)
            //        XCTAssertEqual(beforeMerge.mimeType, "texthtml")
            XCTAssertEqual(beforeMerge.mimeType, "texthtml11111")
            
            
            // Put teardown code here. This method is called after the invocation of each test method in the class.
            try? FileManager.default.removeItem(at:  CoreDataStore.tempUrl)
            
        }
    }

    
    func testChildBackgroudContext() {
        for i in 1 ... 50 {
            // Put setup code here. This method is called before the invocation of each test method in the class.
            try? FileManager.default.removeItem(at:  CoreDataStore.tempUrl)
            let coredata = CoreDataService(container: CoreDataStore.shared.testPersistentContainer)
            let metadata = """
 {
    "IsForwarded" : 0,
    "IsEncrypted" : 1,
    "ExpirationTime" : 0,
    "ReplyTo" : {
        "Address" : "contact@protonmail.ch",
        "Name" : "ProtonMail"
    },
    "Subject" : "Important phishing warning for all ProtonMail users",
    "BCCList" : [
    ],
    "Size" : 2217,
    "ToList" : [
    {
    "Address" : "feng88@protonmail.com",
    "Name" : "",
    "Group" : ""
    }
    ],
    "Order" : 200441873160,
    "IsRepliedAll" : 0,
    "ExternalID" : "MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch",
    "AddressID" : "hbBwBsOdTi5cDhhZcF28yrJ50AZQ8jhXF4d0P7OaUcCS5iv2N8hN_FjvAyPMt8EiP5ch_E_81gHZAjK4D3gfzw==",
    "Location" : 0,
    "LabelIDs" : [
    "0",
    "5",
    "10"
    ],
    "Time" : 1525279399,
    "NumAttachments" : 0,
    "SenderAddress" : "contact@protonmail.ch",
    "MIMEType" : "texthtml",
    "Starred" : 1,
    "Unread" : 0,
    "ID" : "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==",
    "ConversationID" : "3Spjf96LXv8EDUylCxJkKsL7x9IgBac_0z416buSBBMwAkbh_dHh2Ng7O6ss70yhlaLBht0hiJqvqbxoBKtb9Q==",
    "Flags" : 13,
    "SenderName" : "ProtonMail",
    "SpamScore" : 0,
    "Type" : 0,
    "CCList" : [
    ],
    "Sender" : {
        "Address" : "contact@protonmail.ch",
        "Name" : "ProtonMail"
    },
    "IsReplied" : 0
}
"""
            guard let metaMsg = metadata.parseObjectAny() else {
                return
            }
            
            let managedObj = try? GRTJSONSerialization.object(withEntityName: "Message",
                                                              fromJSONDictionary: metaMsg,
                                                              in: coredata.mainManagedObjectContext)
            XCTAssertNotNil(managedObj)
            
            guard let message1 = managedObj as? Message else {
                XCTAssertNotNil(nil)
                return
            }
            XCTAssertEqual(message1.messageID, "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==")
            XCTAssertEqual(message1.body, "")
            XCTAssertEqual(message1.spamScore, 0)
            XCTAssertEqual(message1.mimeType, "texthtml")
            let details = """
 {
    "IsForwarded" : 0,
    "IsEncrypted" : 1,
    "ExpirationTime" : 0,
    "ReplyTo" : {
        "Address" : "contact@protonmail.ch",
        "Name" : "ProtonMail"
    },
    "Subject" : "Important phishing warning for all ProtonMail users",
    "BCCList" : [
    ],
    "Size" : 2217,
    "ParsedHeaders" : {
        "Subject" : "Important phishing warning for all ProtonMail users",
        "X-Pm-Content-Encryption" : "end-to-end",
        "To" : "feng88@protonmail.com",
        "X-Auto-Response-Suppress" : "OOF",
        "Precedence" : "bulk",
        "X-Original-To" : "feng88@protonmail.com",
        "Mime-Version" : "1.0",
        "Return-Path" : "<contact@protonmail.ch>",
        "Content-Type" : "texthtml",
        "Delivered-To" : "feng88@protonmail.com",
        "From" : "ProtonMail <contact@protonmail.ch>",
        "Received" : "from mail.protonmail.ch by mail.protonmail.ch; Wed, 02 May 2018 12:43:19 -0400",
        "Message-Id" : "<MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch>",
        "Date" : "Wed, 02 May 2018 12:43:19 -0400",
        "X-Pm-Origin" : "internal"
    },
    "ToList" : [
    {
    "Address" : "feng88@protonmail.com",
    "Name" : "",
    "Group" : ""
    }
    ],
    "Order" : 200441873160,
    "IsRepliedAll" : 0,
    "ExternalID" : "MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch",
    "AddressID" : "hbBwBsOdTi5cDhhZcF28yrJ50AZQ8jhXF4d0P7OaUcCS5iv2N8hN_FjvAyPMt8EiP5ch_E_81gHZAjK4D3gfzw==",
    "Location" : 0,
    "LabelIDs" : [
    "0",
    "5",
    "10"
    ],
    "Time" : 1525279399,
    "ReplyTos" : [
    {
    "Address" : "contact@protonmail.ch",
    "Name" : "ProtonMail"
    }
    ],
    "NumAttachments" : 0,
    "SenderAddress" : "contact@protonmail.ch",
    "MIMEType" : "texthtml11111",
    "Starred" : 1,
    "Unread" : 0,
    "ID" : "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==",
    "ConversationID" : "3Spjf96LXv8EDUylCxJkKsL7x9IgBac_0z416buSBBMwAkbh_dHh2Ng7O6ss70yhlaLBht0hiJqvqbxoBKtb9Q==",
    "Body" : "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----",
    "Flags" : 13,
    "Header" : "Date: Wed, 02 May 2018 12:43:19 this is a header",
    "SenderName" : "ProtonMail",
    "SpamScore" : 0,
    "Attachments" : [
    ],
    "Type" : 0,
    "CCList" : [
    ],
    "Sender" : {
        "Address" : "contact@protonmail.ch",
        "Name" : "ProtonMail"
    },
    "IsReplied" : 0
}
"""
            let messageID = "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q=="
            guard let out = details.parseObjectAny() else {
                return
            }
            
//            let messagedetails = try? GRTJSONSerialization.object(withEntityName: "Message",
//                                                                  fromJSONDictionary: out,
//                                                                  in: coredata.testChildContext)
//            XCTAssertNotNil(messagedetails)
//            
//            try! coredata.testChildContext.save()
//            //        try! coredata.testChildContext.saveUpstreamIfNeeded()
//            
//            guard let message2 = messagedetails as? Message else {
//                XCTAssertNotNil(nil)
//                return
//            }
//            XCTAssertEqual(message2.messageID, messageID)
//            XCTAssertEqual(message2.body, "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----")
//            XCTAssertEqual(message2.spamScore, 0)
//            XCTAssertEqual(message2.mimeType, "texthtml11111")
//            
//            guard let beforeMerge = Message.messageForMessageID(messageID, inManagedObjectContext: coredata.mainManagedObjectContext) else {
//                XCTAssertNotNil(nil)
//                return
//            }
//            XCTAssertEqual(beforeMerge.messageID, messageID)
//            //        XCTAssertEqual(beforeMerge.body, "")
//            XCTAssertEqual(beforeMerge.body, "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----")
//            XCTAssertEqual(beforeMerge.spamScore, 0)
//            //        XCTAssertEqual(beforeMerge.mimeType, "texthtml")
//            XCTAssertEqual(beforeMerge.mimeType, "texthtml11111")
//            
//            
//            ///
//            guard let beforeMerge1 = Message.messageForMessageID(messageID, inManagedObjectContext: coredata.testChildContext) else {
//                XCTAssertNotNil(nil)
//                return
//            }
//            XCTAssertEqual(beforeMerge1.messageID, messageID)
//            XCTAssertEqual(beforeMerge1.body, "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----", "stop at index: \(i)")
//            XCTAssertEqual(beforeMerge1.spamScore, 0)
//            //        XCTAssertEqual(beforeMerge1.mimeType, "texthtml")
//            XCTAssertEqual(beforeMerge1.mimeType, "texthtml11111")
//            
//            
//            // Put teardown code here. This method is called after the invocation of each test method in the class.
//            try? FileManager.default.removeItem(at:  CoreDataStore.tempUrl)
            
        }
    }

}
