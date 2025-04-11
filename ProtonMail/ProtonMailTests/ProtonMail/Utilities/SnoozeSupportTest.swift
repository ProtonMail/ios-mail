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
import ProtonCoreUIFoundations
import ProtonCoreTestingToolkitUnitTestsServices
import XCTest
import protocol ProtonCoreServices.APIService
@testable import ProtonMail

final class SnoozeSupportTest: XCTestCase {
    private var sut: SnoozeMockObj!
    private var apiService: APIServiceMock!
    private var dateConfigReceiver: SnoozeDateConfigReceiver!
    private var user: UserManager!
    private var testContainer: TestContainer!
    private let snoozeAtDates: [Date] = [
        Date(timeIntervalSince1970: 1701649752), // Mon Dec 04 2023 00:29:12 GMT+0000
        Date(timeIntervalSince1970: 1701737338), // Tue Dec 05 2023 00:48:58 GMT+0000
        Date(timeIntervalSince1970: 1701823738), // Wed Dec 06 2023 00:48:58 GMT+0000
        Date(timeIntervalSince1970: 1701910138), // Thu Dec 07 2023 00:48:58 GMT+0000
        Date(timeIntervalSince1970: 1701996538), // Fri Dec 08 2023 00:48:58 GMT+0000
        Date(timeIntervalSince1970: 1702082938), // Sat Dec 09 2023 00:48:58 GMT+0000
        Date(timeIntervalSince1970: 1702169338)  // Sun Dec 10 2023 00:48:58 GMT+0000
    ]
    private let possibleCalendars = SnoozeSupportTest.calendars()
    private let userID = "tester"
    private let customFolderID = "customFolder"

    override func setUp() {
        super.setUp()
        apiService = APIServiceMock()
        testContainer = TestContainer()
        user = UserManager(api: apiService, userID: userID, globalContainer: testContainer)
        dateConfigReceiver = SnoozeDateConfigReceiver(saveDate: { _ in

        }, cancelHandler: {

        }, showSendInTheFutureAlertHandler: {

        })
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        apiService = nil
        dateConfigReceiver = nil
        user = nil
        testContainer = nil
    }

    func testSetUpTomorrow() {
        let expectedSnoozeUntilDateStrings: [String] = [
            "Tuesday 08:00",
            "Wednesday 08:00",
            "Thursday 08:00",
            "Friday 08:00",
            "Saturday 08:00",
            "Sunday 08:00",
            "Monday 08:00",
        ]
        for weekStart in WeekStart.allCases {
            for calendar in possibleCalendars {
                var expected = expectedSnoozeUntilDateStrings
                for date in snoozeAtDates {
                    initializeSUT(calendar: calendar, weekStart: weekStart)
                    let tomorrowAction = sut.setUpTomorrowAction(current: date)
                    guard
                        let components = tomorrowAction?.components.compactMap({ $0 as? PMActionSheetTextComponent }),
                        let dateComponent = components[safe: 1]
                    else {
                        XCTFail("Unexpected result")
                        return
                    }
                    switch dateComponent.text {
                    case .left(let dateStr):
                        XCTAssertEqual(dateStr, expected.remove(at: 0))
                    case .right(_):
                        XCTFail("Unexpected result")
                    }
                }
            }
        }
    }

    func testSetUpLatterThisWeek() {
        let expectedSnoozeUntilDateStrings: [String?] = [
            "Wednesday 08:00",
            "Thursday 08:00",
            "Friday 08:00",
            nil,
            "Sunday 08:00",
            nil,
            nil
        ]
        for weekStart in WeekStart.allCases {
            for calendar in possibleCalendars {
                initializeSUT(calendar: calendar, weekStart: weekStart)
                var expected = expectedSnoozeUntilDateStrings
                for date in snoozeAtDates {
                    let action = sut.setUpLaterThisWeek(current: date)
                    let expectedStr = expected.remove(at: 0)
                    if action == nil, expectedStr == nil {
                        continue
                    } else if action == nil, expectedStr != nil {
                        XCTFail("Should have action")
                        break
                    } else if let expectedStr,
                              let components = action?.components.compactMap({ $0 as? PMActionSheetTextComponent }),
                              let dateComponent = components[safe: 1] {
                        switch dateComponent.text {
                        case .left(let dateStr):
                            XCTAssertEqual(dateStr, expectedStr)
                        case .right(_):
                            XCTFail("Unexpected result")
                        }
                    }
                }
            }
        }

    }

    func testSetUpThisWeekend_whenWeekStartIsMonday() {
        var expectedSnoozeUntilDateStrings: [String?] = [
            "Saturday 08:00",
            "Saturday 08:00",
            "Saturday 08:00",
            "Saturday 08:00",
            nil,
            nil,
            nil
        ]
        initializeSUT(calendar: Self.calendar(weekStart: .monday), weekStart: .monday)
        for date in snoozeAtDates {
            let action = sut.setUpThisWeekend(current: date)
            let expectedStr = expectedSnoozeUntilDateStrings.remove(at: 0)
            if action == nil, expectedStr == nil {
                continue
            } else if action == nil, expectedStr != nil {
                XCTFail("Should have action")
                break
            } else if let expectedStr,
                      let components = action?.components.compactMap({ $0 as? PMActionSheetTextComponent }),
                      let dateComponent = components[safe: 1] {
                switch dateComponent.text {
                case .left(let dateStr):
                    XCTAssertEqual(dateStr, expectedStr)
                case .right(_):
                    XCTFail("Unexpected result")
                }
            }
        }
    }

    func testSetUpThisWeekend_whenWeekStartIsAutomatic() {
        let expectedSnoozeUntilDateStrings: [String?] = [
            "Saturday 08:00",
            "Saturday 08:00",
            "Saturday 08:00",
            "Saturday 08:00",
            nil,
            nil,
            nil
        ]

        for calendar in possibleCalendars {
            var expected = expectedSnoozeUntilDateStrings
            initializeSUT(calendar: calendar, weekStart: .automatic)
            for date in snoozeAtDates {
                let action = sut.setUpThisWeekend(current: date)
                if (calendar.firstWeekday == 1 || calendar.firstWeekday == 7) {
                    XCTAssertNil(action)
                    continue
                }
                let expectedStr = expected.remove(at: 0)
                if action == nil, expectedStr == nil {
                    continue
                } else if action == nil, expectedStr != nil {
                    XCTFail("Should have action")
                    break
                } else if let expectedStr,
                          let components = action?.components.compactMap({ $0 as? PMActionSheetTextComponent }),
                          let dateComponent = components[safe: 1] {
                    switch dateComponent.text {
                    case .left(let dateStr):
                        XCTAssertEqual(dateStr, expectedStr)
                    case .right(_):
                        XCTFail("Unexpected result")
                    }
                }
            }
        }
    }

    func testSetUpThisWeekend_whenWeekStartIsWeekend() {
        for weekStart in [WeekStart.saturday, WeekStart.sunday] {
            initializeSUT(calendar: Self.calendar(weekStart: .monday), weekStart: weekStart)
            for date in snoozeAtDates {
                XCTAssertNil(sut.setUpThisWeekend(current: date))
            }
        }
    }

    func testSetUpNextWeek_whenWeekStartIsNotAutomatic() {
        var expectedSnoozeUntilDateStrings = [
            "Monday 08:00",
            "Saturday 08:00",
            "Sunday 08:00"
        ]
        for weekday in [WeekStart.monday, WeekStart.saturday, WeekStart.sunday] {
            let expected = expectedSnoozeUntilDateStrings.remove(at: 0)
            initializeSUT(calendar: Self.calendar(weekStart: .monday), weekStart: weekday)
            for (index, date) in snoozeAtDates.enumerated() {
                let action = sut.setUpNextWeek(current: date)
                if index == 6 {
                    XCTAssertNil(action)
                    continue
                }
                guard
                    let components =  action?.components.compactMap({ $0 as? PMActionSheetTextComponent }),
                    let dateComponent = components[safe: 1]
                else {
                    XCTFail("Unexpected result")
                    return
                }
                switch dateComponent.text {
                case .left(let dateStr):
                    XCTAssertEqual(dateStr, expected)
                case .right(_):
                    XCTFail("Unexpected result")
                }
            }
        }
    }

    func testSetUpNextWeek_whenWeekStartIsAutomatic() {
        var expectedSnoozeUntilDateStrings = [
            "Monday 08:00",
            "Saturday 08:00",
            "Sunday 08:00"
        ]
        for calendar in possibleCalendars {
            let expected = expectedSnoozeUntilDateStrings.remove(at: 0)
            initializeSUT(calendar: calendar, weekStart: .automatic)
            for (index, date) in snoozeAtDates.enumerated() {
                let action = sut.setUpNextWeek(current: date)
                if index == 6 {
                    XCTAssertNil(action)
                    continue
                }
                guard
                    let components =  action?.components.compactMap({ $0 as? PMActionSheetTextComponent }),
                    let dateComponent = components[safe: 1]
                else {
                    XCTFail("Unexpected result")
                    return
                }
                switch dateComponent.text {
                case .left(let dateStr):
                    XCTAssertEqual(dateStr, expected)
                case .right(_):
                    XCTFail("Unexpected result")
                }
            }
        }
    }

    func testSnoozeOnDate_messageNotInInboxShouldNotBeAffected_othersShouldMoveToSnooze() throws {
        let conversationID = try mockConversationAndMessages()
        initializeSUT(calendar: possibleCalendars[0], weekStart: .sunday, snoozeConversations: [conversationID])

        let apiMockExpectation = expectation(description: "Interrupt API")
        let snoozeDate = Date(timeInterval: 3_000, since: Date())

        apiService.requestJSONStub.bodyIs { _, method, path, body, _, _, _, _, _, _, _, _, completion in
            XCTAssertEqual(method, .put)
            XCTAssertEqual(path, "/mail/v4/conversations/snooze")

            guard
                let dict = body as? [String: Any],
                let snoozeTime = dict["SnoozeTime"] as? Int,
                let ids = dict["IDs"] as? [String]
            else {
                XCTFail("Should contain a dictionary in body")
                return
            }
            XCTAssertEqual(snoozeTime, Int(snoozeDate.timeIntervalSince1970))
            XCTAssertEqual(ids, [conversationID.rawValue])
            completion(nil, .success(self.mockSnoozeSuccessResponse()))
            apiMockExpectation.fulfill()
        }
        let optimisticExpectation = expectation(description: "Local optimistic finish")
        sut.snooze(on: snoozeDate) {
            optimisticExpectation.fulfill()
        }
        wait(for: [optimisticExpectation])
        testContainer.contextProvider.read { context in
            guard let conversation = Conversation.conversationForConversationID(
                conversationID.rawValue,
                inManagedObjectContext: context
            ) else { return }
            guard let contextLabel = conversation.labels.compactMap({ $0 as? ContextLabel }).first else {
                XCTFail("Should have context")
                return
            }
            XCTAssertEqual(contextLabel.snoozeTime, snoozeDate)
            XCTAssertEqual(contextLabel.labelID, Message.Location.snooze.rawValue)

            guard
                let messages = Message.messagesForConversationID(
                    conversationID.rawValue,
                    inManagedObjectContext: context
                )
            else {
                XCTFail("Should have messages")
                return
            }
            for message in messages {
                guard let label = message.labels.compactMap({ $0 as? Label }).first else {
                    XCTFail("Should have label")
                    return
                }
                if message.messageID == self.customFolderID {
                    XCTAssertEqual(label.labelID, "customFolder")
                } else {
                    XCTAssertEqual(label.labelID, Message.Location.snooze.labelID.rawValue)
                }
            }
        }
        wait(for: [apiMockExpectation])
    }
}

extension SnoozeSupportTest {

    // Calendars has different week start
    private static func calendars() -> [Calendar] {
        return [
            calendar(weekStart: .monday),
            calendar(weekStart: .saturday),
            calendar(weekStart: .sunday)
        ]
    }

    private static func calendar(weekStart: WeekStart) -> Calendar {
        guard weekStart != .automatic else {
            XCTFail("Week start can't be automatic")
            return Calendar(identifier: .gregorian)
        }
        var calendar = Calendar(identifier: .gregorian)
        switch weekStart {

        case .automatic:
            XCTFail("Week start can't be automatic")
        case .monday:
            calendar.firstWeekday = 2
        case .sunday:
            calendar.firstWeekday = 1
        case .saturday:
            calendar.firstWeekday = 7
        }
        return calendar
    }

    /// - Parameters:
    ///   - calendar: Calendar will be used when user preferred week start is automatic
    ///   - weekStart: User preferred week start
    private func initializeSUT(calendar: Calendar, weekStart: WeekStart, snoozeConversations: [ConversationID] = []) {
        sut = .init(
            conversationDataService: user.conversationService,
            calendar: calendar,
            isPaidUser: false,
            presentingView: UIView(),
            snoozeConversations: snoozeConversations,
            snoozeDateConfigReceiver: dateConfigReceiver,
            weekStart: weekStart
        )
    }

    private func mockConversationAndMessages() throws -> ConversationID {
        var conversationID: ConversationID = ConversationID("")
        try testContainer.contextProvider.write { context in
            self.mockLabels(context: context)
            let conversation = self.mockConversation(context: context)
            conversationID = ConversationID(conversation.conversationID)
            let labelIDs = [
                Message.Location.inbox.rawValue,
                Message.Location.inbox.rawValue,
                Message.Location.inbox.rawValue,
                Message.Location.snooze.rawValue,
                self.customFolderID
            ]
            for id in labelIDs {
                _ = self.mockMessage(
                    context: context,
                    conversationID: conversation.conversationID,
                    labelID: id
                )
            }
        }
        return conversationID
    }

    private func mockConversation(context: NSManagedObjectContext) -> Conversation {
        let conversation = Conversation(context: context)
        conversation.conversationID = UUID().uuidString
        conversation.numMessages = 5

        let contextLabel = ContextLabel(context: context)
        contextLabel.labelID = Message.Location.inbox.labelID.rawValue
        contextLabel.conversation = conversation
        contextLabel.unreadCount = 0
        contextLabel.userID = userID
        contextLabel.conversationID = conversation.conversationID
        return conversation
    }

    private func mockMessage(context: NSManagedObjectContext, conversationID: String, labelID: String) -> Message {
        let testMessage = Message(context: context)
        testMessage.messageID = labelID == customFolderID ? customFolderID : UUID().uuidString
        testMessage.conversationID = conversationID
        testMessage.add(labelID: labelID)
        testMessage.messageStatus = 1
        testMessage.unRead = false
        testMessage.userID = userID
        return testMessage
    }

    private func mockLabels(context: NSManagedObjectContext) {
        let labelIDs = [
            Message.Location.inbox.rawValue,
            Message.Location.snooze.rawValue,
            customFolderID
        ]
        for id in labelIDs {
            let label = Label(context: context)
            label.labelID = id
            label.type = 3
        }
    }

    private func mockSnoozeSuccessResponse() -> [String: Any] {
        [
            "Code": 1001,
            "Responses": [
                [
                    "ID": "2SRhxOzFBr9M-g9QdVIN8u42bmxsD_gtbLTUBU70saPS51zPp5FN3jmkYsa4I5NG-Tls4LMGRid88_aM89qdjA==",
                    "Response": [
                        "Code": 1000
                    ]
                ]
            ]
        ]
    }
}

final class SnoozeMockObj: SnoozeSupport {
    func presentPaymentView() {}
    
    var conversationDataService: ConversationDataServiceProxy

    var calendar: Calendar

    var isPaidUser: Bool

    var presentingView: UIView

    var snoozeConversations: [ConversationID]

    var snoozeDateConfigReceiver: SnoozeDateConfigReceiver

    var weekStart: ProtonMail.WeekStart

    func showSnoozeSuccessBanner(on date: Date) {

    }

    init(
        conversationDataService: ConversationDataServiceProxy,
        calendar: Calendar,
        isPaidUser: Bool,
        presentingView: UIView,
        snoozeConversations: [ConversationID],
        snoozeDateConfigReceiver: ProtonMail.SnoozeDateConfigReceiver,
        weekStart: ProtonMail.WeekStart
    ) {
        self.conversationDataService = conversationDataService
        self.calendar = calendar
        self.isPaidUser = isPaidUser
        self.presentingView = presentingView
        self.snoozeConversations = snoozeConversations
        self.snoozeDateConfigReceiver = snoozeDateConfigReceiver
        self.weekStart = weekStart
    }
}
