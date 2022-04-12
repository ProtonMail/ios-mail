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
import CoreData
import Groot
@testable import ProtonMail
import ProtonCore_TestingToolkit
import ProtonCore_DataModel
import ProtonCore_Networking

class MailboxViewModelTests: XCTestCase {

    var sut: MailboxViewModel!
    var pushNotificationServiceMock: PushNotificationServiceProtocol!
    var coreDataContextProviderMock: CoreDataContextProviderProtocol!
    var lastUpdatedStoreMock: LastUpdatedStoreProtocol!
    var humanCheckStatusProviderMock: HumanCheckStatusProviderProtocol!
    var userManagerMock: UserManager!
    var apiServiceMock: APIServiceMock!
    var conversationStateProviderMock: ConversationStateProviderProtocol!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sharedServices.add(CoreDataService.self,
                           for: CoreDataService(container: CoreDataStore.shared.memoryPersistentContainer))
        apiServiceMock = APIServiceMock()
        let fakeAuth = AuthCredential(sessionID: "",
                                      accessToken: "",
                                      refreshToken: "",
                                      expiration: Date(),
                                      userName: "",
                                      userID: "1",
                                      privateKey: nil,
                                      passwordKeySalt: nil)
        let stubUserInfo = UserInfo(maxSpace: nil,
                                    usedSpace: nil,
                                    language: nil,
                                    maxUpload: nil,
                                    role: nil,
                                    delinquent: nil,
                                    keys: nil,
                                    userId: "1",
                                    linkConfirmation: nil,
                                    credit: nil,
                                    currency: nil,
                                    subscribed: nil)
        userManagerMock = UserManager(api: apiServiceMock,
                                      userinfo: stubUserInfo,
                                      auth: fakeAuth,
                                      parent: nil)
        userManagerMock.conversationStateService.userInfoHasChanged(viewMode: .singleMessage)
        pushNotificationServiceMock = MockPushNotificationService()
        coreDataContextProviderMock = MockCoreDataContextProvider()
        lastUpdatedStoreMock = MockLastUpdatedStore()
        humanCheckStatusProviderMock = MockHumanCheckStatusProvider()
        conversationStateProviderMock = MockConversationStateProvider()
        try loadTestMessage() // one message
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        pushNotificationServiceMock = nil
        coreDataContextProviderMock = nil
        lastUpdatedStoreMock = nil
        humanCheckStatusProviderMock = nil
        userManagerMock = nil
        apiServiceMock = nil
    }
    
    func testMessageItemOfIndexPath() {
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        sut.setupFetchController(nil)
        XCTAssertNotNil(sut.item(index:IndexPath(row: 0, section: 0)))
        XCTAssertNil(sut.item(index:IndexPath(row: 1, section: 0)))
        XCTAssertNil(sut.item(index:IndexPath(row: 0, section: 1)))
    }
    
    func testCheckIsIndexPathMatch_withMessage() {
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        sut.setupFetchController(nil)
        let targetMsgID = "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q=="
        XCTAssertTrue(sut.checkIsIndexPathMatch(with: targetMsgID,
                                                indexPath: IndexPath(row: 0, section: 0)))
        XCTAssertFalse(sut.checkIsIndexPathMatch(with: "1213",
                                                indexPath: IndexPath(row: 0, section: 0)))
        XCTAssertFalse(sut.checkIsIndexPathMatch(with: targetMsgID,
                                                indexPath: IndexPath(row: 1, section: 0)))
        XCTAssertFalse(sut.checkIsIndexPathMatch(with: targetMsgID,
                                                indexPath: IndexPath(row: 0, section: 1)))
        
    }
    
    func testSelectMessage() {
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        sut.setupFetchController(nil)
        let targetMsgID = "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q=="
        XCTAssertTrue(sut.select(at: IndexPath(row: 0, section: 0)))
        XCTAssertTrue(sut.selectedIDs.contains(targetMsgID))
        
        XCTAssertFalse(sut.select(at: IndexPath(row: 1, section: 0)))
        XCTAssertFalse(sut.select(at: IndexPath(row: 0, section: 1)))
    }
    
    func testSelectByID() {
        XCTAssertTrue(sut.selectedIDs.isEmpty)
        sut.select(id: "1")
        XCTAssertTrue(sut.selectedIDs.contains("1"))
    }
    
    func testRemoveSelectByID() {
        sut.select(id: "1")
        sut.select(id: "2")
        XCTAssertTrue(sut.selectedIDs.contains("1"))
        XCTAssertTrue(sut.selectedIDs.contains("2"))
        XCTAssertEqual(sut.selectedIDs.count, 2)
        sut.removeSelected(id: "1")
        XCTAssertFalse(sut.selectedIDs.contains("1"))
        XCTAssertTrue(sut.selectedIDs.contains("2"))
        XCTAssertEqual(sut.selectedIDs.count, 1)
    }
    
    func testRemoveAllSelectID() {
        XCTAssertTrue(sut.selectedIDs.isEmpty)
        sut.select(id: "1")
        sut.select(id: "2")
        XCTAssertEqual(sut.selectedIDs.count, 2)
        sut.removeAllSelectedIDs()
        XCTAssertTrue(sut.selectedIDs.isEmpty)
    }
    
    func testSelectionContains() {
        XCTAssertTrue(sut.selectedIDs.isEmpty)
        sut.select(id: "1")
        XCTAssertTrue(sut.selectionContains(id: "1"))
        XCTAssertFalse(sut.selectionContains(id: "2"))
        XCTAssertFalse(sut.selectionContains(id: "3"))
    }
    
    func testLocalizedNavigationTitle() {
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertEqual(sut.localizedNavigationTitle, Message.Location.inbox.localizedTitle)
        
        createSut(labelID: Message.Location.archive.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertEqual(sut.localizedNavigationTitle, Message.Location.archive.localizedTitle)
        
        createSut(labelID: "customID",
                  labelType: .folder,
                  isCustom: true,
                  labelName: "custom")
        XCTAssertEqual(sut.localizedNavigationTitle, "custom")
        
        createSut(labelID: "customID2",
                  labelType: .label,
                  isCustom: true,
                  labelName: "custom2")
        XCTAssertEqual(sut.localizedNavigationTitle, "custom2")
        
        createSut(labelID: "customID2",
                  labelType: .label,
                  isCustom: true,
                  labelName: nil)
        XCTAssertEqual(sut.localizedNavigationTitle, "")
    }
    
    func testGetCurrentViewMode() {
        XCTAssertEqual(sut.currentViewMode, conversationStateProviderMock.viewMode)
        conversationStateProviderMock.viewMode = .conversation
        XCTAssertEqual(sut.currentViewMode, .conversation)
        conversationStateProviderMock.viewMode = .singleMessage
        XCTAssertEqual(sut.currentViewMode, .singleMessage)
    }
    
    func testGetLocationViewMode_inDraftAndSent_getSingleMessageOnly() {
        createSut(labelID: Message.Location.draft.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        conversationStateProviderMock.viewMode = .singleMessage
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        conversationStateProviderMock.viewMode = .conversation
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        
        createSut(labelID: Message.Location.sent.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        conversationStateProviderMock.viewMode = .singleMessage
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        conversationStateProviderMock.viewMode = .conversation
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
    }
    
    func testGetLocationViewMode_notInDraftOrSent_getViewModeFromConversationStateProvider() {
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        conversationStateProviderMock.viewMode = .singleMessage
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        conversationStateProviderMock.viewMode = .conversation
        XCTAssertEqual(sut.locationViewMode, .conversation)
        
        createSut(labelID: "custom",
                  labelType: .folder,
                  isCustom: true,
                  labelName: "1")
        conversationStateProviderMock.viewMode = .singleMessage
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        conversationStateProviderMock.viewMode = .conversation
        XCTAssertEqual(sut.locationViewMode, .conversation)
        
        createSut(labelID: "custom1",
                  labelType: .label,
                  isCustom: true,
                  labelName: "2")
        conversationStateProviderMock.viewMode = .singleMessage
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        conversationStateProviderMock.viewMode = .conversation
        XCTAssertEqual(sut.locationViewMode, .conversation)
    }
    
    func testGetIsRequiredHumanCheck() {
        humanCheckStatusProviderMock.isRequiredHumanCheck = false
        XCTAssertFalse(sut.isRequiredHumanCheck)
        
        humanCheckStatusProviderMock.isRequiredHumanCheck = true
        XCTAssertTrue(sut.isRequiredHumanCheck)
    }
    
    func testSetIsRequiredHumanCheck() {
        humanCheckStatusProviderMock.isRequiredHumanCheck = false
        sut.isRequiredHumanCheck = true
        XCTAssertTrue(humanCheckStatusProviderMock.isRequiredHumanCheck)
        
        sut.isRequiredHumanCheck = false
        XCTAssertFalse(humanCheckStatusProviderMock.isRequiredHumanCheck)
    }
    
    func testGetIsCurrentUserSelectedUnreadFilterInInbox() {
        userManagerMock.isUserSelectedUnreadFilterInInbox = false
        XCTAssertFalse(sut.isCurrentUserSelectedUnreadFilterInInbox)
        
        userManagerMock.isUserSelectedUnreadFilterInInbox = true
        XCTAssertTrue(sut.isCurrentUserSelectedUnreadFilterInInbox)
    }
    
    func testSetIsCurrentUserSelectedUnreadFilterInInbox() {
        sut.isCurrentUserSelectedUnreadFilterInInbox = false
        XCTAssertFalse(userManagerMock.isUserSelectedUnreadFilterInInbox)
        
        sut.isCurrentUserSelectedUnreadFilterInInbox = true
        XCTAssertTrue(userManagerMock.isUserSelectedUnreadFilterInInbox)
    }
    
    func testConvertSwipeActionTypeToMessageSwipeAction() {
        XCTAssertEqual(sut
                        .convertSwipeActionTypeToMessageSwipeAction(.none,
                                                                    isStarred: false,
                                                                    isUnread: false), .none)
        XCTAssertEqual(sut
                        .convertSwipeActionTypeToMessageSwipeAction(.trash,
                                                                    isStarred: false,
                                                                    isUnread: false), .trash)
        XCTAssertEqual(sut
                        .convertSwipeActionTypeToMessageSwipeAction(.spam,
                                                                    isStarred: false,
                                                                    isUnread: false), .spam)
        XCTAssertEqual(sut
                        .convertSwipeActionTypeToMessageSwipeAction(.starAndUnstar,
                                                                    isStarred: true,
                                                                    isUnread: false), .unstar)
        XCTAssertEqual(sut
                        .convertSwipeActionTypeToMessageSwipeAction(.starAndUnstar,
                                                                    isStarred: false,
                                                                    isUnread: false), .star)
        XCTAssertEqual(sut
                        .convertSwipeActionTypeToMessageSwipeAction(.archive,
                                                                    isStarred: false,
                                                                    isUnread: false), .archive)
        XCTAssertEqual(sut
                        .convertSwipeActionTypeToMessageSwipeAction(.readAndUnread,
                                                                    isStarred: false,
                                                                    isUnread: true), .read)
        XCTAssertEqual(sut
                        .convertSwipeActionTypeToMessageSwipeAction(.readAndUnread,
                                                                    isStarred: false,
                                                                    isUnread: false), .unread)
        XCTAssertEqual(sut
                        .convertSwipeActionTypeToMessageSwipeAction(.labelAs,
                                                                    isStarred: false,
                                                                    isUnread: false), .labelAs)
        XCTAssertEqual(sut
                        .convertSwipeActionTypeToMessageSwipeAction(.moveTo,
                                                                    isStarred: false,
                                                                    isUnread: false), .moveTo)
    }
    
    func testCalculateSpaceUsedPercentage() {
        XCTAssertEqual(sut.calculateSpaceUsedPercentage(usedSpace: 50, maxSpace: 100), 0.5, accuracy: 0.001)
        
        XCTAssertEqual(sut.calculateSpaceUsedPercentage(usedSpace: 33, maxSpace: 100), 0.33, accuracy: 0.001)
    }
    
    func testCalculateIsUsedSpaceExceedThreshold() {
        XCTAssertTrue(sut.calculateIsUsedSpaceExceedThreshold(usedPercentage: 0.6, threshold: 50))
        
        XCTAssertFalse(sut.calculateIsUsedSpaceExceedThreshold(usedPercentage: -0.6, threshold: 50))
    }
    
    func testCalculateFormattedMaxSpace() {
        XCTAssertEqual(sut.calculateFormattedMaxSpace(maxSpace: 500000), "488 KB")
        
        XCTAssertEqual(sut.calculateFormattedMaxSpace(maxSpace: -10), "-10 bytes")
    }
    
    func testCalculateSpaceMessage() {
        let msg = sut.calculateSpaceMessage(usedSpace: 600000,
                                            maxSpace: 500000,
                                            formattedMaxSpace: "488 KB",
                                            usedSpacePercentage: 1.2)
        XCTAssertEqual(msg, String(format: LocalString._space_all_used_warning, "488 KB"))
        
        let msg1 = sut.calculateSpaceMessage(usedSpace: 400000,
                                            maxSpace: 500000,
                                            formattedMaxSpace: "488 KB",
                                             usedSpacePercentage: 0.8)
        XCTAssertEqual(msg1,String(format: LocalString._space_partial_used_warning, 80, "488 KB"))
    }
    
    private func createSut(labelID: String,
                           labelType: PMLabelType,
                           isCustom: Bool,
                           labelName: String?) {
        let label = LabelInfo(labelID: labelID, name: labelName ?? "")
        sut = MailboxViewModel(labelID: labelID,
                               label: isCustom ? label : nil,
                               labelType: labelType,
                               userManager: userManagerMock,
                               pushService: pushNotificationServiceMock,
                               coreDataContextProvider: coreDataContextProviderMock,
                               lastUpdatedStore: lastUpdatedStoreMock,
                               humanCheckStatusProvider: humanCheckStatusProviderMock,
                               conversationStateProvider: conversationStateProviderMock,
                               totalUserCountClosure: {
            return 1
        },
                               getOtherUsersClosure: { _ in
            return []
        })
    }
    
    private func loadTestMessage() throws {
        let parsedObject = testMessageMetaData.parseObjectAny()!
        let testMessage = try GRTJSONSerialization
            .object(withEntityName: "Message",
                    fromJSONDictionary: parsedObject,
                    in: coreDataContextProviderMock.mainContext) as? Message
        testMessage?.userID = "1"
        testMessage?.messageStatus = 1
        try coreDataContextProviderMock.mainContext.save()
    }
}
