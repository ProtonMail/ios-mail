//
//  ConversationsAPITests.swift
//  Proton Mail
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

import XCTest
@testable import ProtonMail

class ConversationsAPITests: XCTestCase {
    typealias Parameters = ConversationsRequest.Parameters
    typealias Pair = ConversationsRequest.Parameters.Pair
    
    func testParametersEmpty() {
        let params = ConversationsRequest.Parameters()
        XCTAssertNil(params.additionalPathElements)
        
        let request = ConversationsRequest(params)
        let path = ConversationsAPI.path
        XCTAssertEqual(path, request.path)
    }
    
    func testParameters() {
        let params = ConversationsRequest.Parameters(location: 1, labelID: "labelID", IDs: ["id1", "id2", "id3"])
        let pairs: Array<Pair> = [
            .init(key: "location", value: "1"),
            .init(key: "labelID", value: "labelID"),
            .init(key: "IDs[]", value: "id1"),
            .init(key: "IDs[]", value: "id2"),
            .init(key: "IDs[]", value: "id3") ]
        
        XCTAssertEqual(params.additionalPathElements, pairs)
        
        
        let request = ConversationsRequest(params)
        let additionalString = ["Location=1", "LabelID=labelID", "IDs[]=id1", "IDs[]=id2", "IDs[]=id3"].joined(separator: "&")
        let path = ConversationsAPI.path + "?" + additionalString
        XCTAssertEqual(path, request.path)
    }
    
    func testConversationDetailsRequestWithoutMsgID() {
        let sut = ConversationDetailsRequest(conversationID: "ConversationID1", messageID: nil)
        let path = sut.path
        
        let expected = "/mail/v4/conversations/ConversationID1"
        
        XCTAssertEqual(path, expected)
    }
    
    func testConversationDetailsRequestWithMsgID() {
        let sut = ConversationDetailsRequest(conversationID: "ConversationID1", messageID: "MessageID2")
        let path = sut.path
        
        let expected = "/mail/v4/conversations/ConversationID1?MessageID=MessageID2"
        
        XCTAssertEqual(path, expected)
    }
    
    func testConversationsResponseParsing() {
        let data = testConversationsData.data(using: .utf8)!
        let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let sut = ConversationsResponse()
        XCTAssertTrue(sut.ParseResponse(responseDictionary))
        XCTAssertFalse(sut.conversationsDict.isEmpty)
    }
    
    func testConversationDetailResponseParsing() {
        let data = testConversationDetailData.data(using: .utf8)!
        let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let sut = ConversationDetailsResponse()
        XCTAssertTrue(sut.ParseResponse(responseDictionary))
        XCTAssertNotNil(sut.messages)
//        XCTAssertNotNil(sut.responseDict)
        XCTAssertNotNil(sut.conversation)
    }
    
    // MARK: - Conversation Count
    func testConversationCountRequestWithoutAddrID() {
        let sut = ConversationCountRequest(addressID: nil)
        let path = sut.path
        
        let expected = "/mail/v4/conversations/count"
        
        XCTAssertEqual(path, expected)
    }
    
    func testConversationCountRequestWithAddrID() {
        let sut = ConversationCountRequest(addressID: "AddressID1")
        let path = sut.path
        
        let expected = "/mail/v4/conversations/count?AddressID=AddressID1"
        
        XCTAssertEqual(path, expected)
    }
    
    // MARK: - Conversation Read
    func testConversationReadRequest() throws {
        let ids = ["id1", "id2", "id3", "id4"]
        let sut = ConversationReadRequest(conversationIDs: ids)
        
        let dictionary = try XCTUnwrap(sut.parameters)
        let conversationIDs = dictionary["IDs"]
        
        XCTAssertNotNil(conversationIDs)
        XCTAssertEqual(conversationIDs! as! [String], ids)
        
        let expectedPath = "/mail/v4/conversations/read"
        XCTAssertEqual(expectedPath, sut.path)
    }
    
    func testConversationReadResponse() {
        let data = testConversationReadData.data(using: .utf8)!
        let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let sut = ConversationReadResponse()
        XCTAssertTrue(sut.ParseResponse(responseDictionary))
        XCTAssertNotNil(sut.results)
    }
    
    //MARK: - Conversation Unread
    func testConversationUnreadRequest() throws {
        let ids = ["id1", "id2", "id3", "id4"]
        let label = "labelID1"
        let sut = ConversationUnreadRequest(conversationIDs: ids, labelID: label)
        
        let dictionary = try XCTUnwrap(sut.parameters)
        let conversationIDs = dictionary["IDs"]
        
        XCTAssertNotNil(conversationIDs)
        XCTAssertEqual(conversationIDs! as! [String], ids)
        
        let labelID = dictionary["LabelID"]
        XCTAssertNotNil(labelID)
        XCTAssertEqual(labelID! as! String, label)
        
        let expectedPath = "/mail/v4/conversations/unread"
        XCTAssertEqual(expectedPath, sut.path)
    }
    
    func testConversationUnreadResponse() {
        let data = testConversationReadData.data(using: .utf8)!
        let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let sut = ConversationUnreadResponse()
        XCTAssertTrue(sut.ParseResponse(responseDictionary))
        XCTAssertNotNil(sut.results)
    }
    
    //MARK: - Conversation Delete
    func testConversationDeleteRequest() throws {
        let ids = ["id1", "id2", "id3", "id4"]
        let label = "labelID1"
        let sut = ConversationDeleteRequest(conversationIDs: ids, labelID: label)
        
        let dictionary = try XCTUnwrap(sut.parameters)
        let conversationIDs = dictionary["IDs"]
        
        XCTAssertNotNil(conversationIDs)
        XCTAssertEqual(conversationIDs! as! [String], ids)
        
        let labelID = dictionary["LabelID"]
        XCTAssertNotNil(labelID)
        XCTAssertEqual(labelID! as! String, label)
        
        let expectedPath = "/mail/v4/conversations/delete"
        XCTAssertEqual(expectedPath, sut.path)
    }
    
    func testConversationDeleteResponse() {
        let data = testConversationDeleteData.data(using: .utf8)!
        let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let sut = ConversationDeleteResponse()
        XCTAssertTrue(sut.ParseResponse(responseDictionary))
        XCTAssertNotNil(sut.results)
        XCTAssertNotNil(sut.responseDict)
    }
    
    //MARK: - Conversation Label
    func testConversationLabelRequest() throws {
        let ids = ["id1", "id2", "id3", "id4"]
        let label = "labelID1"
        let sut = ConversationLabelRequest(conversationIDs: ids, labelID: label)
        
        let dictionary = try XCTUnwrap(sut.parameters)
        let conversationIDs = dictionary["IDs"]
        
        XCTAssertNotNil(conversationIDs)
        XCTAssertEqual(conversationIDs! as! [String], ids)
        
        let labelID = dictionary["LabelID"]
        XCTAssertNotNil(labelID)
        XCTAssertEqual(labelID! as! String, label)
        
        let expectedPath = "/mail/v4/conversations/label"
        XCTAssertEqual(expectedPath, sut.path)
    }
    
    func testConversationLabelResponse() {
        let data = testConversationLabelData.data(using: .utf8)!
        let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let sut = ConversationLabelResponse()
        XCTAssertTrue(sut.ParseResponse(responseDictionary))
        XCTAssertNotNil(sut.results)
        XCTAssertNotNil(sut.responseDict)
    }
    
    //MARK: - Conversation Unlabel
    func testConversationUnlabelRequest() throws {
        let ids = ["id1", "id2", "id3", "id4"]
        let label = "labelID1"
        let sut = ConversationUnlabelRequest(conversationIDs: ids, labelID: label)

        let dictionary = try XCTUnwrap(sut.parameters)
        let conversationIDs = dictionary["IDs"]
        
        XCTAssertNotNil(conversationIDs)
        XCTAssertEqual(conversationIDs! as! [String], ids)
        
        let labelID = dictionary["LabelID"]
        XCTAssertNotNil(labelID)
        XCTAssertEqual(labelID! as! String, label)
        
        let expectedPath = "/mail/v4/conversations/unlabel"
        XCTAssertEqual(expectedPath, sut.path)
    }
    
    func testConversationUnlabelResponse() {
        let data = testConversationUnlabelData.data(using: .utf8)!
        let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        
        let sut = ConversationUnlabelResponse()
        XCTAssertTrue(sut.ParseResponse(responseDictionary))
        XCTAssertNotNil(sut.results)
        XCTAssertNotNil(sut.responseDict)
    }
}
