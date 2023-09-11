// Copyright (c) 2023 Proton Technologies AG
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

import CoreData
import Groot
import ProtonCore_DataModel
import ProtonCore_Networking
import ProtonCore_TestingToolkit
import ProtonCore_UIFoundations
@testable import ProtonMail
import XCTest

final class MailboxViewControllerTests: XCTestCase {
    var sut: MailboxViewController!
    var viewModel: MailboxViewModel!
    var coordinator: MailboxCoordinator!

    var userID: UserID!
    var apiServiceMock: APIServiceMock!
    var coreDataService: CoreDataService!
    var userManagerMock: UserManager!
    var conversationStateProviderMock: MockConversationStateProviderProtocol!
    var contactGroupProviderMock: MockContactGroupsProviderProtocol!
    var labelProviderMock: MockLabelProviderProtocol!
    var contactProviderMock: MockContactProvider!
    var conversationProviderMock: MockConversationProvider!
    var eventsServiceMock: EventsServiceMock!
    var mockFetchLatestEventId: MockFetchLatestEventId!
    var welcomeCarrouselCache: WelcomeCarrouselCacheMock!
    var toolbarActionProviderMock: MockToolbarActionProvider!
    var saveToolbarActionUseCaseMock: MockSaveToolbarActionSettingsForUsersUseCase!
    var mockFetchMessageDetail: MockFetchMessageDetail!
    var fakeCoordinator: MockMailboxCoordinatorProtocol!

    var testContext: NSManagedObjectContext {
        coreDataService.mainContext
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        userID = .init(String.randomString(20))
        coreDataService = CoreDataService(container: MockCoreDataStore.testPersistentContainer)
        sharedServices.add(CoreDataService.self, for: coreDataService)

        apiServiceMock = APIServiceMock()
        apiServiceMock.sessionUIDStub.fixture = String.randomString(10)
        apiServiceMock.dohInterfaceStub.fixture = DohMock()
        let fakeAuth = AuthCredential(sessionID: "",
                                      accessToken: "",
                                      refreshToken: "",
                                      userName: "",
                                      userID: userID.rawValue,
                                      privateKey: nil,
                                      passwordKeySalt: nil)
        let stubUserInfo = UserInfo(maxSpace: nil,
                                    usedSpace: nil,
                                    language: nil,
                                    maxUpload: nil,
                                    role: nil,
                                    delinquent: nil,
                                    keys: nil,
                                    userId: userID.rawValue,
                                    linkConfirmation: nil,
                                    credit: nil,
                                    currency: nil,
                                    subscribed: nil)
        userManagerMock = UserManager(api: apiServiceMock,
                                      userInfo: stubUserInfo,
                                      authCredential: fakeAuth,
                                      mailSettings: nil,
                                      parent: nil,
                                      coreKeyMaker: MockKeyMakerProtocol())
        userManagerMock.conversationStateService.userInfoHasChanged(viewMode: .singleMessage)
        conversationStateProviderMock = MockConversationStateProviderProtocol()
        contactGroupProviderMock = MockContactGroupsProviderProtocol()
        labelProviderMock = MockLabelProviderProtocol()
        contactProviderMock = MockContactProvider(coreDataContextProvider: coreDataService)
        conversationProviderMock = MockConversationProvider()
        eventsServiceMock = EventsServiceMock()
        mockFetchLatestEventId = MockFetchLatestEventId()
        welcomeCarrouselCache = WelcomeCarrouselCacheMock()
        toolbarActionProviderMock = MockToolbarActionProvider()
        saveToolbarActionUseCaseMock = MockSaveToolbarActionSettingsForUsersUseCase()
        try loadTestMessage() // one message

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
        fakeCoordinator = .init()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        sut = nil
        viewModel = nil
        contactGroupProviderMock = nil
        contactProviderMock = nil
        coreDataService = nil
        eventsServiceMock = nil
        userManagerMock = nil
        mockFetchLatestEventId = nil
        toolbarActionProviderMock = nil
        saveToolbarActionUseCaseMock = nil
        apiServiceMock = nil
    }

    func testTitle_whenChangeCustomLabelName_titleWillBeUpdatedAccordingly() {
        let labelID = LabelID(String.randomString(20))
        let labelName = String.randomString(20)
        let labelNewName = String.randomString(20)
        coreDataService.performAndWaitOnRootSavingContext { context in
            let label = Label(context: context)
            label.labelID = labelID.rawValue
            label.name = labelName
            label.userID = self.userManagerMock.userID.rawValue
            _ = context.saveUpstreamIfNeeded()
        }
        makeSUT(
            labelID: labelID,
            labelType: .label,
            isCustom: true,
            labelName: labelName
        )
        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.title, labelName)

        // Change the label name
        coreDataService.performAndWaitOnRootSavingContext { context in
            let label = Label.labelForLabelID(labelID.rawValue, inManagedObjectContext: context)
            XCTAssertNotNil(label)
            label?.name = labelNewName
            _ = context.saveUpstreamIfNeeded()
        }

        wait(self.sut.title == labelNewName)
    }

    func testLastUpdateLabel_eventUpdateTimeIsNow_titleIsUpdateJustNow() {
        let labelID = Message.Location.inbox.labelID
        coreDataService.performAndWaitOnRootSavingContext { context in
            let event = UserEvent(context: context)
            event.userID = self.userManagerMock.userID.rawValue
            event.updateTime = Date()
            event.eventID = String.randomString(10)
        }
        makeSUT(
            labelID: labelID,
            labelType: .label,
            isCustom: false,
            labelName: nil
        )
        sut.loadViewIfNeeded()

        XCTAssertEqual(
            sut.updateTimeLabel.text,
            LocalString._mailblox_last_update_time_just_now
        )
    }

    func testLastUpdateLabel_eventUpdateTimeIs30MinsBefore_titleIsLastUpdateIn30Mins() {
        let labelID = Message.Location.inbox.labelID
        coreDataService.performAndWaitOnRootSavingContext { context in
            let event = UserEvent(context: context)
            event.userID = self.userManagerMock.userID.rawValue
            let date = Date().add(.minute, value: -30)
            event.updateTime = date
            event.eventID = String.randomString(10)
        }
        makeSUT(
            labelID: labelID,
            labelType: .label,
            isCustom: false,
            labelName: nil
        )
        sut.loadViewIfNeeded()

        XCTAssertEqual(
            sut.updateTimeLabel.text,
            String.localizedStringWithFormat(LocalString._mailblox_last_update_time, 30)
        )
    }

    func testLastUpdateLabel_eventUpdateTimeIs1HourBefore_titleIsUpdateMoreThan1Hour() {
        let labelID = Message.Location.inbox.labelID
        coreDataService.performAndWaitOnRootSavingContext { context in
            let event = UserEvent(context: context)
            event.userID = self.userManagerMock.userID.rawValue
            let date = Date().add(.hour, value: -1)
            event.updateTime = date
            event.eventID = String.randomString(10)
        }
        makeSUT(
            labelID: labelID,
            labelType: .label,
            isCustom: false,
            labelName: nil
        )
        sut.loadViewIfNeeded()

        XCTAssertEqual(
            sut.updateTimeLabel.text,
            LocalString._mailblox_last_update_time_more_than_1_hour
        )
    }

    func testSelectionMode_whenPullToRefresh_selectionModeWillBeDisable() {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        makeSUT(
            labelID: Message.Location.inbox.labelID,
            labelType: .folder,
            isCustom: false,
            labelName: nil
        )
        sut.loadViewIfNeeded()
        XCTAssertFalse(sut.tableView.visibleCells.isEmpty)

        // Select cell
        let cell = sut.tableView.visibleCells.first as? NewMailboxMessageCell
        cell?.customView.leftContainer.sendActions(for: .touchUpInside)
        XCTAssertEqual(viewModel.selectedIDs.count, 1)
        XCTAssertTrue(viewModel.listEditing)

        // Pull to refresh
        let refreshControl = sut.tableView.subviews
            .compactMap({ $0 as? UIRefreshControl }).first
        refreshControl?.sendActions(for: .valueChanged)

        // Selection mode is disabled
        XCTAssertTrue(viewModel.selectedIDs.isEmpty)
        XCTAssertFalse(viewModel.listEditing)
    }

    func testUnreadButton_whenUnreadCountIsZeroAtFirst_inConversationMode_unreadIsSetToBe1_unreadButtonShouldBeShown() {
        let labelID = LabelID(String.randomString(20))
        coreDataService.performAndWaitOnRootSavingContext { context in
            let count = ConversationCount(context: context)
            count.userID = self.userID.rawValue
            count.labelID = labelID.rawValue
            count.unread = 0
            _ = context.saveUpstreamIfNeeded()
        }
        makeSUT(
            labelID: labelID,
            labelType: .folder,
            isCustom: false,
            labelName: nil
        )
        sut.loadViewIfNeeded()

        XCTAssertTrue(sut.unreadFilterButton.isHidden)

        coreDataService.performAndWaitOnRootSavingContext { context in
            let count = ConversationCount.fetchConversationCounts(
                by: [labelID.rawValue],
                userID: self.userID.rawValue,
                context: context
            ).first
            count?.unread = 1
            _ = context.saveUpstreamIfNeeded()
        }

        wait(self.sut.unreadFilterButton.isHidden == false)
        XCTAssertEqual(sut.unreadFilterButton.titleLabel?.text, "1 \(LocalString._unread_action) ")
    }

    func testUnreadButton_whenUnreadCountIsZeroAtFirst_inMessageMode_unreadIsSetToBe1_unreadButtonShouldBeShown() {
        let labelID = LabelID(String.randomString(20))
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        coreDataService.performAndWaitOnRootSavingContext { context in
            let count = LabelUpdate(context: context)
            count.userID = self.userID.rawValue
            count.labelID = labelID.rawValue
            count.unread = 0
            _ = context.saveUpstreamIfNeeded()
        }
        makeSUT(
            labelID: labelID,
            labelType: .folder,
            isCustom: false,
            labelName: nil
        )
        sut.loadViewIfNeeded()

        XCTAssertTrue(sut.unreadFilterButton.isHidden)

        coreDataService.performAndWaitOnRootSavingContext { context in
            let count = LabelUpdate.fetchLastUpdates(
                by: [labelID.rawValue],
                userID: self.userID.rawValue,
                context: context
            ).first
            count?.unread = 1
            _ = context.saveUpstreamIfNeeded()
        }

        wait(self.sut.unreadFilterButton.isHidden == false)
        XCTAssertEqual(sut.unreadFilterButton.titleLabel?.text, "1 \(LocalString._unread_action) ")
    }

    func testUnreadButton_whenUnreadCountIsMoreThan9999_uneradButtonTitleIsSetToBePlus9999() {
        let labelID = LabelID(String.randomString(20))
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        coreDataService.performAndWaitOnRootSavingContext { context in
            let count = LabelUpdate(context: context)
            count.userID = self.userID.rawValue
            count.labelID = labelID.rawValue
            count.unread = 100000
            _ = context.saveUpstreamIfNeeded()
        }
        makeSUT(
            labelID: labelID,
            labelType: .folder,
            isCustom: false,
            labelName: nil
        )
        sut.loadViewIfNeeded()

        XCTAssertFalse(sut.unreadFilterButton.isHidden)
        XCTAssertEqual(sut.unreadFilterButton.titleLabel?.text, " +9999 \(LocalString._unread_action) ")
    }

    func testUnreadButton_whenClickTheUnreadButton_selectionModeWillBeCancelled() throws {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        makeSUT(labelID: .init("0"), labelType: .folder, isCustom: false, labelName: nil)
        sut.loadViewIfNeeded()

        // Enter selection mode
        let cell = try XCTUnwrap(sut.tableView.visibleCells.first as? NewMailboxMessageCell)
        sut.didSelectButtonStatusChange(cell: cell)
        XCTAssertTrue(viewModel.listEditing)
        XCTAssertFalse(viewModel.selectedIDs.isEmpty)

        // Click unread button
        sut.unreadFilterButton.sendActions(for: .touchUpInside)

        XCTAssertFalse(viewModel.listEditing)
        XCTAssertEqual(viewModel.selectedIDs, [])
    }
}

extension MailboxViewControllerTests {
    private func loadTestMessage() throws {
        let parsedObject = testMessageMetaData.parseObjectAny()!
        let testMessage = try GRTJSONSerialization
            .object(withEntityName: "Message",
                    fromJSONDictionary: parsedObject,
                    in: testContext) as? Message
        testMessage?.userID = userID.rawValue
        testMessage?.messageStatus = 1
        try testContext.save()
    }

    private func makeSUT(
        labelID: LabelID,
        labelType: PMLabelType,
        isCustom: Bool,
        labelName: String?,
        totalUserCount: Int = 1
    ) {
        let globalContainer = GlobalContainer()
        let userContainer = UserContainer(userManager: userManagerMock, globalContainer: globalContainer)

        let fetchMessage = MockFetchMessages()
        let updateMailbox = UpdateMailbox(dependencies: .init(
            labelID: labelID,
            eventService: eventsServiceMock,
            messageDataService: userManagerMock.messageService,
            conversationProvider: conversationProviderMock,
            purgeOldMessages: MockPurgeOldMessages(),
            fetchMessageWithReset: MockFetchMessagesWithReset(),
            fetchMessage: fetchMessage,
            fetchLatestEventID: mockFetchLatestEventId
        ))
        self.mockFetchMessageDetail = MockFetchMessageDetail(stubbedResult: .failure(NSError.badResponse()))

        let dependencies = MailboxViewModel.Dependencies(
            fetchMessages: MockFetchMessages(),
            updateMailbox: updateMailbox,
            fetchMessageDetail: mockFetchMessageDetail,
            fetchSenderImage: FetchSenderImage(
                dependencies: .init(
                    featureFlagCache: MockFeatureFlagCache(),
                    senderImageService: .init(
                        dependencies: .init(
                            apiService: userManagerMock.apiService,
                            internetStatusProvider: MockInternetConnectionStatusProviderProtocol()
                        )
                    ),
                    mailSettings: userManagerMock.mailSettings
                )
            )
        )
        let label = LabelInfo(name: labelName ?? "")
        viewModel = MailboxViewModel(
            labelID: labelID,
            label: isCustom ? label : nil,
            labelType: labelType,
            userManager: userManagerMock,
            pushService: MockPushNotificationService(),
            coreDataContextProvider: coreDataService,
            lastUpdatedStore: MockLastUpdatedStoreProtocol(),
            conversationStateProvider: conversationStateProviderMock,
            contactGroupProvider: contactGroupProviderMock,
            labelProvider: labelProviderMock,
            contactProvider: contactProviderMock,
            conversationProvider: conversationProviderMock,
            eventsService: eventsServiceMock,
            dependencies: dependencies,
            welcomeCarrouselCache: welcomeCarrouselCache,
            toolbarActionProvider: toolbarActionProviderMock,
            saveToolbarActionUseCase: saveToolbarActionUseCaseMock,
            totalUserCountClosure: {
                totalUserCount
            }
        )

        sut = .init(viewModel: viewModel, dependencies: userContainer)
        sut.set(coordinator: fakeCoordinator)
    }
}
