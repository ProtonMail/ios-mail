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

import Combine
import ProtonCoreTestingToolkit
import XCTest
@testable import ProtonMail

class AttachmentViewModelTests: XCTestCase {
    private var urlOpener: MockURLOpener!
    private var user: UserManager!
    private var eventRSVP: MockEventRSVP!
    private var receivedRespondingStatuses: AsyncPublisher<AnyPublisher<AttachmentViewModel.RespondingStatus, Never>>.Iterator!
    private var subscriptions: Set<AnyCancellable>!

    var sut: AttachmentViewModel!
    var testAttachments: [AttachmentInfo] = []

    private let icsMimeType = "text/calendar"

    private let stubbedBasicEventInfo = BasicEventInfo(eventUID: "foo", recurrenceID: nil)

    private let stubbedEventDetails = EventDetails.make()

    override func setUp() {
        super.setUp()

        subscriptions = []

        urlOpener = MockURLOpener()

        let testContainer = TestContainer()

        testContainer.urlOpenerFactory.register { self.urlOpener }

        let apiService = APIServiceMock()
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success([:]))
        }

        user = UserManager(api: apiService, globalContainer: testContainer)
        user.userInfo.userAddresses.append(.dummy.updated(email: stubbedEventDetails.invitees[0].email))

        let fetchAttachmentMetadata = MockFetchAttachmentMetadataUseCase()
        fetchAttachmentMetadata.executionStub.bodyIs { _, _ in
            AttachmentMetadata(id: "", keyPacket: "")
        }

        let fetchAttachment = MockFetchAttachment()
        fetchAttachment.result = .success(
            AttachmentFile(attachmentId: "", fileUrl: URL(fileURLWithPath: ""), data: Data())
        )

        eventRSVP = .init()
        eventRSVP.extractBasicEventInfoStub.bodyIs { _, _ in
            self.stubbedBasicEventInfo
        }
        eventRSVP.fetchEventDetailsStub.bodyIs { _, _ in
            self.stubbedEventDetails
        }

        user.container.reset()
        user.container.eventRSVPFactory.register { self.eventRSVP }
        user.container.fetchAttachmentMetadataFactory.register { fetchAttachmentMetadata }
        user.container.fetchAttachmentFactory.register { fetchAttachment }

        sut = AttachmentViewModel(dependencies: user.container)
        receivedRespondingStatuses = sut.respondingStatus.values.makeAsyncIterator()
    }

    override func tearDown() {
        super.tearDown()

        receivedRespondingStatuses = nil
        subscriptions = nil
        testAttachments.removeAll()

        sut = nil
        urlOpener = nil
        user = nil
        eventRSVP = nil
    }

    func testInit_withNonInlineAttachments_realAttachmentIsFalse_addAllAttachments() {
        for _ in 0..<10 {
            testAttachments.append(makeAttachment(isInline: false))
        }

        sut.attachmentHasChanged(nonInlineAttachments: testAttachments, mimeAttachments: [])

        XCTAssertEqual(sut.attachments.count, testAttachments.count)
        XCTAssertEqual(sut.numberOfAttachments, testAttachments.count)
    }

    func testGetTotalSizeOfAllAttachments() {
        for _ in 0..<10 {
            testAttachments.append(makeAttachment(isInline: true))
        }

        sut.attachmentHasChanged(nonInlineAttachments: testAttachments, mimeAttachments: [])

        let expected = testAttachments.reduce(into: 0, { $0 = $0 + $1.size })
        XCTAssertEqual(sut.totalSizeOfAllAttachments, expected)
    }

    func testAddMimeAttachment() {
        let attachment = MimeAttachment(filename: String.randomString(10), size: 10, mime: "", path: nil, disposition: nil)
        let expectation1 = expectation(description: "closure is called")

        sut.reloadView = {
            expectation1.fulfill()
        }

        sut.attachmentHasChanged(nonInlineAttachments: [], mimeAttachments: [attachment])
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(sut.numberOfAttachments, 1)
    }

    func testAddMimeAttachment_AddDuplicateItem() {
        let attachment = MimeAttachment(filename: String.randomString(10), size: 10, mime: "", path: nil, disposition: nil)
        let expectation1 = expectation(description: "closure is called")

        sut.reloadView = {
            expectation1.fulfill()
        }

        sut.attachmentHasChanged(nonInlineAttachments: [], mimeAttachments: [attachment, attachment])
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(sut.numberOfAttachments, 1)
    }

    func testNumberOfAttachments_NonInLineAttachmentIsNil_returnsTheAttachmentCount() {
        for _ in 0..<10 {
            testAttachments.append(makeAttachment(isInline: false))
        }

        sut.attachmentHasChanged(nonInlineAttachments: testAttachments, mimeAttachments: [])

        XCTAssertEqual(sut.attachments.count, testAttachments.count)
        XCTAssertEqual(sut.numberOfAttachments, 10)
    }

    // MARK: RSVP

    func testGivenICSIsAttached_regardlessOfFormat_submitsICSForParsing() {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)
        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])

        wait(self.eventRSVP.extractBasicEventInfoStub.callCounter == 1)

        let inlineICS = makeAttachment(isInline: true, mimeType: icsMimeType)
        sut.attachmentHasChanged(nonInlineAttachments: [inlineICS], mimeAttachments: [])

        wait(self.eventRSVP.extractBasicEventInfoStub.callCounter == 2)

        let mimeICS = MimeAttachment(filename: "", size: 0, mime: icsMimeType, path: nil, disposition: nil)
        sut.attachmentHasChanged(nonInlineAttachments: [], mimeAttachments: [mimeICS])

        wait(self.eventRSVP.extractBasicEventInfoStub.callCounter == 3)

        let nonICS = makeAttachment(isInline: false)
        sut.attachmentHasChanged(nonInlineAttachments: [nonICS], mimeAttachments: [])

        wait(self.eventRSVP.extractBasicEventInfoStub.callCounter == 3)
    }

    func testGivenICSIsAttached_whenCalledMultipleTimesInQuickSuccession_doesntParseMultipleTimes() {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)

        for _ in 0...3 {
            sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])
        }

        wait(self.eventRSVP.extractBasicEventInfoStub.callCounter == 1)
    }

    func testWhenICSIsFound_notifiesAboutProcessingProgress() async {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)
        var receivedInvitationViewStates = sut.invitationViewState.values.makeAsyncIterator()

        await receivedInvitationViewStates.expectNextValue(toBe: .noInvitationFound)

        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])

        await receivedInvitationViewStates.expectNextValue(toBe: .invitationFoundAndProcessing)
        await receivedInvitationViewStates.expectNextValue(toBe: .invitationProcessed(stubbedEventDetails))
    }

    func testGivenHeadersContainEventInfo_whenAttachmentsContainICS_doesntParseICS() {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)

        sut.basicEventInfoSourcedFromHeaders = stubbedBasicEventInfo
        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])

        wait(self.eventRSVP.fetchEventDetailsStub.callCounter == 1)
        XCTAssertEqual(eventRSVP.extractBasicEventInfoStub.callCounter, 0)
    }

    func testRespondingStatus_whenAnsweringAndChangingAnswer_showsProcessingAndThenTheSelectedAnswerEachTime() async {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)

        await receivedRespondingStatuses.expectNextValue(toBe: .respondingUnavailable)

        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])

        await receivedRespondingStatuses.expectNextValue(toBe: .awaitingUserInput)

        sut.respondToInvitation(with: .yes)

        await receivedRespondingStatuses.expectNextValue(toBe: .responseIsBeingProcessed)
        await receivedRespondingStatuses.expectNextValue(toBe: .alreadyResponded(.yes))

        sut.respondToInvitation(with: .maybe)

        await receivedRespondingStatuses.expectNextValue(toBe: .responseIsBeingProcessed)
        await receivedRespondingStatuses.expectNextValue(toBe: .alreadyResponded(.maybe))
    }

    func testRespondingStatus_whenAnsweringFails_revertsToPreviousValue() async {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)

        eventRSVP.respondToInvitationStub.bodyIs { _, _ in
            throw NSError.badResponse()
        }

        await receivedRespondingStatuses.expectNextValue(toBe: .respondingUnavailable)

        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])

        await receivedRespondingStatuses.expectNextValue(toBe: .awaitingUserInput)

        sut.respondToInvitation(with: .yes)

        await receivedRespondingStatuses.expectNextValue(toBe: .responseIsBeingProcessed)
        await receivedRespondingStatuses.expectNextValue(toBe: .awaitingUserInput)
    }

    func testResponding_whenUserIsNotAnInvitee_isNotAvailable() async {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)

        user.userInfo.userAddresses[0] = user.userInfo.userAddresses[0]
            .updated(email: "somethingOtherThanInvitee@example.com")

        var receivedStates: [AttachmentViewModel.RespondingStatus] = []

        sut.respondingStatus
            .sink { value in
                receivedStates.append(value)
            }
            .store(in: &subscriptions)

        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])

        await sleep(milliseconds: 50)

        XCTAssertEqual(receivedStates, [.respondingUnavailable])
    }

    func testOpenInCalendar_whenRecentCalendarIsInstalled_directlyOpensCalendar() {
        let deepLink = stubbedEventDetails.calendarAppDeepLink

        urlOpener.canOpenURLStub.bodyIs { _, url in
            url == deepLink
        }

        let instruction = sut.instructionToHandle(deepLink: deepLink)
        XCTAssertEqual(instruction, .openDeepLink(deepLink))
    }

    func testOpenInCalendar_whenOutdatedCalendarIsInstalled_promptsToOpenAppStorePage() {
        urlOpener.canOpenURLStub.bodyIs { _, url in
            url == .ProtonCalendar.legacyScheme
        }

        let instruction = sut.instructionToHandle(deepLink: stubbedEventDetails.calendarAppDeepLink)
        XCTAssertEqual(instruction, .goToAppStore(askBeforeGoing: true))
    }

    func testOpenInCalendar_whenBothCalendarsAreInstalled_directlyOpensCalendar() {
        urlOpener.canOpenURLStub.bodyIs { _, url in
            true
        }

        let deepLink = stubbedEventDetails.calendarAppDeepLink
        let instruction = sut.instructionToHandle(deepLink: deepLink)
        XCTAssertEqual(instruction, .openDeepLink(deepLink))
    }

    func testOpenInCalendar_whenCalendarIsNotInstalled_directlyOpensAppStorePage() {
        urlOpener.canOpenURLStub.bodyIs { _, url in
            false
        }

        let instruction = sut.instructionToHandle(deepLink: stubbedEventDetails.calendarAppDeepLink)
        XCTAssertEqual(instruction, .goToAppStore(askBeforeGoing: false))
    }

    private func makeAttachment(isInline: Bool, mimeType: String = "text/plain") -> AttachmentInfo {
        return AttachmentInfo(
            fileName: String.randomString(50),
            size: 99,
            mimeType: mimeType,
            localUrl: nil,
            isDownloaded: true,
            id: "",
            isInline: isInline,
            objectID: nil,
            contentID: nil,
            order: -1
        )
    }
}
