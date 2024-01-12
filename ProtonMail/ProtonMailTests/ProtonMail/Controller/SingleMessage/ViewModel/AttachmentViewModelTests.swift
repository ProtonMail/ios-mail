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
    private var subscriptions: Set<AnyCancellable>!

    var sut: AttachmentViewModel!
    var testAttachments: [AttachmentInfo] = []

    private let icsMimeType = "text/calendar"

    private let stubbedEventDetails = EventDetails(
        title: "Team Collaboration Workshop",
        startDate: .distantPast,
        endDate: .distantFuture,
        calendar: .init(
            name: "General",
            iconColor: "#FF0000"
        ),
        location: .init(
            name: "Zoom call"
        ),
        participants: [
            .init(email: "aubrey.thompson@proton.me", isOrganizer: true, status: .attending),
            .init(email: "eric.norbert@proton.me", isOrganizer: false, status: .attending)
        ], 
        calendarAppDeepLink: URL(string: UUID().uuidString)!
    )

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

        let fetchAttachmentMetadata = MockFetchAttachmentMetadataUseCase()
        fetchAttachmentMetadata.executionStub.bodyIs { _, _ in
            AttachmentMetadata(id: "", keyPacket: "")
        }

        let fetchAttachment = MockFetchAttachment()
        fetchAttachment.result = .success(
            AttachmentFile(attachmentId: "", fileUrl: URL(fileURLWithPath: ""), data: Data())
        )

        eventRSVP = .init()
        eventRSVP.parseDataStub.bodyIs { _, _ in
            self.stubbedEventDetails
        }

        user.container.reset()
        user.container.eventRSVPFactory.register { self.eventRSVP }
        user.container.fetchAttachmentMetadataFactory.register { fetchAttachmentMetadata }
        user.container.fetchAttachmentFactory.register { fetchAttachment }

        sut = AttachmentViewModel(dependencies: user.container)
    }

    override func tearDown() {
        super.tearDown()

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

        wait(self.eventRSVP.parseDataStub.callCounter == 1)

        let inlineICS = makeAttachment(isInline: true, mimeType: icsMimeType)
        sut.attachmentHasChanged(nonInlineAttachments: [inlineICS], mimeAttachments: [])

        wait(self.eventRSVP.parseDataStub.callCounter == 2)

        let mimeICS = MimeAttachment(filename: "", size: 0, mime: icsMimeType, path: nil, disposition: nil)
        sut.attachmentHasChanged(nonInlineAttachments: [], mimeAttachments: [mimeICS])

        wait(self.eventRSVP.parseDataStub.callCounter == 3)

        let nonICS = makeAttachment(isInline: false)
        sut.attachmentHasChanged(nonInlineAttachments: [nonICS], mimeAttachments: [])

        wait(self.eventRSVP.parseDataStub.callCounter == 3)
    }

    func testGivenICSIsAttached_whenCalledMultipleTimesInQuickSuccession_doesntParseMultipleTimes() {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)

        for _ in 0...3 {
            sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])
        }

        wait(self.eventRSVP.parseDataStub.callCounter == 1)
    }

    func testWhenICSIsFound_notifiesAboutProcessingProgress() {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)
        var receivedStates: [AttachmentViewModel.InvitationViewState] = []

        sut.invitationViewState
            .sink { value in
                receivedStates.append(value)
            }
            .store(in: &subscriptions)

        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])

        let expectedStates: [AttachmentViewModel.InvitationViewState] = [
            .noInvitationFound, .invitationFoundAndProcessing, .invitationProcessed(stubbedEventDetails)
        ]
        wait(receivedStates == expectedStates)
    }

    func testOpenInCalendar_whenCalendarIsInstalled_opensCalendarInsteadOfAppStore() async {
        urlOpener.openAsyncStub.bodyIs { _, url, _ in
            true
        }

        await sut.onOpenInCalendarTapped(deepLink: stubbedEventDetails.calendarAppDeepLink)

        XCTAssertEqual(urlOpener.openAsyncStub.lastArguments?.a1, stubbedEventDetails.calendarAppDeepLink)
        XCTAssertEqual(urlOpener.openAsyncStub.callCounter, 1)
    }

    func testOpenInCalendar_whenCalendarIsNotInstalled_opensAppStorePage() async {
        urlOpener.openAsyncStub.bodyIs { _, url, _ in
            url == .AppStore.calendar
        }

        await sut.onOpenInCalendarTapped(deepLink: stubbedEventDetails.calendarAppDeepLink)

        XCTAssertEqual(urlOpener.openAsyncStub.lastArguments?.a1, .AppStore.calendar)
        XCTAssertEqual(urlOpener.openAsyncStub.callCounter, 2)
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
