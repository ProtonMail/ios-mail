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
import CoreData
import Groot
@testable import ProtonMail
import ProtonCore_TestingToolkit
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_UIFoundations

class MailboxViewModelTests: XCTestCase {

    var sut: MailboxViewModel!
    var pushNotificationServiceMock: PushNotificationServiceProtocol!
    var coreDataContextProviderMock: CoreDataContextProviderProtocol!
    var lastUpdatedStoreMock: LastUpdatedStoreProtocol!
    var humanCheckStatusProviderMock: HumanCheckStatusProviderProtocol!
    var userManagerMock: UserManager!
    var apiServiceMock: APIServiceMock!
    var conversationStateProviderMock: ConversationStateProviderProtocol!
    var contactGroupProviderMock: MockContactGroupsProvider!
    var labelProviderMock: MockLabelProvider!
    var contactProviderMock: MockContactProvider!
    var conversationProviderMock: MockConversationProvider!
    var eventsServiceMock: EventsServiceMock!
    var mockFetchLatestEventId: MockFetchLatestEventId!
    var mockPurgeOldMessages: MockPurgeOldMessages!
    var welcomeCarrouselCache: WelcomeCarrouselCacheMock!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sharedServices.add(CoreDataService.self,
                           for: CoreDataService(container: MockCoreDataStore.testPersistentContainer))
        apiServiceMock = APIServiceMock()
        coreDataContextProviderMock = MockCoreDataContextProvider()
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
                                      parent: nil,
                                      contextProvider: coreDataContextProviderMock)
        userManagerMock.conversationStateService.userInfoHasChanged(viewMode: .singleMessage)
        pushNotificationServiceMock = MockPushNotificationService()
        lastUpdatedStoreMock = MockLastUpdatedStore()
        humanCheckStatusProviderMock = MockHumanCheckStatusProvider()
        conversationStateProviderMock = MockConversationStateProvider()
        contactGroupProviderMock = MockContactGroupsProvider()
        labelProviderMock = MockLabelProvider()
        contactProviderMock = MockContactProvider()
        conversationProviderMock = MockConversationProvider()
        eventsServiceMock = EventsServiceMock()
        mockFetchLatestEventId = MockFetchLatestEventId()
        mockPurgeOldMessages = MockPurgeOldMessages()
        welcomeCarrouselCache = WelcomeCarrouselCacheMock()
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
        mockFetchLatestEventId = nil
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
    
    func testIsInDraftFolder() {
        createSut(labelID: Message.Location.draft.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertTrue(sut.isInDraftFolder)
        
        createSut(labelID: Message.Location.trash.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertFalse(sut.isInDraftFolder)
    }
    
    func testIsHavingUser() {
        createSut(labelID: Message.Location.draft.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil,
                  totalUserCount: 3)
        XCTAssertTrue(sut.isHavingUser)
        
        createSut(labelID: Message.Location.draft.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil,
                  totalUserCount: 0)
        XCTAssertFalse(sut.isHavingUser)
    }
    
    func testMessageLocation() {
        createSut(labelID: Message.Location.trash.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertEqual(sut.messageLocation, .trash)
        
        createSut(labelID: "labelID",
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertNil(sut.messageLocation)
    }
    
    func testIsTrashOrSpam() {
        createSut(labelID: Message.Location.trash.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertTrue(sut.isTrashOrSpam)
        
        createSut(labelID: Message.Location.spam.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertTrue(sut.isTrashOrSpam)
        
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertFalse(sut.isTrashOrSpam)
        
        createSut(labelID: "1234",
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertFalse(sut.isTrashOrSpam)
    }
    
    func testGetActionSheetViewModel() {
        conversationStateProviderMock.viewMode = .singleMessage
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertEqual(sut.selectedIDs.count, 0)
        let model = sut.actionSheetViewModel
        XCTAssertEqual(model.title, .localizedStringWithFormat(LocalString._general_message, 0))
        
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        sut.select(id: "id")
        XCTAssertEqual(sut.selectedIDs.count, 1)
        let model2 = sut.actionSheetViewModel
        XCTAssertEqual(model2.title, .localizedStringWithFormat(LocalString._general_conversation, 1))
    }
    
    func testGetEmptyFolderCheckMessage() {
        conversationStateProviderMock.viewMode = .singleMessage
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertEqual(sut.getEmptyFolderCheckMessage(count: 1),
                       String(format: LocalString._clean_message_warning, 1))
        
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertEqual(sut.getEmptyFolderCheckMessage(count: 10),
                       String(format: LocalString._clean_conversation_warning, 10))
    }
    
    func testGetGroupContacts() {
        let testData = ContactGroupVO(ID: "1", name: "name1")
        contactGroupProviderMock.contactGroupsToReturn = [testData]
        createSut(labelID: "1", labelType: .folder, isCustom: false, labelName: nil)

        XCTAssertEqual(sut.groupContacts, [testData])
    }
    
    func testGetCustomFolders() {
        let testData = Label(context: coreDataContextProviderMock.mainContext)
        testData.labelID = "1"
        testData.name = "name1"
        labelProviderMock.customFolderToReturn = [testData]
        createSut(labelID: "1", labelType: .folder, isCustom: false, labelName: nil)

        XCTAssertEqual(sut.customFolders, [LabelEntity(label: testData)])
    }

    func testFetchContacts() {
        let expectation1 = expectation(description: "Closure is called")
        sut.fetchContacts(completion: { _, _ in
            XCTAssertTrue(self.contactProviderMock.isFetchContactsCalled)
            expectation1.fulfill()
        })
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetAllEmails() {
        let testData = Email(context: coreDataContextProviderMock.mainContext)
        testData.emailID = "1"
        testData.email = "test@pm.me"
        contactProviderMock.allEmailsToReturn = [testData]
        createSut(labelID: "1", labelType: .folder, isCustom: false, labelName: nil)

        XCTAssertEqual(sut.allEmails, [testData])
    }

    func testMoveConversation() {
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)

        let expectation1 = expectation(description: "Closure called")
        let ids = Set<String>(["1", "2"])
        sut.move(IDs: ids,
                 from: Message.Location.inbox.labelID,
                 to: Message.Location.trash.labelID) {
            XCTAssertTrue(self.conversationProviderMock.callMove.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.callMove.lastArguments
            XCTAssertTrue(argument?.first.contains("1") ?? false)
            XCTAssertTrue(argument?.first.contains("2") ?? false)

            XCTAssertEqual(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments?.value, self.sut.labelID)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMarkConversationAsRead() {
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)

        let expectation1 = expectation(description: "Closure called")
        let ids = Set<String>(["1", "2"])
        sut.mark(IDs: ids, unread: false) {
            XCTAssertTrue(self.conversationProviderMock.callMarkAsRead.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.callMarkAsRead.lastArguments
            XCTAssertNotNil(argument)
            XCTAssertTrue(argument?.first.contains("1") ?? false)
            XCTAssertTrue(argument?.first.contains("2") ?? false)
            XCTAssertEqual(argument?.a2, "1245")

            XCTAssertEqual(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments?.value, self.sut.labelID)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMarkConversationAsUnread() {
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)

        let expectation1 = expectation(description: "Closure called")
        let ids = Set<String>(["1", "2"])
        sut.mark(IDs: ids, unread: true) {
            XCTAssertTrue(self.conversationProviderMock.callMarkAsUnRead.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.callMarkAsUnRead.lastArguments
            XCTAssertNotNil(argument)
            XCTAssertTrue(argument?.first.contains("1") ?? false)
            XCTAssertTrue(argument?.first.contains("2") ?? false)
            XCTAssertEqual(argument?.a2, "1245")

            XCTAssertEqual(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments?.value, self.sut.labelID)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testLabelConversation_applyLabel() {
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)

        let expectation1 = expectation(description: "Closure called")
        let ids = Set<String>(["1", "2"])
        sut.label(IDs: ids, with: "labelID", apply: true) {
            XCTAssertTrue(self.conversationProviderMock.callLabel.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.callLabel.lastArguments
            XCTAssertNotNil(argument)
            XCTAssertTrue(argument?.first.contains("1") ?? false)
            XCTAssertTrue(argument?.first.contains("2") ?? false)
            XCTAssertEqual(argument?.a2, "labelID")
            XCTAssertFalse(argument?.a3 ?? true)

            XCTAssertEqual(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments?.value, self.sut.labelID)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testLabelConversation_removeLabel() {
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)

        let expectation1 = expectation(description: "Closure called")
        let ids = Set<String>(["1", "2"])
        sut.label(IDs: ids, with: "labelID", apply: false) {
            XCTAssertTrue(self.conversationProviderMock.callUnlabel.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.callUnlabel.lastArguments
            XCTAssertNotNil(argument)
            XCTAssertTrue(argument?.first.contains("1") ?? false)
            XCTAssertTrue(argument?.first.contains("2") ?? false)
            XCTAssertEqual(argument?.a2, "labelID")
            XCTAssertFalse(argument?.a3 ?? true)

            XCTAssertEqual(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments?.value, self.sut.labelID)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchConversationDetailIsCalled() {
        let expectation1 = expectation(description: "Closure called")

        sut.fetchConversationDetail(conversationID: "conversationID1") { _ in
            XCTAssertTrue(self.conversationProviderMock.callFetchConversation.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.callFetchConversation.lastArguments
            XCTAssertNotNil(argument)
            XCTAssertEqual(argument?.first, "conversationID1")
            XCTAssertNil(argument?.a2)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMarkConversationAsUnreadIsCalled() {
        let expectation1 = expectation(description: "Closure called")
        sut.markConversationAsUnread(conversationIDs: ["conversation1"], currentLabelID: "label1") { _ in
            XCTAssertTrue(self.conversationProviderMock.callMarkAsUnRead.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callMarkAsUnRead.lastArguments)
                XCTAssertEqual(argument.first, ["conversation1"])
                XCTAssertEqual(argument.a2, "label1")
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMarkConversationAsReadIsCalled() {
        let expectation1 = expectation(description: "Closure called")
        sut.markConversationAsRead(conversationIDs: ["conversation1"], currentLabelID: "label1") { _ in
            XCTAssertTrue(self.conversationProviderMock.callMarkAsRead.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callMarkAsRead.lastArguments)
                XCTAssertEqual(argument.first, ["conversation1"])
                XCTAssertEqual(argument.a2, "label1")
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testLabelConversationsIsCalled() {
        let expectation1 = expectation(description: "Closure called")
        sut.labelConversations(conversationIDs: ["conversation1"], labelID: "label1") { _ in
            XCTAssertTrue(self.conversationProviderMock.callLabel.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callLabel.lastArguments)
                XCTAssertEqual(argument.first, ["conversation1"])
                XCTAssertEqual(argument.a2, "label1")
                XCTAssertFalse(argument.a3)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUnlabelConversationsIsCalled() {
        let expectation1 = expectation(description: "Closure called")
        sut.unlabelConversations(conversationIDs: ["conversation1"], labelID: "label1") { _ in
            XCTAssertTrue(self.conversationProviderMock.callUnlabel.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callUnlabel.lastArguments)
                XCTAssertEqual(argument.first, ["conversation1"])
                XCTAssertEqual(argument.a2, "label1")
                XCTAssertFalse(argument.a3)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchConversationCount() {
        let expectation1 = expectation(description: "Closure called")
        sut.fetchConversationCount { _ in
            XCTAssertTrue(self.conversationProviderMock.callFetchConversationCounts.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callFetchConversationCounts.lastArguments)
                XCTAssertNil(argument.first)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDeleteConversationPermanently() {
        conversationStateProviderMock.viewMode = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)

        let expectation1 = expectation(description: "Closure called")
        let ids: Set<String> = ["1", "2"]
        sut.delete(IDs: ids) {
            XCTAssertTrue(self.conversationProviderMock.callDelete.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callDelete.lastArguments)
                XCTAssertTrue(argument.first.contains("1"))
                XCTAssertTrue(argument.first.contains("2"))
                XCTAssertEqual(argument.a2, self.sut.labelID)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testHandleConversationMoveToAction() {
        let labelToMoveTo = MenuLabel(id: "0",
                                      name: "name",
                                      parentID: nil,
                                      path: "",
                                      textColor: "",
                                      iconColor: "",
                                      type: 0,
                                      order: 0,
                                      notify: false)
        // select the folder to move
        sut.updateSelectedMoveToDestination(menuLabel: labelToMoveTo, isOn: true)
        let conversationObject = Conversation(context: coreDataContextProviderMock.mainContext)
        conversationObject.conversationID = "1"
        let expectation1 = expectation(description: "Closure called")
        let conversationToMove = ConversationEntity(conversationObject)

        sut.handleMoveToAction(conversations: [conversationToMove], isFromSwipeAction: false) {
            XCTAssertTrue(self.conversationProviderMock.callMove.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callMove.lastArguments)
                XCTAssertTrue(argument.first.contains("1"))
                XCTAssertEqual(argument.a2, "")
                XCTAssertEqual(argument.a3, labelToMoveTo.location.labelID)
                XCTAssertFalse(argument.a4)

                XCTAssertEqual(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments?.a1, self.sut.labelID)
                XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(self.sut.selectedMoveToFolder)
    }

    func testHandleConversatinoMoveToAction_withNoDestination() {
        let conversationObject = Conversation(context: coreDataContextProviderMock.mainContext)
        conversationObject.conversationID = "1"
        let expectation1 = expectation(description: "Closure called")
        let conversationToMove = ConversationEntity(conversationObject)

        XCTAssertNil(self.sut.selectedMoveToFolder)
        sut.handleMoveToAction(conversations: [conversationToMove], isFromSwipeAction: false) {
            XCTAssertFalse(self.conversationProviderMock.callMove.wasCalledExactlyOnce)
            XCTAssertFalse(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDeleteConversationActionForSwipeAction_inTrash_moveIsCalled() {
        let conversationObject = Conversation(context: coreDataContextProviderMock.mainContext)
        conversationObject.conversationID = "1"
        createSut(labelID: Message.Location.trash.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let expectation1 = expectation(description: "Closure called")
        let conversationToMove = ConversationEntity(conversationObject)

        sut.delete(conversation: conversationToMove, isSwipeAction: false) {
            XCTAssertTrue(self.conversationProviderMock.callDelete.wasNotCalled)
            XCTAssertTrue(self.conversationProviderMock.callMove.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callMove.lastArguments)
                XCTAssertTrue(argument.first.contains("1"))
                XCTAssertEqual(argument.a2, conversationToMove.getFirstValidFolder() ?? "")
                XCTAssertEqual(argument.a3, Message.Location.trash.labelID)
                XCTAssertFalse(argument.a4)

                XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDeleteConversationActionForSwipeAction_inSpam_moveIsCalled() {
        let conversationObject = Conversation(context: coreDataContextProviderMock.mainContext)
        conversationObject.conversationID = "1"
        createSut(labelID: Message.Location.spam.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let expectation1 = expectation(description: "Closure called")
        let conversationToMove = ConversationEntity(conversationObject)

        sut.delete(conversation: conversationToMove, isSwipeAction: false) {
            XCTAssertTrue(self.conversationProviderMock.callDelete.wasNotCalled)
            XCTAssertTrue(self.conversationProviderMock.callMove.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callMove.lastArguments)
                XCTAssertTrue(argument.first.contains("1"))
                XCTAssertEqual(argument.a2, conversationToMove.getFirstValidFolder() ?? "")
                XCTAssertEqual(argument.a3, Message.Location.trash.labelID)
                XCTAssertFalse(argument.a4)

                XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDeleteConversationActionForSwipeAction_inDraft_moveIsCalled() {
        let conversationObject = Conversation(context: coreDataContextProviderMock.mainContext)
        conversationObject.conversationID = "1"
        createSut(labelID: Message.Location.draft.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let expectation1 = expectation(description: "Closure called")
        let conversationToMove = ConversationEntity(conversationObject)

        sut.delete(conversation: conversationToMove, isSwipeAction: false) {
            XCTAssertTrue(self.conversationProviderMock.callDelete.wasNotCalled)
            XCTAssertTrue(self.conversationProviderMock.callMove.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callMove.lastArguments)
                XCTAssertTrue(argument.first.contains("1"))
                XCTAssertEqual(argument.a2, conversationToMove.getFirstValidFolder() ?? "")
                XCTAssertEqual(argument.a3, Message.Location.trash.labelID)
                XCTAssertFalse(argument.a4)

                XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDeleteConversationActionForSwipeAction_inInbox_moveIsCalled() {
        let conversationObject = Conversation(context: coreDataContextProviderMock.mainContext)
        conversationObject.conversationID = "1"
        createSut(labelID: Message.Location.inbox.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let expectation1 = expectation(description: "Closure called")
        let conversationToMove = ConversationEntity(conversationObject)

        sut.delete(conversation: conversationToMove, isSwipeAction: false) {
            XCTAssertTrue(self.conversationProviderMock.callMove.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callMove.lastArguments)
                XCTAssertTrue(argument.first.contains("1"))
                XCTAssertEqual(argument.a2, conversationToMove.getFirstValidFolder() ?? "")
                XCTAssertEqual(argument.a3, Message.Location.trash.labelID)
                XCTAssertFalse(argument.a4)

                XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testHandleLabelAsActionForConversation_applyLabel_andApplyArchive() {
        let selectedLabel = MenuLabel(id: "label1",
                                      name: "label1",
                                      parentID: nil,
                                      path: "",
                                      textColor: "",
                                      iconColor: "",
                                      type: 0,
                                      order: 0,
                                      notify: false)
        let currentOption = [selectedLabel: PMActionSheetPlainItem.MarkType.none]
        let conversationObject = Conversation(context: coreDataContextProviderMock.mainContext)
        conversationObject.conversationID = "1234"
        let label = LabelLocation(id: "label1", name: nil)
        // select label1
        sut.selectedLabelAsLabels.insert(label)
        let expectation1 = expectation(description: "Closure called")
        let conversationToAddLabel = ConversationEntity(conversationObject)

        sut.handleLabelAsAction(conversations: [conversationToAddLabel],
                                shouldArchive: true,
                                currentOptionsStatus: currentOption) {
            XCTAssertTrue(self.conversationProviderMock.callLabel.wasCalledExactlyOnce)
            XCTAssertTrue(self.conversationProviderMock.callMove.wasCalledExactlyOnce)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalled)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callLabel.lastArguments)
                XCTAssertTrue(argument.first.contains(conversationToAddLabel.conversationID))
                XCTAssertEqual(argument.a2, label.labelID)
                XCTAssertFalse(argument.a3)

                // Check is move function called
                let argument2 = try XCTUnwrap(self.conversationProviderMock.callMove.lastArguments)
                XCTAssertTrue(argument2.first.contains(conversationToAddLabel.conversationID))
                XCTAssertEqual(argument2.a2, "")
                XCTAssertEqual(argument2.a3, Message.Location.archive.labelID)
                XCTAssertFalse(argument2.a4)

                // Check event api is called
                let argument3 = try XCTUnwrap(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments)
                XCTAssertEqual(argument3.a1, self.sut.labelId)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(sut.selectedLabelAsLabels.isEmpty)
    }

    func testHandleLabelAsActionForConversation_removeLabel_withoutApplyArchive() {
        let selectedLabel = MenuLabel(id: "label1",
                                      name: "label1",
                                      parentID: nil,
                                      path: "",
                                      textColor: "",
                                      iconColor: "",
                                      type: 0,
                                      order: 0,
                                      notify: false)
        let currentOption = [selectedLabel: PMActionSheetPlainItem.MarkType.none]
        let label = LabelLocation(id: "label1", name: nil)

        let conversationObject = Conversation(context: coreDataContextProviderMock.mainContext)
        conversationObject.conversationID = "1234"
        // Add label to be removed
        conversationObject.applyLabelChanges(labelID: label.labelID.rawValue, apply: true, context: coreDataContextProviderMock.mainContext)

        let expectation1 = expectation(description: "Closure called")
        let conversationToRemoveLabel = ConversationEntity(conversationObject)

        sut.handleLabelAsAction(conversations: [conversationToRemoveLabel],
                                shouldArchive: false,
                                currentOptionsStatus: currentOption) {
            XCTAssertTrue(self.conversationProviderMock.callUnlabel.wasCalledExactlyOnce)
            XCTAssertFalse(self.conversationProviderMock.callMove.wasCalledExactlyOnce)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalled)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.callUnlabel.lastArguments)
                XCTAssertTrue(argument.first.contains(conversationToRemoveLabel.conversationID))
                XCTAssertEqual(argument.a2, label.labelID)
                XCTAssertFalse(argument.a3)

                // Check event api is called
                let argument2 = try XCTUnwrap(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments)
                XCTAssertEqual(argument2.a1, self.sut.labelId)
            } catch {
                XCTFail("Should not reach here")
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(sut.selectedLabelAsLabels.isEmpty)
    }

    func testGetActionBarActions_inInbox() {
        createSut(labelID: Message.Location.inbox.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.getActionBarActions()
        XCTAssertEqual(result, [.markAsRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inStar() {
        createSut(labelID: Message.Location.starred.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.getActionBarActions()
        XCTAssertEqual(result, [.markAsRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inArchive() {
        createSut(labelID: Message.Location.archive.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.getActionBarActions()
        XCTAssertEqual(result, [.markAsRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inAllMail() {
        createSut(labelID: Message.Location.allmail.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.getActionBarActions()
        XCTAssertEqual(result, [.markAsRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inAllSent() {
        createSut(labelID: Message.Location.sent.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.getActionBarActions()
        XCTAssertEqual(result, [.markAsRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inDraft() {
        createSut(labelID: Message.Location.draft.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.getActionBarActions()
        XCTAssertEqual(result, [.markAsRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inTrash() {
        createSut(labelID: Message.Location.trash.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.getActionBarActions()
        XCTAssertEqual(result, [.delete, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inSpam() {
        createSut(labelID: Message.Location.spam.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.getActionBarActions()
        XCTAssertEqual(result, [.delete, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inCustomFolder() {
        let label = Label(context: coreDataContextProviderMock.mainContext)
        label.labelID = "qweqwe"
        label.type = 3
        labelProviderMock.labelToReturnInGetLabel = label
        createSut(labelID: "qweqwe", labelType: .folder, isCustom: false, labelName: nil)

        let result = sut.getActionBarActions()
        XCTAssertEqual(result, [.markAsRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inCustomLabel() {
        let label = Label(context: coreDataContextProviderMock.mainContext)
        label.labelID = "qweqwe"
        label.type = 1
        labelProviderMock.labelToReturnInGetLabel = label
        createSut(labelID: "qweqwe", labelType: .folder, isCustom: false, labelName: nil)

        let result = sut.getActionBarActions()
        XCTAssertEqual(result, [.markAsRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_withNonExistLabel() {
        createSut(labelID: "qweasd", labelType: .folder, isCustom: false, labelName: nil)
        XCTAssertTrue(sut.getActionBarActions().isEmpty)
    }

    func testGetOnboardingDestination() {
        // Fresh install
        self.welcomeCarrouselCache.lastTourVersion = nil
        var destination = self.sut.getOnboardingDestination()
        XCTAssertEqual(destination, .onboardingForNew)

        // The last tour version is the same as defined TOUR_VERSION
        // Shouldn't show welcome carrousel
        self.welcomeCarrouselCache.lastTourVersion = Constants.App.TourVersion
        destination = self.sut.getOnboardingDestination()
        XCTAssertNil(destination)

        // Update the app
        self.welcomeCarrouselCache.lastTourVersion = 1
        destination = self.sut.getOnboardingDestination()
        XCTAssertEqual(destination, .onboardingForUpdate)
    }


    func testSendsHapticFeedbackOnceWhenSwipeActionIsActivatedAndOnceItIsDeactivated() {
        var signalsSent = 0

        sut.sendHapticFeedback = {
            signalsSent += 1
        }

        for _ in (1...3) {
            sut.swipyCellDidSwipe(triggerActivated: false)
        }

        for _ in (1...3) {
            sut.swipyCellDidSwipe(triggerActivated: true)
        }

        XCTAssert(signalsSent == 1)

        for _ in (1...3) {
            sut.swipyCellDidSwipe(triggerActivated: true)
        }

        for _ in (1...3) {
            sut.swipyCellDidSwipe(triggerActivated: false)
        }

        XCTAssert(signalsSent == 2)
    }
}

extension MailboxViewModelTests {
    func loadTestMessage() throws {
        let parsedObject = testMessageMetaData.parseObjectAny()!
        let testMessage = try GRTJSONSerialization
            .object(withEntityName: "Message",
                    fromJSONDictionary: parsedObject,
                    in: coreDataContextProviderMock.rootSavingContext) as? Message
        testMessage?.userID = "1"
        testMessage?.messageStatus = 1
        try coreDataContextProviderMock.rootSavingContext.save()
    }

    func createSut(labelID: String,
                   labelType: PMLabelType,
                   isCustom: Bool,
                   labelName: String?,
                   totalUserCount: Int = 1) {
        let dependencies = MailboxViewModel.Dependencies(
            fetchMessages: MockFetchMessages(),
            fetchMessagesWithReset: MockFetchMessagesWithReset(),
            fetchLatestEventIdUseCase: mockFetchLatestEventId,
            purgeOldMessages: mockPurgeOldMessages
        )
        let label = LabelInfo(labelID: LabelID(labelID), name: labelName ?? "")
        sut = MailboxViewModel(labelID: LabelID(labelID),
                               label: isCustom ? label : nil,
                               labelType: labelType,
                               userManager: userManagerMock,
                               pushService: pushNotificationServiceMock,
                               coreDataContextProvider: coreDataContextProviderMock,
                               lastUpdatedStore: lastUpdatedStoreMock,
                               humanCheckStatusProvider: humanCheckStatusProviderMock,
                               conversationStateProvider: conversationStateProviderMock,
                               contactGroupProvider: contactGroupProviderMock,
                               labelProvider: labelProviderMock,
                               contactProvider: contactProviderMock,
                               conversationProvider: conversationProviderMock,
                               eventsService: eventsServiceMock,
                               dependencies: dependencies,
                               welcomeCarrouselCache: welcomeCarrouselCache,
                               totalUserCountClosure: {
            return totalUserCount
        })
    }
}
