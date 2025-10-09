// Copyright (c) 2024 Proton Technologies AG
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

@testable import InboxComposer
import proton_app_uniffi
import Testing

final class AttachmentErrorAlertStateTests {
    private var sut: AttachmentErrorAlertState!
    private static let timeStamp1: Int64 = 1743000520
    private static let timeStamp2: Int64 = 1743009702
    private static let timeStamp3: Int64 = 1743032002
    private let tooManyError1 = DraftAttachment.makeMock(id: 1, state: .error(.upload(.reason(.tooManyAttachments))), timestamp: timeStamp1)
    private let tooManyError2 = DraftAttachment.makeMock(id: 2, state: .error(.upload(.reason(.tooManyAttachments))), timestamp: timeStamp2)
    private let tooLargeError1 = DraftAttachment.makeMock(id: 3, state: .error(.upload(.reason(.attachmentTooLarge))), timestamp: timeStamp3)

    init() {
        sut = .init()
    }

    deinit {
        sut = nil
    }

    // MARK: enqueueAdditionErrors

    @Test
    func testEnqueueAdditionErrors_whenOneErrorPassed_itShouldPresentThePassedError() async {
        let error = DraftAttachmentUploadError.reason(.messageAlreadySent)

        await sut.enqueueAdditionErrors([error])

        let errorToPresent = await sut.errorToPresent
        let pendingErrorCount = await sut.queue.count
        #expect(errorToPresent?.title.string == L10n.AttachmentError.somethingWentWrongTitle.string)
        #expect(pendingErrorCount == 0)
    }

    @Test
    func testEnqueueAdditionErrors_whenTwoErrorsPassed_itShouldEnqueueTheSecond() async {
        let error1 = DraftAttachmentUploadError.reason(.attachmentTooLarge)
        let error2 = DraftAttachmentUploadError.reason(.tooManyAttachments)

        await sut.enqueueAdditionErrors([error1, error2])

        let errorToPresent = await sut.errorToPresent
        let pendingErrorCount = await sut.queue.count
        #expect(errorToPresent?.title.string == L10n.AttachmentError.attachmentsOverSizeLimitTitle.string)
        #expect(pendingErrorCount == 1)
    }

    @Test
    func testEnqueueAdditionErrors_whenSameErrorPassed_itShouldEnqueueTheSecondError() async {
        let error = DraftAttachmentUploadError.reason(.attachmentTooLarge)

        await sut.enqueueAdditionErrors([error])
        await sut.enqueueAdditionErrors([error])

        let errorToPresent = await sut.errorToPresent
        let pendingErrorCount = await sut.queue.count
        #expect(errorToPresent?.title.string == L10n.AttachmentError.attachmentsOverSizeLimitTitle.string)
        #expect(pendingErrorCount == 1)
    }

    // MARK: enqueueAnyUploadError

    @Test
    func testEnqueueAnyUploadError_whenNoErrorsPassed_itShouldNotEnqueueErrors() async {
        await sut.enqueueAnyUploadError([
            DraftAttachment.makeMock(state: .uploaded, timestamp: 1),
            DraftAttachment.makeMock(state: .pending, timestamp: 2),
        ])

        let errorToPresent = await sut.errorToPresent
        let pendingErrorCount = await sut.queue.count
        #expect(errorToPresent == nil)
        #expect(pendingErrorCount == 0)
    }

    @Test
    func testEnqueueAnyUploadError_whenMultipleErrorsOfTheSameType_itShouldAggregateTheErrors() async {
        await sut.enqueueAnyUploadError([tooManyError1, tooManyError2])

        let errorToPresent = await sut.errorToPresent
        let pendingErrorCount = await sut.queue.count
        #expect(errorToPresent?.title.string == L10n.AttachmentError.tooManyAttachmentsFromServerTitle.string)
        #expect(errorToPresent!.origin.isUploading == true)
        #expect(errorToPresent?.origin.errorCount == 2)
        #expect(pendingErrorCount == 0)
    }

    @Test
    func testEnqueueAnyUploadError_whenTwoErrorsOfDifferentTypes_itShouldEnqueueTheSecond() async {
        await sut.enqueueAnyUploadError([tooLargeError1, tooManyError1])

        let errorToPresent = await sut.errorToPresent
        let pendingErrorCount = await sut.queue.count
        #expect(errorToPresent?.title.string == L10n.AttachmentError.attachmentsOverSizeLimitTitle.string)
        #expect(errorToPresent?.origin.errorCount == 1)
        #expect(pendingErrorCount == 1)
    }

    @Test
    func testEnqueueAnyUploadError_whenErrorsOfDifferentTypesInConsecutiveCalls_itShouldEnqueueTheSecondError() async {
        await sut.enqueueAnyUploadError([tooLargeError1])
        await sut.enqueueAnyUploadError([tooManyError1])

        let errorToPresent = await sut.errorToPresent
        let pendingErrorCount = await sut.queue.count
        #expect(errorToPresent?.title.string == L10n.AttachmentError.attachmentsOverSizeLimitTitle.string)
        #expect(pendingErrorCount == 1)
    }

    @Test
    func testEnqueueAnyUploadError_whenSameErrorPassedInConsecutoveCalls_itShouldEnqueueSecondTime() async {
        await sut.enqueueAnyUploadError([tooManyError1])
        await sut.enqueueAnyUploadError([tooManyError1])

        let errorToPresent = await sut.errorToPresent
        let pendingErrorCount = await sut.queue.count
        #expect(errorToPresent?.title.string == L10n.AttachmentError.tooManyAttachmentsFromServerTitle.string)
        #expect(errorToPresent?.origin.errorCount == 1)
        #expect(pendingErrorCount == 0)
    }

    @Test
    func testEnqueueAnyUploadError_whenErrorIsHandledInAggregation_itShouldNotBeEnqueuedIfPassedIndividually() async {
        await sut.enqueueAnyUploadError([tooManyError1, tooManyError2])
        await sut.enqueueAnyUploadError([tooManyError2])

        let errorToPresent = await sut.errorToPresent
        let pendingErrorCount = await sut.queue.count
        #expect(errorToPresent?.title.string == L10n.AttachmentError.tooManyAttachmentsFromServerTitle.string)
        #expect(errorToPresent?.origin.errorCount == 2)
        #expect(pendingErrorCount == 0)
    }

    // MARK: nextErrorToPresent

    @Test
    func testNextErrorToPresent_whenThereIsAnErrorPresented_itShouldNotPresentTheNextOne() async {
        await sut.enqueueAnyUploadError([tooLargeError1, tooManyError1])
        let errorToPresent1 = await sut.errorToPresent
        #expect(errorToPresent1?.title.string == L10n.AttachmentError.attachmentsOverSizeLimitTitle.string)

        await sut.nextErrorToPresent()

        let errorToPresent2 = await sut.errorToPresent
        #expect(errorToPresent2?.title.string == L10n.AttachmentError.attachmentsOverSizeLimitTitle.string)
    }

    // MARK: errorDismissedShowNextError

    @Test
    func testErrorDismissedShowNextError_whenThereIsAnErrorPresented_itShouldNotPresentTheNextOne() async {
        await sut.enqueueAnyUploadError([tooLargeError1, tooManyError1])
        let errorToPresent1 = await sut.errorToPresent
        #expect(errorToPresent1?.title.string == L10n.AttachmentError.attachmentsOverSizeLimitTitle.string)

        await sut.errorDismissedShowNextError()

        let errorToPresent2 = await sut.errorToPresent
        #expect(errorToPresent2?.title.string == L10n.AttachmentError.tooManyAttachmentsFromServerTitle.string)
    }

    // MARK: onErrorToPresent

    @Test
    func testOnErrorToPresent_isCalled() async {
        var onErrorToPresentWasCalled = false
        await sut.setOnErrorToPresent({ _ in onErrorToPresentWasCalled = true })

        await sut.enqueueAnyUploadError([tooManyError1])

        #expect(onErrorToPresentWasCalled == true)
    }
}

private extension AttachmentErrorOrigin {
    var isUploading: Bool {
        switch self {
        case .adding: false
        case .uploading: true
        }
    }
}
