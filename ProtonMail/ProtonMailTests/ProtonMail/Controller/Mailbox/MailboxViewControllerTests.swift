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
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreTestingToolkitUnitTestsDoh
import ProtonCoreTestingToolkitUnitTestsServices
import ProtonCoreUIFoundations
@testable import ProtonMail
import protocol ProtonCoreServices.APIService
import XCTest

final class MailboxViewControllerTests: XCTestCase {
    var sut: MailboxViewController!
    var viewModel: MailboxViewModel!
    var coordinator: MailboxCoordinator!

    var userID: UserID!
    var apiServiceMock: APIServiceMock!
    var userManagerMock: UserManager!
    var conversationStateProviderMock: MockConversationStateProviderProtocol!
    var contactGroupProviderMock: MockContactGroupsProviderProtocol!
    var labelProviderMock: MockLabelProviderProtocol!
    var contactProviderMock: MockContactProvider!
    var conversationProviderMock: MockConversationProvider!
    var eventsServiceMock: EventsServiceMock!
    var mockFetchLatestEventId: MockFetchLatestEventId!
    var toolbarActionProviderMock: MockToolbarActionProvider!
    var saveToolbarActionUseCaseMock: MockSaveToolbarActionSettingsForUsersUseCase!
    var fakeCoordinator: MockMailboxCoordinatorProtocol!

    private var testContainer: TestContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()

        userID = .init(String.randomString(20))

        testContainer = .init()

        apiServiceMock = APIServiceMock()
        apiServiceMock.sessionUIDStub.fixture = String.randomString(10)
        apiServiceMock.dohInterfaceStub.fixture = DohMock()
        userManagerMock = try UserManager.prepareUser(
            apiMock: apiServiceMock,
            userID: userID,
            globalContainer: testContainer
        )
        testContainer.usersManager.add(newUser: userManagerMock)
        userManagerMock.conversationStateService.userInfoHasChanged(viewMode: .singleMessage)
        conversationStateProviderMock = MockConversationStateProviderProtocol()
        contactGroupProviderMock = MockContactGroupsProviderProtocol()
        labelProviderMock = MockLabelProviderProtocol()
        contactProviderMock = MockContactProvider(coreDataContextProvider: testContainer.contextProvider)
        conversationProviderMock = MockConversationProvider()
        eventsServiceMock = EventsServiceMock()
        mockFetchLatestEventId = MockFetchLatestEventId()
        toolbarActionProviderMock = MockToolbarActionProvider()
        saveToolbarActionUseCaseMock = MockSaveToolbarActionSettingsForUsersUseCase()
        try loadTestMessage() // one message

        conversationProviderMock.fetchConversationStub.bodyIs { [unowned self] _, _, _, _, completion in
            self.testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
                completion(.success(Conversation(context: context)))
            }
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
        eventsServiceMock = nil
        userManagerMock = nil
        mockFetchLatestEventId = nil
        toolbarActionProviderMock = nil
        saveToolbarActionUseCaseMock = nil
        apiServiceMock = nil
        testContainer = nil
    }

    func testTitle_whenChangeCustomLabelName_titleWillBeUpdatedAccordingly() {
        let labelID = LabelID(String.randomString(20))
        let labelName = String.randomString(20)
        let labelNewName = String.randomString(20)
        testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
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
        testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
            let label = Label.labelForLabelID(labelID.rawValue, inManagedObjectContext: context)
            XCTAssertNotNil(label)
            label?.name = labelNewName
            _ = context.saveUpstreamIfNeeded()
        }

        wait(self.sut.title == labelNewName)
    }

    func testLastUpdateLabel_eventUpdateTimeIsNow_titleIsUpdateJustNow() {
        let labelID = Message.Location.inbox.labelID
        let lastUpdateKey = UserSpecificLabelKey(labelID: labelID, userID: userID)
        testContainer.userDefaults[.mailboxLastUpdateTimes][lastUpdateKey.userDefaultsKey] = Date()

        makeSUT(
            labelID: labelID,
            labelType: .label,
            isCustom: false,
            labelName: nil
        )
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.updateTimeLabel.text, "Updated just now")
    }

    func testLastUpdateLabel_eventUpdateTimeIs30MinsBefore_titleIsLastUpdateIn30Mins() {
        let labelID = Message.Location.inbox.labelID
        let lastUpdateKey = UserSpecificLabelKey(labelID: labelID, userID: userID)
        testContainer.userDefaults[.mailboxLastUpdateTimes][lastUpdateKey.userDefaultsKey] = Date().add(.minute, value: -30)

        makeSUT(
            labelID: labelID,
            labelType: .label,
            isCustom: false,
            labelName: nil
        )

        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.updateTimeLabel.text, "Updated 30 mins ago")
    }

    func testLastUpdateLabel_eventUpdateTimeIs1HourBefore_titleIsUpdateMoreThan1Hour() {
        let labelID = Message.Location.inbox.labelID
        let lastUpdateKey = UserSpecificLabelKey(labelID: labelID, userID: userID)
        testContainer.userDefaults[.mailboxLastUpdateTimes][lastUpdateKey.userDefaultsKey] = Date().add(.hour, value: -1)

        makeSUT(
            labelID: labelID,
            labelType: .label,
            isCustom: false,
            labelName: nil
        )

        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.updateTimeLabel.text, "Updated >1 hour ago")
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

        wait(!self.sut.tableView.visibleCells.isEmpty)

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
        testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
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

        testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
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
        testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
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

        testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
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
        testContainer.contextProvider.performAndWaitOnRootSavingContext { context in
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

        wait(self.sut.unreadFilterButton.isHidden == false)
        XCTAssertEqual(sut.unreadFilterButton.titleLabel?.text, " +9999 \(LocalString._unread_action) ")
    }

    func testUnreadButton_whenClickTheUnreadButton_selectionModeWillBeCancelled() throws {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        makeSUT(labelID: .init("0"), labelType: .folder, isCustom: false, labelName: nil)
        sut.loadViewIfNeeded()

        wait(self.sut.tableView.visibleCells.isEmpty == false)

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

    func testMessagesOrdering_inSnoozeFolder_snoozeMessagesAreSortedCorrectly() throws {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        makeSUT(labelID: Message.Location.snooze.labelID, labelType: .folder, isCustom: false, labelName: nil)
        try testContainer.contextProvider.write { context in
            let label = Label(context: context)
            label.labelID = Message.Location.snooze.rawValue
            let message1 = Message(context: context)
            message1.userID = self.userID.rawValue
            message1.messageStatus = .init(value: 1)
            message1.add(labelID: Message.Location.snooze.rawValue)
            message1.snoozeTime = Date(timeIntervalSince1970: 5000)
            message1.sender = """
            {
                "Name": "name",
                "Address": "test@pm.me"
            }
            """

            let message2 = Message(context: context)
            message2.userID = self.userID.rawValue
            message2.messageStatus = .init(value: 1)
            message2.add(labelID: Message.Location.snooze.rawValue)
            message2.snoozeTime = Date(timeIntervalSince1970: 7000)
            message2.sender = """
            {
                "Name": "name",
                "Address": "test@pm.me"
            }
            """
        }
        sut.loadViewIfNeeded()

        wait(self.sut.tableView.visibleCells.count == 2)

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [NewMailboxMessageCell])
        let firstCell = try XCTUnwrap(cells.first)
        XCTAssertEqual(
            firstCell.customView.messageContentView.snoozeTimeLabel.text,
            PMDateFormatter.shared.stringForSnoozeTime(from: Date(timeIntervalSince1970: 5000))
        )

        let secondCell = try XCTUnwrap(cells[safe: 1])
        XCTAssertEqual(
            secondCell.customView.messageContentView.snoozeTimeLabel.text,
            PMDateFormatter.shared.stringForSnoozeTime(from: Date(timeIntervalSince1970: 7000))
        )
    }

    func testConversationsOrdering_inSnoozeFolder_snoozeConversationsAreSortedCorrectly() throws {
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        makeSUT(labelID: Message.Location.snooze.labelID, labelType: .folder, isCustom: false, labelName: nil)
        try testContainer.contextProvider.write { context in
            let conversation1 = Conversation(context: context)
            conversation1.userID = self.userID.rawValue
            conversation1.conversationID = String.randomString(20)
            conversation1.senders = """
                [{
                    "Name": "name",
                    "Address": "test@pm.me"
                }]
            """
            let contextLabel1 = ContextLabel(context: context)
            contextLabel1.userID = self.userID.rawValue
            contextLabel1.conversation = conversation1
            contextLabel1.labelID = Message.Location.snooze.rawValue
            contextLabel1.conversationID = conversation1.conversationID
            contextLabel1.snoozeTime = Date(timeIntervalSince1970: 5000)

            let conversation2 = Conversation(context: context)
            conversation2.userID = self.userID.rawValue
            conversation2.conversationID = String.randomString(20)
            conversation2.senders = """
                [{
                    "Name": "name",
                    "Address": "test@pm.me"
                }]
            """
            let contextLabel2 = ContextLabel(context: context)
            contextLabel2.userID = self.userID.rawValue
            contextLabel2.conversation = conversation2
            contextLabel2.labelID = Message.Location.snooze.rawValue
            contextLabel2.conversationID = conversation2.conversationID
            contextLabel2.snoozeTime = Date(timeIntervalSince1970: 7000)
        }
        sut.loadViewIfNeeded()

        wait(self.sut.tableView.visibleCells.count == 2)

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [NewMailboxMessageCell])
        let firstCell = try XCTUnwrap(cells.first)
        XCTAssertEqual(
            firstCell.customView.messageContentView.snoozeTimeLabel.text,
            PMDateFormatter.shared.stringForSnoozeTime(from: Date(timeIntervalSince1970: 5000))
        )

        let secondCell = try XCTUnwrap(cells[safe: 1])
        XCTAssertEqual(
            secondCell.customView.messageContentView.snoozeTimeLabel.text,
            PMDateFormatter.shared.stringForSnoozeTime(from: Date(timeIntervalSince1970: 7000))
        )
    }

    func testConversationOrdering_inInbox_poppedConversationAreSortedCorrectly() throws {
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        makeSUT(labelID: Message.Location.inbox.labelID, labelType: .folder, isCustom: false, labelName: nil)
        try testContainer.contextProvider.write { context in
            let conversation1 = Conversation(context: context)
            conversation1.userID = self.userID.rawValue
            conversation1.conversationID = String.randomString(20)
            conversation1.senders = """
                [{
                    "Name": "name",
                    "Address": "test@pm.me"
                }]
            """
            let contextLabel1 = ContextLabel(context: context)
            contextLabel1.userID = self.userID.rawValue
            contextLabel1.conversation = conversation1
            contextLabel1.labelID = Message.Location.inbox.rawValue
            contextLabel1.conversationID = conversation1.conversationID
            contextLabel1.time = Date(timeIntervalSince1970: 8000)

            let conversation2 = Conversation(context: context)
            conversation2.userID = self.userID.rawValue
            conversation2.conversationID = String.randomString(20)
            conversation2.senders = """
                [{
                    "Name": "name",
                    "Address": "test@pm.me"
                }]
            """
            conversation2.displaySnoozedReminder = true
            let contextLabel2 = ContextLabel(context: context)
            contextLabel2.userID = self.userID.rawValue
            contextLabel2.conversation = conversation2
            contextLabel2.labelID = Message.Location.inbox.rawValue
            contextLabel2.conversationID = conversation2.conversationID
            contextLabel2.snoozeTime = Date(timeIntervalSince1970: 100000)
            contextLabel2.time = Date(timeIntervalSince1970: 7000)
        }
        sut.loadViewIfNeeded()

        wait(self.sut.tableView.visibleCells.count == 2)

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [NewMailboxMessageCell])
        let firstCell = try XCTUnwrap(cells.first)
        XCTAssertEqual(
            firstCell.customView.messageContentView.timeLabel.text,
            "January 02, 1970"
        )

        let secondCell = try XCTUnwrap(cells[safe: 1])
        XCTAssertEqual(
            secondCell.customView.messageContentView.timeLabel.text,
            "January 01, 1970"
        )
    }

    func testConversationOrdering_inAllMail_poppedConversationAreSortedCorrectly() throws {
        conversationStateProviderMock.viewModeStub.fixture = .conversation
        makeSUT(labelID: Message.Location.allmail.labelID, labelType: .folder, isCustom: false, labelName: nil)
        try testContainer.contextProvider.write { context in
            let conversation1 = Conversation(context: context)
            conversation1.userID = self.userID.rawValue
            conversation1.conversationID = String.randomString(20)
            conversation1.senders = """
                [{
                    "Name": "name",
                    "Address": "test@pm.me"
                }]
            """
            let contextLabel1 = ContextLabel(context: context)
            contextLabel1.userID = self.userID.rawValue
            contextLabel1.conversation = conversation1
            contextLabel1.labelID = Message.Location.allmail.rawValue
            contextLabel1.conversationID = conversation1.conversationID
            contextLabel1.time = Date(timeIntervalSince1970: 8000)
            let contextLabel11 = ContextLabel(context: context)
            contextLabel11.userID = self.userID.rawValue
            contextLabel11.conversation = conversation1
            contextLabel11.labelID = Message.Location.inbox.rawValue
            contextLabel11.conversationID = conversation1.conversationID
            contextLabel11.time = Date(timeIntervalSince1970: 8000)

            let conversation2 = Conversation(context: context)
            conversation2.userID = self.userID.rawValue
            conversation2.conversationID = String.randomString(20)
            conversation2.senders = """
                [{
                    "Name": "name",
                    "Address": "test@pm.me"
                }]
            """
            conversation2.displaySnoozedReminder = true
            let contextLabel2 = ContextLabel(context: context)
            contextLabel2.userID = self.userID.rawValue
            contextLabel2.conversation = conversation2
            contextLabel2.labelID = Message.Location.allmail.rawValue
            contextLabel2.conversationID = conversation2.conversationID
            contextLabel2.snoozeTime = Date(timeIntervalSince1970: 7000)
            contextLabel2.time = Date(timeIntervalSince1970: 7000)
            let contextLabel22 = ContextLabel(context: context)
            contextLabel22.userID = self.userID.rawValue
            contextLabel22.conversation = conversation2
            contextLabel22.labelID = Message.Location.inbox.rawValue
            contextLabel22.conversationID = conversation2.conversationID
            contextLabel22.snoozeTime = Date(timeIntervalSince1970: 100000)
            contextLabel22.time = Date(timeIntervalSince1970: 7000)
        }
        sut.loadViewIfNeeded()

        wait(self.sut.tableView.visibleCells.count == 2)

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [NewMailboxMessageCell])
        let firstCell = try XCTUnwrap(cells.first)
        XCTAssertEqual(
            firstCell.mailboxItem?.time(labelID: Message.Location.allmail.labelID),
            Date(timeIntervalSince1970: 8000)
        )
        XCTAssertEqual(
            firstCell.customView.messageContentView.timeLabel.text,
            "January 01, 1970"
        )

        let secondCell = try XCTUnwrap(cells[safe: 1])
        XCTAssertEqual(
            secondCell.customView.messageContentView.timeLabel.text,
            "January 02, 1970"
        )
    }

    func testMessagesOrdering_inInboxFolder_poppedMessagesAreSortedCorrectly() throws {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        makeSUT(labelID: Message.Location.inbox.labelID, labelType: .folder, isCustom: false, labelName: nil)
        try testContainer.contextProvider.write { context in
            let label = Label(context: context)
            label.labelID = Message.Location.inbox.rawValue
            let message1 = Message(context: context)
            message1.userID = self.userID.rawValue
            message1.messageStatus = .init(value: 1)
            message1.add(labelID: Message.Location.inbox.rawValue)
            message1.snoozeTime = Date(timeIntervalSince1970: 8000000)
            message1.time = Date(timeIntervalSince1970: 7000000)
            message1.flag.insert(.showReminder)
            message1.sender = """
            {
                "Name": "name",
                "Address": "test@pm.me"
            }
            """

            let message2 = Message(context: context)
            message2.userID = self.userID.rawValue
            message2.messageStatus = .init(value: 1)
            message2.add(labelID: Message.Location.inbox.rawValue)
            message2.time = Date(timeIntervalSince1970: 7000000)
            message2.sender = """
            {
                "Name": "name",
                "Address": "test@pm.me"
            }
            """
        }
        sut.loadViewIfNeeded()

        wait(self.sut.tableView.visibleCells.count == 3)

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [NewMailboxMessageCell])
        let firstCell = try XCTUnwrap(cells.first)
        XCTAssertEqual(
            firstCell.mailboxItem?.time(labelID: Message.Location.inbox.labelID),
            Date(timeIntervalSince1970: 7000000)
        )
        XCTAssertEqual(
            firstCell.customView.messageContentView.timeLabel.text,
            "April 03, 1970"
        )

        let secondCell = try XCTUnwrap(cells[safe: 1])
        XCTAssertEqual(
            secondCell.mailboxItem?.time(labelID: Message.Location.inbox.labelID),
            Date(timeIntervalSince1970: 7000000)
        )
        XCTAssertEqual(
            secondCell.customView.messageContentView.timeLabel.text,
            "March 23, 1970"
        )
    }

    func testMessagesOrdering_inAllMailFolder_poppedMessagesAreSortedCorrectly() throws {
        conversationStateProviderMock.viewModeStub.fixture = .singleMessage
        makeSUT(labelID: Message.Location.allmail.labelID, labelType: .folder, isCustom: false, labelName: nil)
        try testContainer.contextProvider.write { context in
            let label = Label(context: context)
            label.labelID = Message.Location.allmail.rawValue
            let message1 = Message(context: context)
            message1.userID = self.userID.rawValue
            message1.messageStatus = .init(value: 1)
            message1.add(labelID: Message.Location.allmail.rawValue)
            message1.snoozeTime = Date(timeIntervalSince1970: 8000000)
            message1.time = Date(timeIntervalSince1970: 7000001)
            message1.flag.insert(.showReminder)
            message1.sender = """
            {
                "Name": "name",
                "Address": "test@pm.me"
            }
            """

            let message2 = Message(context: context)
            message2.userID = self.userID.rawValue
            message2.messageStatus = .init(value: 1)
            message2.add(labelID: Message.Location.allmail.rawValue)
            message2.time = Date(timeIntervalSince1970: 7000000)
            message2.sender = """
            {
                "Name": "name",
                "Address": "test@pm.me"
            }
            """
        }
        sut.loadViewIfNeeded()

        wait(self.sut.tableView.visibleCells.count == 3)

        let cells = try XCTUnwrap(sut.tableView.visibleCells as? [NewMailboxMessageCell])
        let firstCell = try XCTUnwrap(cells.first)
        XCTAssertEqual(
            firstCell.mailboxItem?.time(labelID: Message.Location.allmail.labelID),
            Date(timeIntervalSince1970: 7000001)
        )
        XCTAssertEqual(
            firstCell.customView.messageContentView.timeLabel.text,
            "April 03, 1970"
        )

        let secondCell = try XCTUnwrap(cells[safe: 1])
        XCTAssertEqual(
            secondCell.mailboxItem?.time(labelID: Message.Location.allmail.labelID),
            Date(timeIntervalSince1970: 7000000)
        )
        XCTAssertEqual(
            secondCell.customView.messageContentView.timeLabel.text,
            "March 23, 1970"
        )
    }
}

extension MailboxViewControllerTests {
    private func loadTestMessage() throws {
        try testContainer.contextProvider.write { context in
            let parsedObject = testMessageMetaData.parseObjectAny()!
            let testMessage = try GRTJSONSerialization.object(
                withEntityName: "Message",
                fromJSONDictionary: parsedObject,
                in: context
            ) as? Message
            testMessage?.userID = self.userID.rawValue
            testMessage?.messageStatus = 1
        }
    }

    private func makeSUT(
        labelID: LabelID,
        labelType: PMLabelType,
        isCustom: Bool,
        labelName: String?,
        totalUserCount: Int = 1
    ) {
        let userContainer = UserContainer(userManager: userManagerMock, globalContainer: testContainer)
        testContainer.usersManager.add(newUser: userManagerMock)

        let label = LabelInfo(name: labelName ?? "")
        viewModel = MailboxViewModel(
            labelID: labelID,
            label: isCustom ? label : nil,
            userManager: userManagerMock,
            coreDataContextProvider: testContainer.contextProvider,
            lastUpdatedStore: MockLastUpdatedStoreProtocol(),
            conversationStateProvider: conversationStateProviderMock,
            contactGroupProvider: contactGroupProviderMock,
            labelProvider: labelProviderMock,
            contactProvider: contactProviderMock,
            conversationProvider: conversationProviderMock,
            eventsService: eventsServiceMock,
            dependencies: userContainer,
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

extension MockMailboxCoordinatorProtocol: SnoozeSupport {
    func presentPaymentView() { }

    var conversationDataService: ConversationDataServiceProxy {
        let fakeUser = UserManager(api: APIServiceMock())
        return fakeUser.container.conversationService
    }

    var calendar: Calendar { LocaleEnvironment.calendar }

    var isPaidUser: Bool { false }

    var presentingView: UIView { UIView() }

    var snoozeConversations: [ProtonMail.ConversationID] { [] }

    var snoozeDateConfigReceiver: ProtonMail.SnoozeDateConfigReceiver {
        SnoozeDateConfigReceiver { _ in

        } cancelHandler: {

        } showSendInTheFutureAlertHandler: {

        }
    }
    
    var weekStart: ProtonMail.WeekStart { .monday }

    func showSnoozeSuccessBanner(on date: Date) { }
}
