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
    var mockSenderImageStatusProvider: MockSenderImageStatusProvider!
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
        mockSenderImageStatusProvider = .init()
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

        conversationProviderMock.labelStub.bodyIs { _, _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.markAsReadStub.bodyIs { _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.markAsUnreadStub.bodyIs { _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.moveStub.bodyIs { _, _, _, _, _, _, completion in
            completion?(.success(()))
        }

        conversationProviderMock.unlabelStub.bodyIs { _, _, _, _, completion in
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
        mockSenderImageStatusProvider = nil
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

        let e = expectation(description: "Closure is called")
        // Give CoreData some time to update the UI.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            // Check if the title is updated
            XCTAssertEqual(self.sut.title, labelNewName)
            e.fulfill()
        }
        waitForExpectations(timeout: 3)
    }
}

extension MailboxViewControllerTests {
    private func loadTestMessage() throws {
        let parsedObject = testMessageMetaData.parseObjectAny()!
        let testMessage = try GRTJSONSerialization
            .object(withEntityName: "Message",
                    fromJSONDictionary: parsedObject,
                    in: testContext) as? Message
        testMessage?.userID = "1"
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
        sut = .init()
        let fetchMessage = MockFetchMessages()
        let updateMailbox = UpdateMailbox(dependencies: .init(
            eventService: eventsServiceMock,
            messageDataService: userManagerMock.messageService,
            conversationProvider: conversationProviderMock,
            purgeOldMessages: MockPurgeOldMessages(),
            fetchMessageWithReset: MockFetchMessagesWithReset(),
            fetchMessage: fetchMessage,
            fetchLatestEventID: mockFetchLatestEventId
        ), parameters: .init(labelID: labelID))
        self.mockFetchMessageDetail = MockFetchMessageDetail(stubbedResult: .failure(NSError.badResponse()))

        let dependencies = MailboxViewModel.Dependencies(
            fetchMessages: MockFetchMessages(),
            updateMailbox: updateMailbox,
            fetchMessageDetail: mockFetchMessageDetail,
            fetchSenderImage: FetchSenderImage(
                dependencies: .init(
                    senderImageService: .init(
                        dependencies: .init(
                            apiService: userManagerMock.apiService,
                            internetStatusProvider: MockInternetConnectionStatusProviderProtocol()
                        )
                    ),
                    senderImageStatusProvider: mockSenderImageStatusProvider,
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
            senderImageService: .init(dependencies: .init(apiService: userManagerMock.apiService, internetStatusProvider: MockInternetConnectionStatusProviderProtocol())),
            totalUserCountClosure: {
                totalUserCount
            }
        )
        sut.set(viewModel: viewModel)
        sut.set(coordinator: fakeCoordinator)
    }
}
