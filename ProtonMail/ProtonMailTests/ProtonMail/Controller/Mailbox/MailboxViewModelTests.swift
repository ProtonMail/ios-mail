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
import Groot
@testable import ProtonMail
import ProtonCoreTestingToolkitUnitTestsDoh
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreUIFoundations

final class MailboxViewModelTests: XCTestCase {

    var sut: MailboxViewModel!
    var apiServiceMock: APIServiceMock!
    var featureFlagCache: MockFeatureFlagCache!
    var userManagerMock: UserManager!
    var conversationStateProviderMock: MockConversationStateProviderProtocol!
    var fetchMessageWithReset: MockFetchMessagesWithReset!
    var contactGroupProviderMock: MockContactGroupsProviderProtocol!
    var labelProviderMock: MockLabelProviderProtocol!
    var contactProviderMock: MockContactProvider!
    var conversationProviderMock: MockConversationProvider!
    var eventsServiceMock: EventsServiceMock!
    var mockFetchLatestEventId: MockFetchLatestEventId!
    var toolbarActionProviderMock: MockToolbarActionProvider!
    var saveToolbarActionUseCaseMock: MockSaveToolbarActionSettingsForUsersUseCase!
    var imageTempUrl: URL!
    var mockFetchMessageDetail: MockFetchMessageDetail!
    var mockLoadedMessage: Message!
    var fakeTableView: UITableView!
    var delegateMock: MockCoreDataDelegateObject!
    private let selectionLimitation = 5

    private var globalContainer: TestContainer!
    private var userNotificationCenter: MockUserNotificationCenterProtocol!

    var coreDataService: CoreDataContextProviderProtocol {
        globalContainer.contextProvider
    }

    var testContext: NSManagedObjectContext {
        coreDataService.mainContext
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        userNotificationCenter = .init()

        globalContainer = .init()
        globalContainer.userNotificationCenterFactory.register { self.userNotificationCenter }

        apiServiceMock = APIServiceMock()
        apiServiceMock.sessionUIDStub.fixture = String.randomString(10)
        apiServiceMock.dohInterfaceStub.fixture = DohMock()
        let fakeAuth = AuthCredential(sessionID: "",
                                      accessToken: "",
                                      refreshToken: "",
                                      userName: "",
                                      userID: "1",
                                      privateKey: nil,
                                      passwordKeySalt: nil)
        let stubUserInfo = UserInfo(maxSpace: nil,
                                    maxBaseSpace: nil,
                                    maxDriveSpace: nil,
                                    usedSpace: nil,
                                    usedBaseSpace: nil,
                                    usedDriveSpace: nil,
                                    language: nil,
                                    maxUpload: nil,
                                    role: nil,
                                    delinquent: nil,
                                    keys: nil,
                                    userId: "1",
                                    linkConfirmation: nil,
                                    credit: nil,
                                    currency: nil,
                                    createTime: nil,
                                    subscribed: nil)
        userManagerMock = UserManager(api: apiServiceMock,
                                      userInfo: stubUserInfo,
                                      authCredential: fakeAuth,
                                      mailSettings: nil,
                                      parent: nil,
                                      globalContainer: globalContainer)
        featureFlagCache = .init()
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [
                FeatureFlagKey.mailboxSelectionLimitation.rawValue: self.selectionLimitation
            ])
        }
        userManagerMock.conversationStateService.userInfoHasChanged(viewMode: .singleMessage)
        globalContainer.featureFlagCacheFactory.register { self.featureFlagCache }
        conversationStateProviderMock = MockConversationStateProviderProtocol()
        fetchMessageWithReset = MockFetchMessagesWithReset()
        contactGroupProviderMock = MockContactGroupsProviderProtocol()
        labelProviderMock = MockLabelProviderProtocol()
        contactProviderMock = MockContactProvider(coreDataContextProvider: coreDataService)
        conversationProviderMock = MockConversationProvider()
        eventsServiceMock = EventsServiceMock()
        mockFetchLatestEventId = MockFetchLatestEventId()
        toolbarActionProviderMock = MockToolbarActionProvider()
        saveToolbarActionUseCaseMock = MockSaveToolbarActionSettingsForUsersUseCase()
        mockLoadedMessage = try loadTestMessage() // one message
        fakeTableView = .init()
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)

        conversationProviderMock.fetchConversationStub.bodyIs { [unowned self] _, _, _, _, completion in
            completion(.success(Conversation(context: self.testContext)))
        }

        conversationProviderMock.fetchConversationCountsStub.bodyIs { _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.fetchConversationsStub.bodyIs { _, _, _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.labelStub.bodyIs { _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.markAsReadStub.bodyIs { _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.markAsUnreadStub.bodyIs { _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.moveStub.bodyIs { _, _, _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.unlabelStub.bodyIs { _, _, _, completion in
            completion?(.success(()))
        }

        // Prepare for api mock to write image data to disk
        imageTempUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent("senderImage", isDirectory: true)
        try FileManager.default.createDirectory(at: imageTempUrl, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        delegateMock = nil
        sut = nil
        contactGroupProviderMock = nil
        contactProviderMock = nil
        eventsServiceMock = nil
        featureFlagCache = nil
        userManagerMock = nil
        mockFetchLatestEventId = nil
        toolbarActionProviderMock = nil
        saveToolbarActionUseCaseMock = nil
        apiServiceMock = nil
        globalContainer = nil
        fakeTableView = nil
        fetchMessageWithReset = nil
        userNotificationCenter = nil

        try FileManager.default.removeItem(at: imageTempUrl)
    }

    func testMessageItemOfIndexPath() {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        wait(self.sut.diffableDataSource?.snapshot().numberOfItems ?? 0 > 0)

        XCTAssertNotNil(sut.item(index:IndexPath(row: 0, section: 0)))
        XCTAssertNil(sut.item(index:IndexPath(row: 1, section: 0)))
        XCTAssertNil(sut.item(index:IndexPath(row: 0, section: 1)))
    }

    func testSelectByID_withSelectionLimitation() {
        XCTAssertTrue(sut.selectedIDs.isEmpty)
        let ids = Array(0...selectionLimitation).map { "\($0)"}
        for (index, id) in ids.enumerated() {
            let isAllowed = sut.select(id: id)
            if index < selectionLimitation {
                XCTAssertTrue(isAllowed)
            } else {
                XCTAssertFalse(isAllowed)
            }
        }
        for id in ids.prefix(selectionLimitation) {
            XCTAssertTrue(sut.selectedIDs.contains(id))
        }
        XCTAssertEqual(sut.selectedIDs.count, selectionLimitation)
    }

    func testRemoveSelectByID() {
        _ = sut.select(id: "1")
        _ = sut.select(id: "2")
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
        _ = sut.select(id: "1")
        _ = sut.select(id: "2")
        XCTAssertEqual(sut.selectedIDs.count, 2)
        sut.removeAllSelectedIDs()
        XCTAssertTrue(sut.selectedIDs.isEmpty)
    }

    func testSelectionContains() {
        XCTAssertTrue(sut.selectedIDs.isEmpty)
        _ = sut.select(id: "1")
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

    func testGetLocationViewMode_inDraftAndSent_getSingleMessageOnly() {
        createSut(labelID: Message.Location.draft.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        XCTAssertEqual(sut.locationViewMode, .singleMessage)

        createSut(labelID: Message.Location.sent.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
    }

    func testGetLocationViewMode_notInDraftOrSent_getViewModeFromConversationStateProvider() {
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        XCTAssertEqual(sut.locationViewMode, .conversation)

        createSut(labelID: "custom",
                  labelType: .folder,
                  isCustom: true,
                  labelName: "1")
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        XCTAssertEqual(sut.locationViewMode, .conversation)

        createSut(labelID: "custom1",
                  labelType: .label,
                  isCustom: true,
                  labelName: "2")
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        XCTAssertEqual(sut.locationViewMode, .singleMessage)
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        XCTAssertEqual(sut.locationViewMode, .conversation)
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
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        XCTAssertEqual(sut.selectedIDs.count, 0)
        let model = sut.actionSheetViewModel
        XCTAssertEqual(model.title, .localizedStringWithFormat(LocalString._general_message, 0))

        conversationStateProviderMock.viewModeStub.fixture = .conversation
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        _ = sut.select(id: "id")
        XCTAssertEqual(sut.selectedIDs.count, 1)
        let model2 = sut.actionSheetViewModel
        XCTAssertEqual(model2.title, .localizedStringWithFormat(LocalString._general_conversation, 1))
    }

    func testGetEmptyFolderCheckMessage() {
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)

        XCTAssertEqual(
            sut.getEmptyFolderCheckMessage(folder: .trash),
            "Are you sure you want to permanently delete all messages within 'Trash'?"
        )
    }

    func testGetGroupContacts() {
        let testData = ContactGroupVO(ID: "1", name: "name1", contextProvider: coreDataService)
        contactGroupProviderMock.getAllContactGroupVOsStub.bodyIs { _ in
            [testData]
        }
        createSut(labelID: "1", labelType: .folder, isCustom: false, labelName: nil)

        XCTAssertEqual(sut.contactGroups(), [testData])
    }

    func testGetCustomFolders() {
        let testData = LabelEntity.make(labelID: "1", name: "name1")
        labelProviderMock.getCustomFoldersStub.bodyIs { _ in
            [testData]
        }
        createSut(labelID: "1", labelType: .folder, isCustom: false, labelName: nil)

        XCTAssertEqual(sut.customFolders, [testData])
    }

    func testFetchContacts() {
        sut.fetchContacts()
        XCTAssertEqual(contactProviderMock.fetchContactsStub.callCounter, 1)
    }

    func testGetAllEmails() {
        let testData = EmailEntity.make(emailID: .init("1"), email: "test@pm.me")
        contactProviderMock.allEmailsToReturn = [testData]
        createSut(labelID: "1", labelType: .folder, isCustom: false, labelName: nil)

        XCTAssertEqual(sut.allEmails, [testData])
    }

    func testTrashFromActionSheet_trashedSelectedConversations() throws {
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        let conversationIDs = try setupConversations(labelID: sut.labelID.rawValue, count: 3, unread: false)
        wait(self.sut.diffableDataSource?.snapshot().numberOfItems == 3)

        for id in conversationIDs {
            _ = sut.select(id: id)
        }

        sut.handleBarActions(.trash, completion: nil)

        XCTAssertTrue(self.conversationProviderMock.moveStub.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(self.conversationProviderMock.moveStub.lastArguments)
        XCTAssertEqual(Set(argument.first.map(\.rawValue)), Set(conversationIDs))

        XCTAssertEqual(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments?.value, self.sut.labelID)
        XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
    }

    func testMarkConversationAsRead() {
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        testContext.performAndWait {
            _ = Conversation(
                from: ConversationEntity.make(
                    conversationID: "1",
                    userID: userManagerMock.userID,
                    contextLabelRelations: [
                        .make(
                            unreadCount: 0,
                            conversationID: "1",
                            labelID: "0",
                            userID: userManagerMock.userID
                        )
                    ]
                ),
                context: testContext
            )
            _ = Conversation(
                from: ConversationEntity.make(
                    conversationID: "2",
                    userID: userManagerMock.userID,
                    contextLabelRelations: [
                        .make(
                            unreadCount: 1,
                            conversationID: "2",
                            labelID: "0",
                            userID: userManagerMock.userID
                        )
                    ]
                ),
                context: testContext
            )
            try? testContext.save()
        }
        createSut(labelID: "0", labelType: .folder, isCustom: false, labelName: nil)
        wait(self.sut.diffableDataSource?.snapshot().numberOfItems == 2)

        let expectation1 = expectation(description: "Closure called")
        let ids = Set<String>(["1", "2"])
        _ = sut.select(id: "1")
        _ = sut.select(id: "2")
        sut.mark(IDs: ids, unread: false) {
            XCTAssertTrue(self.conversationProviderMock.markAsReadStub.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.markAsReadStub.lastArguments
            XCTAssertNotNil(argument)
            XCTAssertFalse(argument?.first.contains("1") ?? false)
            XCTAssertTrue(argument?.first.contains("2") ?? false)
            XCTAssertEqual(argument?.a2, "0")

            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testMarkConversationAsUnread() {
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        testContext.performAndWait {
            _ = Conversation(
                from: ConversationEntity.make(
                    conversationID: "1",
                    userID: userManagerMock.userID,
                    contextLabelRelations: [
                        .make(
                            unreadCount: 0,
                            conversationID: "1",
                            labelID: "0",
                            userID: userManagerMock.userID
                        )
                    ]
                ),
                context: testContext
            )
            _ = Conversation(
                from: ConversationEntity.make(
                    conversationID: "2",
                    userID: userManagerMock.userID,
                    contextLabelRelations: [
                        .make(
                            unreadCount: 1,
                            conversationID: "2",
                            labelID: "0",
                            userID: userManagerMock.userID
                        )
                    ]
                ),
                context: testContext
            )
            try? testContext.save()
        }
        createSut(labelID: "0", labelType: .folder, isCustom: false, labelName: nil)
        wait(self.sut.diffableDataSource?.snapshot().numberOfItems == 2)

        let expectation1 = expectation(description: "Closure called")
        let ids = Set<String>(["1", "2"])
        _ = sut.select(id: "1")
        _ = sut.select(id: "2")
        sut.mark(IDs: ids, unread: true) {
            XCTAssertTrue(self.conversationProviderMock.markAsUnreadStub.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.markAsUnreadStub.lastArguments
            XCTAssertNotNil(argument)
            XCTAssertTrue(argument?.first.contains("1") ?? false)
            XCTAssertFalse(argument?.first.contains("2") ?? false)
            XCTAssertEqual(argument?.a2, "0")

            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testLabelConversation_applyLabel() {
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)

        let expectation1 = expectation(description: "Closure called")
        let ids = Set<String>(["1", "2"])
        sut.label(IDs: ids, with: "labelID", apply: true) {
            XCTAssertTrue(self.conversationProviderMock.labelStub.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.labelStub.lastArguments
            XCTAssertNotNil(argument)
            XCTAssertTrue(argument?.first.contains("1") ?? false)
            XCTAssertTrue(argument?.first.contains("2") ?? false)
            XCTAssertEqual(argument?.a2, "labelID")

            XCTAssertEqual(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments?.value, self.sut.labelID)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testLabelConversation_removeLabel() {
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        createSut(labelID: "1245", labelType: .folder, isCustom: false, labelName: nil)

        let expectation1 = expectation(description: "Closure called")
        let ids = Set<String>(["1", "2"])
        sut.label(IDs: ids, with: "labelID", apply: false) {
            XCTAssertTrue(self.conversationProviderMock.unlabelStub.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.unlabelStub.lastArguments
            XCTAssertNotNil(argument)
            XCTAssertTrue(argument?.first.contains("1") ?? false)
            XCTAssertTrue(argument?.first.contains("2") ?? false)
            XCTAssertEqual(argument?.a2, "labelID")

            XCTAssertEqual(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments?.value, self.sut.labelID)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalledExactlyOnce)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchConversationDetailIsCalled() {
        let expectation1 = expectation(description: "Closure called")

        sut.fetchConversationDetail(conversationID: "conversationID1") {
            XCTAssertTrue(self.conversationProviderMock.fetchConversationStub.wasCalledExactlyOnce)
            let argument = self.conversationProviderMock.fetchConversationStub.lastArguments
            XCTAssertNotNil(argument)
            XCTAssertEqual(argument?.first, "conversationID1")
            XCTAssertNil(argument?.a2)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDeleteConversationPermanently() throws {
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        let conversationIDs = try setupConversations(labelID: sut.labelID.rawValue, count: 3, unread: false)
        wait(self.sut.diffableDataSource?.snapshot().numberOfItems == 3)

        for id in conversationIDs {
            _ = sut.select(id: id)
        }

        sut.deleteSelectedIDs()

        XCTAssertTrue(self.conversationProviderMock.deleteConversationsStub.wasCalledExactlyOnce)
        let argument = try XCTUnwrap(self.conversationProviderMock.deleteConversationsStub.lastArguments)
        XCTAssertEqual(Set(argument.first.map(\.rawValue)), Set(conversationIDs))
        XCTAssertEqual(argument.a2, self.sut.labelID)
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
        let expectation1 = expectation(description: "Closure called")
        let conversationToMove = ConversationEntity.make(conversationID: "1")

        sut.handleMoveToAction(conversations: [conversationToMove], to: labelToMoveTo) {
            XCTAssertTrue(self.conversationProviderMock.moveStub.wasCalledExactlyOnce)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.moveStub.lastArguments)
                XCTAssertTrue(argument.first.contains("1"))
                XCTAssertEqual(argument.a2, self.sut.labelID)
                XCTAssertEqual(argument.a3, labelToMoveTo.location.labelID)

                XCTAssertEqual(self.eventsServiceMock.callFetchEventsByLabelID.lastArguments?.a1, self.sut.labelID)
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
        let currentOption = [selectedLabel: PMActionSheetItem.MarkType.none]
        let label = LabelLocation(id: "label1", name: nil)
        // select label1
        sut.selectedLabelAsLabels.insert(label)
        let expectation1 = expectation(description: "Closure called")
        let conversationToAddLabel = ConversationEntity.make(conversationID: "1234")

        sut.handleLabelAsAction(conversations: [conversationToAddLabel],
                                shouldArchive: true,
                                currentOptionsStatus: currentOption) {
            XCTAssertTrue(self.conversationProviderMock.labelStub.wasCalledExactlyOnce)
            XCTAssertTrue(self.conversationProviderMock.moveStub.wasCalledExactlyOnce)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalled)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.labelStub.lastArguments)
                XCTAssertTrue(argument.first.contains(conversationToAddLabel.conversationID))
                XCTAssertEqual(argument.a2, label.labelID)

                // Check is move function called
                let argument2 = try XCTUnwrap(self.conversationProviderMock.moveStub.lastArguments)
                XCTAssertTrue(argument2.first.contains(conversationToAddLabel.conversationID))
                XCTAssertEqual(argument2.a2, "")
                XCTAssertEqual(argument2.a3, Message.Location.archive.labelID)

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
        let currentOption = [selectedLabel: PMActionSheetItem.MarkType.none]
        let label = LabelLocation(id: "label1", name: nil)

        let conversationObject = Conversation(context: testContext)
        conversationObject.conversationID = "1234"
        // Add label to be removed
        conversationObject.applyLabelChanges(labelID: label.labelID.rawValue, apply: true)

        let expectation1 = expectation(description: "Closure called")
        let conversationToRemoveLabel = ConversationEntity(conversationObject)

        sut.handleLabelAsAction(conversations: [conversationToRemoveLabel],
                                shouldArchive: false,
                                currentOptionsStatus: currentOption) {
            XCTAssertTrue(self.conversationProviderMock.unlabelStub.wasCalledExactlyOnce)
            XCTAssertFalse(self.conversationProviderMock.moveStub.wasCalledExactlyOnce)
            XCTAssertTrue(self.eventsServiceMock.callFetchEventsByLabelID.wasCalled)
            do {
                let argument = try XCTUnwrap(self.conversationProviderMock.unlabelStub.lastArguments)
                XCTAssertTrue(argument.first.contains(conversationToRemoveLabel.conversationID))
                XCTAssertEqual(argument.a2, label.labelID)

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
        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inStar() {
        createSut(labelID: Message.Location.starred.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inArchive() {
        createSut(labelID: Message.Location.archive.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inAllMail() {
        createSut(labelID: Message.Location.allmail.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inAllSent() {
        createSut(labelID: Message.Location.sent.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inDraft() {
        createSut(labelID: Message.Location.draft.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inTrash() {
        createSut(labelID: Message.Location.trash.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .delete, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inSpam() {
        createSut(labelID: Message.Location.spam.rawValue, labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .delete, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inCustomFolder() {
        createSut(labelID: "qweqwe", labelType: .folder, isCustom: false, labelName: nil)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_inCustomLabel() {
        createSut(labelID: "qweqwe", labelType: .label, isCustom: false, labelName: nil)

        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_withNonExistLabel() {
        createSut(labelID: "qweasd", labelType: .folder, isCustom: false, labelName: nil)
        let result = sut.toolbarActionTypes()
        XCTAssertEqual(result, [.markRead, .trash, .moveTo, .labelAs, .more])
    }

    func testGetActionBarActions_withCustomToolbarActions() {
        createSut(labelID: "qweasd", labelType: .folder, isCustom: false, labelName: nil)
        toolbarActionProviderMock.listViewToolbarActions = [.star, .saveAsPDF]

        let result = sut.toolbarActionTypes()

        XCTAssertEqual(result, [.star, .saveAsPDF, .more])
    }

    func testGetOnboardingDestination() {
        // Fresh install
        globalContainer.userDefaults[.lastTourVersion] = nil
        var destination = self.sut.getOnboardingDestination()
        XCTAssertEqual(destination, .onboardingForNew)

        // The last tour version is the same as defined TOUR_VERSION
        // Shouldn't show welcome carrousel
        globalContainer.userDefaults[.lastTourVersion] = Constants.App.TourVersion
        destination = self.sut.getOnboardingDestination()
        XCTAssertNil(destination)

        // Update the app
        globalContainer.userDefaults[.lastTourVersion] = 1
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

    func testTagUIModels_for_conversation() throws {
        try coreDataService.write { context in
            let conversation = Conversation(context: context)
            conversation.userID = self.sut.user.userID.rawValue
            conversation.expirationTime = Date()

            let systemLabel = Label(context: context)
            systemLabel.labelID = Message.Location.inbox.rawValue
            systemLabel.name = "Inbox"

            let userLabels: [Label] = (1...3).map { index in
                let userLabel = Label(context: context)
                userLabel.labelID = UUID().uuidString
                userLabel.name = "Label \(index)"
                // set descending `order` to test sorting
                userLabel.order = 10 - index as NSNumber
                return userLabel
            }

            let allLabels: [Label] = [systemLabel] + userLabels

            for label in allLabels {
                label.type = 1
                label.userID = conversation.userID
            }

            let contextLabels: [ContextLabel] = allLabels.map { label in
                let contextLabel = ContextLabel(context: context)
                contextLabel.labelID = label.labelID
                return contextLabel
            }
            conversation.labels = NSSet(array: contextLabels)
        }

        let conversationEntity = try coreDataService.read { context in
            let conversation = try XCTUnwrap(
                context.managedObjectWithEntityName(Conversation.Attributes.entityName, matching: [:]) as? Conversation
            )
            return ConversationEntity(conversation)
        }

        let tags = sut.tagUIModels(for: conversationEntity)

        // no tag based on the system label
        XCTAssertFalse(tags.contains { $0.title == Message.Location.inbox.rawValue })

        // expiration tag is present
        XCTAssertEqual(tags[0].icon, IconProvider.hourglass)

        // sorted according to `order` set above
        XCTAssertEqual(tags[1].title, "Label 3")
        XCTAssertEqual(tags[2].title, "Label 2")
        XCTAssertEqual(tags[3].title, "Label 1")
    }

    func testUpdateToolbarActions_updateActionWithoutMoreAction() {
        saveToolbarActionUseCaseMock.callExecute.bodyIs { _, _, completion  in
            completion(.success(Void()))
        }
        let e = expectation(description: "Closure is called")
        sut.updateToolbarActions(actions: [.unstar, .markRead]) { _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(saveToolbarActionUseCaseMock.callExecute.wasCalledExactlyOnce)
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.listViewActions, [.unstar, .markRead])
    }

    func testUpdateToolbarActions_updateActionWithMoreAction() {
        saveToolbarActionUseCaseMock.callExecute.bodyIs { _, _, completion  in
            completion(.success(Void()))
        }
        let e = expectation(description: "Closure is called")
        sut.updateToolbarActions(actions: [.unstar, .markRead, .more]) { _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(saveToolbarActionUseCaseMock.callExecute.wasCalledExactlyOnce)
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.listViewActions, [.unstar, .markRead])

        let e1 = expectation(description: "Closure is called")
        sut.updateToolbarActions(actions: [.more, .unstar, .markRead]) { _ in
            e1.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertTrue(saveToolbarActionUseCaseMock.callExecute.wasCalled)
        XCTAssertEqual(saveToolbarActionUseCaseMock.callExecute.lastArguments?.first.preference.listViewActions, [.unstar, .markRead])
    }

    func testSwipeGesturesIgnoreSelection() throws {
        let selectedConversationIDs = ["foo", "bar"]

        for conversationID in selectedConversationIDs {
            _ = sut.select(id: conversationID)
        }

        sut.handleSwipeAction(.trash, on: .conversation(.make(conversationID: ConversationID("xyz"))))

        XCTAssertEqual(conversationProviderMock.moveStub.callCounter, 1)
        let lastMoveArguments = try XCTUnwrap(conversationProviderMock.moveStub.lastArguments)
        XCTAssertEqual(lastMoveArguments.a1, ["xyz"])
        XCTAssertEqual(lastMoveArguments.a3, Message.Location.trash.labelID)

    }

    func testFetchSenderImageIfNeeded_featureFlagIsOff_getNil() {
        userManagerMock.mailSettings = .init(hideSenderImages: false)
        let e = expectation(description: "Closure is called")

        sut.fetchSenderImageIfNeeded(item: .message(MessageEntity.make()),
                                     isDarkMode: Bool.random(),
                                     scale: 1.0) { result in
            XCTAssertNil(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(apiServiceMock.requestJSONStub.wasNotCalled)
    }

    func testFetchSenderImageIfNeeded_hideSenderImageInMailSettingTrue_getNil() {
        userManagerMock.mailSettings = .init(hideSenderImages: true)
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.senderImage.rawValue: true])
        }
        let e = expectation(description: "Closure is called")

        sut.fetchSenderImageIfNeeded(item: .message(MessageEntity.make()),
                                     isDarkMode: Bool.random(),
                                     scale: 1.0) { result in
            XCTAssertNil(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(apiServiceMock.requestJSONStub.wasNotCalled)
    }

    func testFetchSenderImageIfNeeded_msgHasNoSenderThatIsEligible_getNil() {
        userManagerMock.mailSettings = .init(hideSenderImages: false)
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.senderImage.rawValue: true])
        }
        let e = expectation(description: "Closure is called")
        let e2 = expectation(description: "Closure is called")

        sut.fetchSenderImageIfNeeded(item: .message(MessageEntity.make()),
                                     isDarkMode: Bool.random(),
                                     scale: 1.0) { result in
            XCTAssertNil(result)
            e.fulfill()
        }

        sut.fetchSenderImageIfNeeded(item: .conversation(ConversationEntity.make()),
                                     isDarkMode: Bool.random(),
                                     scale: 1.0) { result in
            XCTAssertNil(result)
            e2.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(apiServiceMock.requestJSONStub.wasNotCalled)
    }

    func testFetchSenderImageIfNeeded_msgHasEligibleSender_getImageData() {
        userManagerMock.mailSettings = .init(hideSenderImages: false)
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.senderImage.rawValue: true])
        }
        let e = expectation(description: "Closure is called")
        let msg = MessageEntity.createSenderImageEligibleMessage()
        let imageData = UIImage(named: "ic-file-type-audio")?.pngData()
        apiServiceMock.downloadStub.bodyIs { _, _, fileUrl, _, _, _, _, _, _, completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                try? imageData?.write(to: fileUrl)
                let response = HTTPURLResponse(statusCode: 200)
                completion(response, nil, nil)
            }
        }

        sut.fetchSenderImageIfNeeded(item: .message(msg),
                                     isDarkMode: Bool.random(),
                                     scale: 1.0) { result in
            XCTAssertNotNil(result)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertTrue(apiServiceMock.downloadStub.wasCalledExactlyOnce)
    }

    func testFetchMessageDetail_forDraft_ignoreDownloadedIsTrue() throws {
        let fakeMsg = MessageEntity.make(
            labels: [LabelEntity.make(labelID: Message.Location.draft.labelID)]
        )
        let e = expectation(description: "Closure is called")
        mockFetchMessageDetail.result = .success(fakeMsg)

        sut.fetchMessageDetail(
            message: fakeMsg) { _ in
                e.fulfill()
            }

        waitForExpectations(timeout: 1)

        let params = try XCTUnwrap(mockFetchMessageDetail.params)
        XCTAssertTrue(params.ignoreDownloaded)
    }

    func testFetchMessageDetail_msgIsNotDraft_ignoreDownloadedIsFalse() throws {
        let fakeMsg = MessageEntity.make(
            labels: [LabelEntity.make(labelID: Message.Location.inbox.labelID)]
        )
        let e = expectation(description: "Closure is called")
        mockFetchMessageDetail.result = .success(fakeMsg)

        sut.fetchMessageDetail(
            message: fakeMsg) { _ in
                e.fulfill()
            }

        waitForExpectations(timeout: 1)

        let params = try XCTUnwrap(mockFetchMessageDetail.params)
        XCTAssertFalse(params.ignoreDownloaded)
    }

    func testMarkAsUnRead_selectOneReadAndOneUnreadMessage_onlyReadMessageIsMarkAsUnread() throws {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        let readMsgIds = String.randomString(10)
        let unreadMsgIds = String.randomString(10)
        try coreDataService.write { context in
            let msg = MessageEntity.make(
                messageID: .init(readMsgIds),
                userID: self.userManagerMock.userID,
                unRead: false,
                labels: [LabelEntity.make(labelID: .init("0"))]
            )
            _ = Message(from: msg, context: context)

            let unreadMsg = MessageEntity.make(
                messageID: .init(unreadMsgIds),
                userID: self.userManagerMock.userID,
                unRead: true,
                labels: [LabelEntity.make(labelID: .init("0"))]
            )
            _ = Message(from: unreadMsg, context: context)
            try? context.save()
        }
        createSut(labelID: Message.Location.inbox.rawValue,
                  labelType: .folder,
                  isCustom: false,
                  labelName: nil)
        wait(self.sut.diffableDataSource?.snapshot().numberOfItems == 3)

        _ = sut.select(id: readMsgIds)
        _ = sut.select(id: unreadMsgIds)
        let e = expectation(description: "Closure is called")


        XCTAssertEqual(sut.selectedIDs.count, 2)
        XCTAssertEqual(sut.selectedConversations.count, 0)
        XCTAssertEqual(sut.selectedMessages.count, 2)
        sut.mark(IDs: .init([readMsgIds, unreadMsgIds]), unread: true) {
            e.fulfill()
        }
        waitForExpectations(timeout: 1)

        // Check if the message is updated
        coreDataService.performAndWaitOnRootSavingContext { context in
            let msg = Message.messageForMessageID(
                readMsgIds,
                inManagedObjectContext: context
            )
            XCTAssertTrue(msg?.unRead ?? false)

            let msg2 = Message.messageForMessageID(
                unreadMsgIds,
                inManagedObjectContext: context
            )
            XCTAssertTrue(msg2?.unRead ?? false)
        }
    }

    func testListEditing_setItToFalse_theSelectedIDsWillBeRemoved() {
        _ = sut.select(id: String.randomString(20))
        XCTAssertFalse(sut.selectedIDs.isEmpty)

        sut.listEditing = false

        XCTAssertTrue(sut.selectedIDs.isEmpty)
    }

    func testListEditing_setItToTrue_theSelectedIDsWillNotBeRemoved() {
        _ = sut.select(id: String.randomString(20))
        XCTAssertFalse(sut.selectedIDs.isEmpty)

        sut.listEditing = true

        XCTAssertFalse(sut.selectedIDs.isEmpty)
    }

    func testItemsToPrefetchShouldFetchConversationsInConversationMode() throws {
        /// Given conversation mode and a random number of conversations, no matter their read status,
        /// and a random number of messages, no matter their read status
        conversationStateProviderMock.viewModeStub.fixture = .conversation

        let conversations = try setupConversations(labelID: Message.Location.inbox.rawValue, count: Int.random(in: 0..<100), unread: Bool.random())
        _ = try setupMessages(labelID: Message.Location.inbox.rawValue, count: Int.random(in: 0..<100), unread: Bool.random())
        wait(self.sut.diffableDataSource?.snapshot().itemIdentifiers.count == conversations.count)

        /// When determinining items to prefetch
        let itemsToPrefetch = sut.itemsToPrefetch()

        /// Then those should be conversations in equal number

        XCTAssertEqual(itemsToPrefetch.count, conversations.count)
        XCTAssertTrue(itemsToPrefetch.areAllConversations)
    }

    func testItemsToPrefetchShouldFetchMessagesInSingleMessageMode() throws {
        /// Given single message mode and a random number of conversations, no matter their read status,
        /// and a random number of messages, no matter their read status
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage

        _ = try setupConversations(
            labelID: Message.Location.inbox.rawValue,
            count: Int.random(in: 0..<100),
            unread: Bool.random()
        )
        let messages = try setupMessages(
            labelID: Message.Location.inbox.rawValue,
            count: Int.random(in: 0..<100),
            unread: Bool.random()
        )
        createSut(
            labelID: Message.Location.inbox.rawValue,
            labelType: .folder,
            isCustom: false,
            labelName: nil
        )
        wait(self.sut.diffableDataSource?.snapshot().itemIdentifiers.count == messages.count + 1)

        /// When determinining items to prefetch
        let itemsToPrefetch = sut.itemsToPrefetch()

        /// Then those should be messages in equal number + 1 for the default one that is inserted during setup
        XCTAssertEqual(itemsToPrefetch.count, messages.count + 1)
        XCTAssertTrue(itemsToPrefetch.areAllMessages)
    }

    func testItemsToPrefetchShouldReturnUnreadConversationsFirstAndInTheSameOrder() throws {
        /// Given conversation mode and a random number of read conversations, and a random number of unread conversations
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        let readConversations = try setupConversations(labelID: Message.Location.inbox.rawValue,
                                                   count: Int.random(in: 0..<100),
                                                   unread: false)
        let unreadConversations = try setupConversations(labelID: Message.Location.inbox.rawValue,
                                                     count: Int.random(in: 0..<100),
                                                     unread: true)
        wait(self.sut.diffableDataSource?.snapshot().itemIdentifiers.count == unreadConversations.count + readConversations.count)

        /// When determining items to prefetch
        let itemsToPrefetch = sut.itemsToPrefetch()

        /// Unread conversations should be first and in the same order (time + order)
        let conversationEntities = itemsToPrefetch.allConversations
        XCTAssertEqual(conversationEntities.prefix(unreadConversations.count).map(\.conversationID.rawValue),
                       unreadConversations)
        XCTAssertEqual(conversationEntities.dropFirst(unreadConversations.count).map(\.conversationID.rawValue),
                       readConversations)
    }

    func testItemsToPrefetchShouldReturnUnreadMessagesFirstAndInTheSameOrder() throws {
        /// Given single message mode and a random number of read messages, and a random number of unread messages
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        let unreadMessages = try setupMessages(labelID: Message.Location.inbox.rawValue,
                                           count: Int.random(in: 0..<100),
                                           unread: true)
        let readMessages = try setupMessages(labelID: Message.Location.inbox.rawValue,
                                         count: Int.random(in: 0..<100),
                                         unread: false)
        let defaultMockMessage = self.mockLoadedMessage // Message loaded by default is setup, unread one
        createSut(
            labelID: Message.Location.inbox.rawValue,
            labelType: .folder,
            isCustom: false,
            labelName: nil
        )
        wait(self.sut.diffableDataSource?.snapshot().itemIdentifiers.count == unreadMessages.count + readMessages.count + 1)


        /// When determining items to prefetch
        let itemsToPrefetch = sut.itemsToPrefetch()

        /// Unread messages should be first and in the same order (time + order)
        let messageEntities = itemsToPrefetch.allMessages
        XCTAssertEqual(messageEntities.prefix(unreadMessages.count).map(\.messageID.rawValue),
                       unreadMessages)
        XCTAssertEqual(messageEntities.dropFirst(unreadMessages.count).dropLast(1).map(\.messageID.rawValue),
                       readMessages)
        XCTAssertEqual(messageEntities.last?.messageID.rawValue, defaultMockMessage?.messageID)
    }
}

// MARK: Cancellation Reminder Modal Tests

extension MailboxViewModelTests {
    func testShouldShowReminderModal_noDataPassed_shouldReturnFalse() {
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.autoDowngradeReminder.rawValue: [:]])
        }
        XCTAssertFalse(sut.shouldShowReminderModal())
    }
    
    func testShouldShowReminderModal_defaultValuePassed_shouldReturnFalse() {
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.autoDowngradeReminder.rawValue: []])
        }
        XCTAssertFalse(sut.shouldShowReminderModal())
    }
    
    func testShouldShowReminderModal_allValuesAreEqualToTwo_shouldReturnFalse() {
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.autoDowngradeReminder.rawValue: ["day-45": 2, "day-30": 2]])
        }
        XCTAssertFalse(sut.shouldShowReminderModal())
    }
    
    func testShouldShowReminderModal_singleValueIsEqualsToOne_shouldReturnTrue() {
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.autoDowngradeReminder.rawValue: ["day-45": 2, "day-30": 1]])
        }
        XCTAssertTrue(sut.shouldShowReminderModal())
    }
    
    func testShouldShowReminderModal_multipleValuesAreEqualToOne_shouldReturnTrue() {
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.autoDowngradeReminder.rawValue: ["day-45": 1, "day-30": 1]])
        }
        XCTAssertTrue(sut.shouldShowReminderModal())
    }
    
    func testShouldShowReminderModal_allValuesAreEqualToZero_shouldReturnFalse() {
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.autoDowngradeReminder.rawValue: ["day-45": 0, "day-30": 0]])
        }
        XCTAssertFalse(sut.shouldShowReminderModal())
    }
    
    func testShouldShowReminderModal_valuesAreZeroOrOne_shouldReturnTrue() {
        featureFlagCache.featureFlagsStub.bodyIs { _, _ in
            SupportedFeatureFlags(rawValues: [FeatureFlagKey.autoDowngradeReminder.rawValue: ["day-45": 0, "day-30": 1]])
        }
        XCTAssertTrue(sut.shouldShowReminderModal())
    }
}

// MARK: notification authorization

extension MailboxViewModelTests {
    func testWhenNotificationAuthorizationStatusIsNotDeterminedAndHasntBeenRequestedBefore_thenShouldRequestAuthorization() async {
        userNotificationCenter.authorizationStatusStub.bodyIs { _ in
            UNAuthorizationStatus.notDetermined
        }

        let shouldRequestNotificationAuthorization = await sut.shouldRequestNotificationAuthorization()
        XCTAssert(shouldRequestNotificationAuthorization)
    }

    func testWhenNotificationAuthorizationStatusIsNotDeterminedButHasBeenRequestedBefore_thenShouldNotRequestAuthorization() async {
        sut.didRequestNotificationAuthorization()

        userNotificationCenter.authorizationStatusStub.bodyIs { _ in
            UNAuthorizationStatus.notDetermined
        }

        let shouldRequestNotificationAuthorization = await sut.shouldRequestNotificationAuthorization()
        XCTAssertFalse(shouldRequestNotificationAuthorization)
    }

    func testWhenNotificationAuthorizationStatusIsDeterminedAndTheRequestIsRecorded_thenShouldNotRequestAuthorization() async {
        sut.didRequestNotificationAuthorization()

        userNotificationCenter.authorizationStatusStub.bodyIs { _ in
            UNAuthorizationStatus.denied
        }

        let shouldRequestNotificationAuthorization = await sut.shouldRequestNotificationAuthorization()
        XCTAssertFalse(shouldRequestNotificationAuthorization)
    }

    func testWhenNotificationAuthorizationStatusIsDeterminedButTheRequestIsNotRecorded_thenShouldNotRequestAuthorization() async {
        userNotificationCenter.authorizationStatusStub.bodyIs { _ in
            UNAuthorizationStatus.denied
        }

        let shouldRequestNotificationAuthorization = await sut.shouldRequestNotificationAuthorization()
        XCTAssertFalse(shouldRequestNotificationAuthorization)
    }
}

extension MailboxViewModelTests {
    func loadTestMessage() throws -> Message {
        let parsedObject = testMessageMetaData.parseObjectAny()!
        let testMessage = try GRTJSONSerialization
            .object(withEntityName: "Message",
                    fromJSONDictionary: parsedObject,
                    in: testContext) as! Message
        testMessage.userID = "1"
        testMessage.messageStatus = 1
        try testContext.save()
        return testMessage
    }

    func createSut(labelID: String,
                   labelType: PMLabelType,
                   isCustom: Bool,
                   labelName: String?,
                   totalUserCount: Int = 1) {
        let fetchMessage = MockFetchMessages()
        let updateMailbox = UpdateMailbox(dependencies: .init(
            eventService: eventsServiceMock,
            messageDataService: userManagerMock.messageService,
            conversationProvider: conversationProviderMock,
            purgeOldMessages: MockPurgeOldMessages(),
            fetchMessageWithReset: fetchMessageWithReset,
            fetchMessage: fetchMessage,
            fetchLatestEventID: mockFetchLatestEventId,
            internetConnectionStatusProvider: MockInternetConnectionStatusProviderProtocol(),
            userDefaults: globalContainer.userDefaults
        ))
        self.mockFetchMessageDetail = MockFetchMessageDetail(stubbedResult: .failure(NSError.badResponse()))
        userManagerMock.container.updateMailboxFactory.register { updateMailbox }
        userManagerMock.container.fetchMessageDetailFactory.reset()
        userManagerMock.container.fetchMessageDetailFactory.register { self.mockFetchMessageDetail }

        let label = LabelInfo(name: labelName ?? "")
        sut = MailboxViewModel(labelID: LabelID(labelID),
                               label: isCustom ? label : nil,
                               userManager: userManagerMock,
                               coreDataContextProvider: coreDataService,
                               lastUpdatedStore: MockLastUpdatedStoreProtocol(),
                               conversationStateProvider: conversationStateProviderMock,
                               contactGroupProvider: contactGroupProviderMock,
                               labelProvider: labelProviderMock,
                               contactProvider: contactProviderMock,
                               conversationProvider: conversationProviderMock,
                               eventsService: eventsServiceMock,
                               dependencies: userManagerMock.container,
                               toolbarActionProvider: toolbarActionProviderMock,
                               saveToolbarActionUseCase: saveToolbarActionUseCaseMock,
                               totalUserCountClosure: {
            return totalUserCount
        })
        delegateMock = .init(viewModel: sut)
        sut.setupDiffableDataSource(tableView: fakeTableView) { _, _, _ in return .init()}
        sut.setupFetchController(delegateMock)
        wait({
            var fetched = false
            self.sut.fetchedResultsController?.managedObjectContext.performAndWait {
                fetched = self.sut.fetchedResultsController?.fetchedObjects != nil
            }
            return fetched
        }())
    }

    func setupConversations(labelID: String, count: Int, unread: Bool) throws -> [String] {
        return try coreDataService.write { context in
            (0..<count).map { currentIndex in
                let conversation = Conversation(context: context)
                conversation.conversationID = UUID().uuidString
                conversation.userID = self.userManagerMock.userID.rawValue

                let contextLabel = ContextLabel(context: context)
                contextLabel.labelID = labelID
                contextLabel.conversation = conversation
                contextLabel.userID = self.userManagerMock.userID.rawValue
                contextLabel.unreadCount = unread ? 1 : 0
                contextLabel.conversationID = conversation.conversationID
                /// Time is monotously decreasing to simulate inserting from newest to oldest, to facilitate order testing
                contextLabel.time = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - Double(currentIndex))
                return conversation.conversationID
            }
        }
    }

    func setupMessages(labelID: String, count: Int, unread: Bool) throws -> [String] {
        return try coreDataService.write(block: { context in
            (0..<count).map { currentIndex in
                let message = Message(context: context)
                message.messageID = UUID().uuidString
                message.userID = self.userManagerMock.userID.rawValue
                message.messageStatus = 1
                message.unRead = unread
                message.add(labelID: labelID)
                /// Time is monotously decreasing to simulate inserting from newest to oldest, to facilitate order testing
                message.time = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - Double(currentIndex))
                return message.messageID
            }
        })
    }
}

final class MockCoreDataDelegateObject: NSObject, NSFetchedResultsControllerDelegate {
    let viewModel: MailboxViewModel

    init(viewModel: MailboxViewModel) {
        self.viewModel = viewModel
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let remappedSnapshot = remapToNewSnapshot(controller: controller, snapshot: snapshot)
        viewModel.diffableDataSource?.reloadSnapshot(
            snapshot: remappedSnapshot,
            completion: nil
        )
    }

    private func remapToNewSnapshot(controller: NSFetchedResultsController<NSFetchRequestResult>, snapshot: NSDiffableDataSourceSnapshotReference) -> NSDiffableDataSourceSnapshot<Int, MailboxRow> {
        let viewMode = viewModel.locationViewMode
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        var newSnapshot = NSDiffableDataSourceSnapshot<Int, MailboxRow>()
        for (index, section) in snapshot.sectionIdentifiers.enumerated() {
            let items = snapshot.itemIdentifiers(inSection: section)
            let mailboxRows = items.compactMap { objectID in
                let object = controller.managedObjectContext.object(with: objectID)
                switch viewMode {
                case .singleMessage:
                    if let message = object as? Message {
                        return MailboxRow.real(.message(.init(message)))
                    }
                case .conversation:
                    if let contextLabel = object as? ContextLabel,
                       let conversation = contextLabel.conversation {
                        return MailboxRow.real(.conversation(.init(conversation)))
                    }
                }
                return nil
            }

            newSnapshot.appendSections([index])
            newSnapshot.appendItems(mailboxRows, toSection: index)
        }
        return newSnapshot
    }
}

private extension MailboxItem {
    var toConversation: ConversationEntity? {
        switch self {
        case .conversation(let entity):
            return entity
        case .message:
            return nil
        }
    }

    var toMessage: MessageEntity? {
        switch self {
        case .conversation:
            return nil
        case .message(let entity):
            return entity
        }
    }

    var isConversation: Bool {
        toConversation != nil
    }

    var isMessage: Bool {
        toMessage != nil
    }
}

private extension Collection where Element == MailboxItem {
    var areAllConversations: Bool {
        allSatisfy { $0.isConversation }
    }

    var areAllMessages: Bool {
        allSatisfy { $0.isMessage }
    }

    var allConversations: [ConversationEntity] {
        compactMap { $0.toConversation }
    }

    var allMessages: [MessageEntity] {
        compactMap { $0.toMessage }
    }
}
