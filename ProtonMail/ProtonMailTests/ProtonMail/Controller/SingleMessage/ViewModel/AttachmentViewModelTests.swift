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

import ProtonCoreTestingToolkitUnitTestsServices
import XCTest
@testable import ProtonMail

class AttachmentViewModelTests: XCTestCase {
    private var answerInvitation: MockAnswerInvitation!
    private var extractBasicEventInfo: MockExtractBasicEventInfo!
    private var fetchAttachment: MockFetchAttachment!
    private var fetchAttachmentMetadata: MockFetchAttachmentMetadataUseCase!
    private var fetchEventDetails: MockFetchEventDetails!
    private var featureFlagProvider: MockFeatureFlagProvider!
    private var urlOpener: MockURLOpener!
    private var user: UserManager!
    private var receivedRespondingStatuses: EmittedValuesObserver<AttachmentViewModel.RespondingStatus>!
    private var receivedErrors: EmittedValuesObserver<Error>!

    var sut: AttachmentViewModel!
    var testAttachments: [AttachmentInfo] = []

    private var isCalendarLandingPageEnabled: Bool!

    private let icsMimeType = "text/calendar"

    private let stubbedBasicEventInfo = BasicEventInfo.inviteDataFromICS(eventUID: "foo", recurrenceID: nil)

    private var stubbedEventDetails: EventDetails!

    override func setUp() {
        super.setUp()

        urlOpener = MockURLOpener()

        let testContainer = TestContainer()

        testContainer.urlOpenerFactory.register { self.urlOpener }

        let apiService = APIServiceMock()
        apiService.requestJSONStub.bodyIs { _, _, path, _, _, _, _, _, _, _, _, _, completion in
            completion(nil, .success([:]))
        }

        featureFlagProvider = .init()
        featureFlagProvider.isEnabledStub.bodyIs { [unowned self] _, flag in
            switch flag {
            case .calendarMiniLandingPage:
                return self.isCalendarLandingPageEnabled
            default:
                return true
            }
        }

        stubbedEventDetails = .make(
            currentUserAmongInvitees: .init(email: "employee1@example.com", role: .unknown, status: .pending)
        )

        user = UserManager(api: apiService, globalContainer: testContainer)

        answerInvitation = .init()

        fetchAttachmentMetadata = .init()
        fetchAttachmentMetadata.executionStub.bodyIs { _, _ in
            AttachmentMetadata(keyPacket: "")
        }

        fetchAttachment = .init()
        fetchAttachment.result = .success(
            AttachmentFile(attachmentId: "", fileUrl: URL(fileURLWithPath: ""), data: Data())
        )

        extractBasicEventInfo = .init()
        extractBasicEventInfo.executeStub.bodyIs { _, _ in
            self.stubbedBasicEventInfo
        }

        fetchEventDetails = .init()
        fetchEventDetails.executeStub.bodyIs { _, _ in
            (self.stubbedEventDetails, nil)
        }

        user.container.reset()
        user.container.answerInvitationFactory.register { self.answerInvitation }
        user.container.extractBasicEventInfoFactory.register { self.extractBasicEventInfo }
        user.container.featureFlagProviderFactory.register { self.featureFlagProvider }
        user.container.fetchAttachmentMetadataFactory.register { self.fetchAttachmentMetadata }
        user.container.fetchAttachmentFactory.register { self.fetchAttachment }
        user.container.fetchEventDetailsFactory.register { self.fetchEventDetails }

        sut = AttachmentViewModel(dependencies: user.container)
        receivedRespondingStatuses = .init(observing: sut.respondingStatus)
        receivedErrors = .init(observing: sut.error)
    }

    override func tearDown() {
        super.tearDown()

        receivedRespondingStatuses = nil
        receivedErrors = nil
        testAttachments.removeAll()
        stubbedEventDetails = nil

        sut = nil
        answerInvitation = nil
        extractBasicEventInfo = nil
        featureFlagProvider = nil
        fetchAttachment = nil
        fetchAttachmentMetadata = nil
        fetchEventDetails = nil
        urlOpener = nil
        user = nil
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

        wait(self.extractBasicEventInfo.executeStub.callCounter == 1)

        let inlineICS = makeAttachment(isInline: true, mimeType: icsMimeType)
        sut.attachmentHasChanged(nonInlineAttachments: [inlineICS], mimeAttachments: [])

        wait(self.extractBasicEventInfo.executeStub.callCounter == 2)

        let mimeICS = MimeAttachment(filename: "", size: 0, mime: icsMimeType, path: nil, disposition: nil)
        sut.attachmentHasChanged(nonInlineAttachments: [], mimeAttachments: [mimeICS])

        wait(self.extractBasicEventInfo.executeStub.callCounter == 3)

        let nonICS = makeAttachment(isInline: false)
        sut.attachmentHasChanged(nonInlineAttachments: [nonICS], mimeAttachments: [])

        wait(self.extractBasicEventInfo.executeStub.callCounter == 3)
    }

    func testGivenICSIsAttached_whenCalledMultipleTimesInQuickSuccession_doesntParseMultipleTimes() {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)

        for _ in 0...3 {
            sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])
        }

        wait(self.extractBasicEventInfo.executeStub.callCounter == 1)
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

        wait(self.fetchEventDetails.executeStub.callCounter == 1)
        XCTAssertEqual(extractBasicEventInfo.executeStub.callCounter, 0)
    }

    func testGivenHeadersContainEventInfo_whenThereAreNoAttachments_thenShowsViewRegardless() async {
        await receivedRespondingStatuses.expectNextValue(toBe: .respondingUnavailable)

        sut.basicEventInfoSourcedFromHeaders = stubbedBasicEventInfo
        sut.attachmentHasChanged(nonInlineAttachments: [], mimeAttachments: [])

        await receivedRespondingStatuses.expectNextValue(toBe: .awaitingUserInput)

        XCTAssert(sut.viewShouldBeShown)
    }

    func testGivenICSIsCachedLocally_whenLoadingData_doesNotPerformNetworkRequests() {
        let icsData = Data("foo".utf8)
        let icsFile = SecureTemporaryFile(data: icsData, name: "ics.ics")
        let ics = makeAttachment(isInline: false, localUrl: icsFile.url, mimeType: icsMimeType)

        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])
        wait(self.extractBasicEventInfo.executeStub.wasCalled)

        XCTAssert(fetchAttachmentMetadata.executionStub.wasNotCalled)
        XCTAssert(fetchAttachment.executionBlock.wasNotCalled)
    }

    // MARK: RSVP - Responding status

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

    func testRespondingStatus_whenAnsweringFails_revertsToPreviousValueAndPublisherError() async throws {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)
        let stubbedError = NSError.badResponse()

        answerInvitation.executeStub.bodyIs { _, _ in
            throw stubbedError
        }

        await receivedRespondingStatuses.expectNextValue(toBe: .respondingUnavailable)

        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])

        await receivedRespondingStatuses.expectNextValue(toBe: .awaitingUserInput)

        sut.respondToInvitation(with: .yes)

        await receivedRespondingStatuses.expectNextValue(toBe: .responseIsBeingProcessed)
        await receivedRespondingStatuses.expectNextValue(toBe: .awaitingUserInput)

        let receivedErrorOptional = await receivedErrors.next()
        let receivedError = try XCTUnwrap(receivedErrorOptional) as NSError

        switch receivedError {
        case stubbedError:
            break
        default:
            throw receivedError
        }
    }

    func testRespondingStatus_whenUserHasPreviouslyResponded_isReflected() async {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)

        stubbedEventDetails = .make(
            currentUserAmongInvitees: .init(email: "employee1@example.com", role: .unknown, status: .accepted)
        )

        await receivedRespondingStatuses.expectNextValue(toBe: .respondingUnavailable)

        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])

        await receivedRespondingStatuses.expectNextValue(toBe: .alreadyResponded(.yes))
    }

    // MARK: RSVP: Cases where responding is unavailable

    func testResponding_whenUserIsNotAnInvitee_isNotAvailable() async {
        stubbedEventDetails = .make(currentUserAmongInvitees: nil)

        await ensureRespondingIsNotAvailableWhenICSIsReceived()
    }

    func testResponding_whenEventHasBeenCancelled_isNotAvailable() async {
        stubbedEventDetails = .make(
            currentUserAmongInvitees: stubbedEventDetails.currentUserAmongInvitees,
            status: .cancelled
        )

        await ensureRespondingIsNotAvailableWhenICSIsReceived()
    }

    private func ensureRespondingIsNotAvailableWhenICSIsReceived() async {
        let ics = makeAttachment(isInline: false, mimeType: icsMimeType)

        sut.attachmentHasChanged(nonInlineAttachments: [ics], mimeAttachments: [])

        await receivedRespondingStatuses.expectNextValue(toBe: .respondingUnavailable)
        await sleep(milliseconds: 50)
        XCTAssertFalse(receivedRespondingStatuses.hasPendingUnreadValues)
    }

    // MARK: RSVP: Open in Calendar

    func testOpenInCalendar_whenRecentCalendarIsInstalled_directlyOpensCalendar() {
        let deepLink = stubbedEventDetails.calendarAppDeepLink

        urlOpener.canOpenURLStub.bodyIs { _, url in
            url == deepLink
        }

        let instruction = sut.instructionToHandle(deepLink: deepLink)
        XCTAssertEqual(instruction, .openDeepLink(deepLink))
    }

    func testOpenInCalendar_whenOutdatedCalendarIsInstalled_promptsTheUserToUpdate() {
        urlOpener.canOpenURLStub.bodyIs { _, url in
            url == .ProtonCalendar.legacyScheme
        }

        let instruction = sut.instructionToHandle(deepLink: stubbedEventDetails.calendarAppDeepLink)
        XCTAssertEqual(instruction, .promptToUpdateCalendarApp)
    }

    func testOpenInCalendar_whenBothCalendarsAreInstalled_directlyOpensCalendar() {
        urlOpener.canOpenURLStub.bodyIs { _, url in
            true
        }

        let deepLink = stubbedEventDetails.calendarAppDeepLink
        let instruction = sut.instructionToHandle(deepLink: deepLink)
        XCTAssertEqual(instruction, .openDeepLink(deepLink))
    }

    func testOpenInCalendar_whenCalendarIsNotInstalledAndLandingPageIsDisabled_directlyOpensAppStorePage() {
        urlOpener.canOpenURLStub.bodyIs { _, url in
            false
        }

        isCalendarLandingPageEnabled = false

        let instruction = sut.instructionToHandle(deepLink: stubbedEventDetails.calendarAppDeepLink)
        XCTAssertEqual(instruction, .goToAppStoreDirectly)
    }

    func testOpenInCalendar_whenCalendarIsNotInstalledAndLandingPageIsEnabled_presentsCalendarLandingPage() {
        urlOpener.canOpenURLStub.bodyIs { _, url in
            false
        }

        isCalendarLandingPageEnabled = true

        let instruction = sut.instructionToHandle(deepLink: stubbedEventDetails.calendarAppDeepLink)
        XCTAssertEqual(instruction, .presentCalendarLandingPage)
    }

    private func makeAttachment(
        isInline: Bool,
        localUrl: URL? = nil,
        mimeType: String = "text/plain"
    ) -> AttachmentInfo {
        return AttachmentInfo(
            fileName: String.randomString(50),
            size: 99,
            mimeType: mimeType,
            localUrl: localUrl,
            isDownloaded: true,
            id: "",
            isInline: isInline,
            objectID: nil,
            contentID: nil,
            order: -1
        )
    }
}
