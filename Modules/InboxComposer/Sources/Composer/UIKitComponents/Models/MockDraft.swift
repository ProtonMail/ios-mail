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

import Foundation
import typealias InboxCore.ID
import proton_app_uniffi

extension SingleRecipientEntry {

    func toComposerRecipientSingle() -> ComposerRecipientSingle {
        .init(displayName: name, address: email, validState: .valid)
    }
}

final class MockDraft: AppDraftProtocol, @unchecked Sendable {
    static let defaultMessageId: Id = 12345
    static private var defaultSender: String { "old_sender@example.com" }
    static private var defaultSubject: String { "Test Subject" }
    static private var defaultBody: String { "Test Body" }
    static private var defaultRecipients: [ComposerRecipient] {
        [ComposerRecipient.single(.init(displayName: "", address: "inbox1@pm.me", validState: .valid))]
    }
    static private var defaultAttachments: [DraftAttachment] {
        let mockMimeType = AttachmentMimeType(mime: "pdf", category: .pdf)
        let mockAttachment = AttachmentMetadata(
            id: .random(),
            disposition: .attachment,
            mimeType: mockMimeType,
            name: "attachment_1",
            size: 123456,
            isListable: false
        )
        return [DraftAttachment(state: .uploaded, attachment: mockAttachment, stateModifiedTimestamp: 1742829536)]
    }

    var mockBody: String
    var mockSender: String
    var mockSubject: String
    var mockToRecipientList: MockComposerRecipientList
    var mockCcRecipientList: MockComposerRecipientList
    var mockBccRecipientList: MockComposerRecipientList
    var mockAttachmentList: MockAttachmentList
    var mockGetPassword: DraftGetPasswordResult = .ok(nil)
    var mockDraftExpirationTimeResult: DraftExpirationTimeResult = .ok(.never)
    var mockDraftAddressValidationResult: DraftAddressValidationResult? = nil
    var mockValidateRecipientsExpirationResult: DraftValidateRecipientsExpirationFeatureResult = .ok(
        .init(supported: [], unsupported: [], unknown: [])
    )

    var mockDraftMessageIdResult: DraftMessageIdResult = .ok(defaultMessageId)
    var mockMimeType: MimeType = .textHtml
    var mockSenderList: DraftListSenderAddressesResult = .ok(.init(available: [], active: .empty))
    var mockDraftChangeSenderAddressResult: DraftChangeSenderAddressResult = .ok
    var mockSendResult: VoidDraftSendResult = .ok

    private(set) var clearAddressValidationErrorWasCalled: Bool = false
    private(set) var sendWasCalled: Bool = false
    private(set) var scheduleSendWasCalled: Bool = false
    private(set) var scheduleSendWasCalledWithTime: UInt64 = 0

    init(
        mockBody: String,
        mockSender: String,
        mockSubject: String,
        mockToRecipientList: MockComposerRecipientList,
        mockCcRecipientList: MockComposerRecipientList,
        mockBccRecipientList: MockComposerRecipientList,
        mockAttachmentList: MockAttachmentList,
    ) {
        self.mockBody = mockBody
        self.mockSender = mockSender
        self.mockSubject = mockSubject
        self.mockToRecipientList = mockToRecipientList
        self.mockCcRecipientList = mockCcRecipientList
        self.mockBccRecipientList = mockBccRecipientList
        self.mockAttachmentList = mockAttachmentList
    }

    static var emptyMockDraft: MockDraft {
        .init(
            mockBody: .empty,
            mockSender: .empty,
            mockSubject: .empty,
            mockToRecipientList: MockComposerRecipientList(),
            mockCcRecipientList: MockComposerRecipientList(),
            mockBccRecipientList: MockComposerRecipientList(),
            mockAttachmentList: MockAttachmentList()
        )
    }

    static var defaultMockDraft: MockDraft {
        let attachmentList = MockAttachmentList()
        attachmentList.mockAttachments = defaultAttachments
        return MockDraft(
            mockBody: defaultBody,
            mockSender: defaultSender,
            mockSubject: defaultSubject,
            mockToRecipientList: .init(addedRecipients: defaultRecipients),
            mockCcRecipientList: .init(),
            mockBccRecipientList: .init(),
            mockAttachmentList: attachmentList
        )
    }

    static func makeWithRecipients(_ recipients: [ComposerRecipient], group: RecipientGroupType) -> MockDraft {
        let draft: MockDraft = .emptyMockDraft
        switch group {
        case .to: draft.mockToRecipientList = .init(addedRecipients: recipients)
        case .cc: draft.mockCcRecipientList = .init(addedRecipients: recipients)
        case .bcc: draft.mockBccRecipientList = .init(addedRecipients: recipients)
        }
        return draft
    }

    static func makeWithAttachments(_ attachments: [DraftAttachment]) -> MockDraft {
        let draft: MockDraft = .emptyMockDraft
        let mockAttachmentList = MockAttachmentList()
        mockAttachmentList.mockAttachments = attachments
        draft.mockAttachmentList = mockAttachmentList
        return draft
    }

    func messageId() async -> DraftMessageIdResult { mockDraftMessageIdResult }

    func mimeType() -> MimeType { mockMimeType }

    func addressValidationResult() -> DraftAddressValidationResult? { mockDraftAddressValidationResult }

    func clearAddressValidationError() {
        clearAddressValidationErrorWasCalled = true
    }

    func listSenderAddresses() async -> DraftListSenderAddressesResult {
        mockSenderList
    }

    func changeSenderAddress(email: String) async -> DraftChangeSenderAddressResult {
        if case .ok = mockDraftChangeSenderAddressResult {
            mockSender = email
        }
        return mockDraftChangeSenderAddressResult
    }

    func attachmentList() -> AttachmentListProtocol {
        mockAttachmentList
    }

    func toRecipients() -> ComposerRecipientListProtocol {
        mockToRecipientList
    }

    func ccRecipients() -> ComposerRecipientListProtocol {
        mockCcRecipientList
    }

    func bccRecipients() -> ComposerRecipientListProtocol {
        mockBccRecipientList
    }

    func body() -> String {
        mockBody
    }

    func scheduleSendOptions() -> DraftScheduleSendOptionsResult {
        let options = try! ScheduleSendOptionsProvider.dummy(isCustomAvailable: false).scheduleSendOptions().get()
        return .ok(options)
    }

    func schedule(timestamp: UInt64) async -> VoidDraftSendResult {
        scheduleSendWasCalled = true
        scheduleSendWasCalledWithTime = timestamp
        return mockSendResult
    }

    func send() async -> VoidDraftSendResult {
        sendWasCalled = true
        return mockSendResult
    }

    func sender() -> String {
        mockSender
    }

    func setBody(body: String) -> VoidDraftSaveResult {
        mockBody = body
        return .ok
    }

    func setSubject(subject: String) -> VoidDraftSaveResult {
        mockSubject = subject
        return .ok
    }

    func subject() -> String {
        mockSubject
    }

    func getEmbeddedAttachment(cid: String) async -> AttachmentDataResult {
        .error(.network)
    }

    func loadImage(url: String) async -> AttachmentDataResult {
        .error(.network)
    }

    func isPasswordProtected() -> DraftIsPasswordProtectedResult {
        .ok(false)
    }

    func setPassword(password: String, hint: String?) async -> VoidDraftPasswordResult { .ok }

    func getPassword() -> DraftGetPasswordResult { mockGetPassword }

    func removePassword() async -> VoidDraftPasswordResult { .ok }

    func expirationTime() -> DraftExpirationTimeResult { mockDraftExpirationTimeResult }

    func setExpirationTime(expirationTime: DraftExpirationTime) async -> VoidDraftExpirationResult { .ok }

    func validateRecipientsExpirationFeature() -> DraftValidateRecipientsExpirationFeatureResult {
        mockValidateRecipientsExpirationResult
    }

    func discard() async -> VoidDraftDiscardResult {
        .ok
    }
}

extension MockDraft {

    func attachmentPathsFor(dispositon: Disposition) -> [String] {
        let list = (attachmentList() as! MockAttachmentList)
        switch dispositon {
        case .attachment:
            return list.capturedAddCalls.map(\.path)
        case .inline:
            return list.capturedAddInlineCalls.map(\.path)
        }
    }
}

extension AppDraftProtocol where Self == MockDraft {
    static var emptyMock: MockDraft { .emptyMockDraft }
}

/**
 `MockComposerRecipientList` implments the logic it is expected from the SDK's `ComposerRecipientList` object. The
 UI state of the recpient lists is partially hold in the SDK. This is because recipients do not have an identifier and some operations
 need to happen based on the index of the elements.

 The reason have some logic in this mock object are:
 1. Avoid executing any HTTP request involved
 2. The `ComposerModel` logic relies on the updated `ComposerRecipientList` state during certain operations
 to update the ComposerState
 */
final class MockComposerRecipientList: ComposerRecipientListProtocol, @unchecked Sendable {
    var addedRecipients: [ComposerRecipient] = []
    private(set) var callback: ComposerRecipientValidationCallback?

    init(addedRecipients: [ComposerRecipient] = []) {
        self.addedRecipients = addedRecipients
    }

    func addGroupRecipient(groupName: String, recipients: [SingleRecipientEntry], totalContactsInGroup: UInt64) -> AddGroupRecipientError {
        let group = ComposerRecipientGroup(
            displayName: groupName,
            recipients: recipients.map { $0.toComposerRecipientSingle() },
            totalContactsInGroup: totalContactsInGroup
        )
        addedRecipients.append(.group(group))
        return .ok
    }

    func addSingleRecipient(recipient: SingleRecipientEntry) -> AddSingleRecipientError {
        addedRecipients.append(.single(recipient.toComposerRecipientSingle()))
        return .ok
    }

    func recipients() -> [ComposerRecipient] {
        addedRecipients
    }

    func removeGroup(groupName: String) -> RemoveRecipientError {
        .ok
    }

    func removeRecipientFromGroup(groupName: String, email: String) -> RemoveRecipientError {
        .ok
    }

    func removeSingleRecipient(email: String) -> RemoveRecipientError {
        addedRecipients.removeAll(where: { !$0.isGroup && $0.singleRecipient?.address == email })
        return .ok
    }

    func setCallback(cb: ComposerRecipientValidationCallback) {
        callback = cb
    }
}

final class MockAttachmentList: AttachmentListProtocol, @unchecked Sendable {
    var mockAttachments = [DraftAttachment]()
    var attachmentUploadDirectoryURL: URL = URL(fileURLWithPath: .empty)
    var capturedAddCalls: [(path: String, filenameOverride: String?)] = []
    var capturedAddInlineCalls: [(path: String, filenameOverride: String?)] = []
    var capturedSwapInlineCalls: [String] = []
    var capturedRemoveIdCalls: [ID] = []
    var capturedRemoveContentIdCalls: [String] = []
    var mockAttachmentListAddResult = [(lastPathComponent: String, result: AttachmentListAddResult)]()
    var mockAttachmentListAddInlineResult = [(lastPathComponent: String, result: AttachmentListAddInlineResult)]()
    var mockAttachmentSwapWithCidResult: VoidDraftAttachmentDispositionSwapResult = .ok
    var mockAttachmentListRemoveWithCidResult = [(cid: String, result: AttachmentListRemoveWithCidResult)]()

    func add(path: String, filenameOverride: String?) async -> AttachmentListAddResult {
        capturedAddCalls.append((path, filenameOverride))
        return mockAttachmentListAddResult.first(where: {
            $0.lastPathComponent == path.suffix($0.lastPathComponent.count)
        })?.result ?? AttachmentListAddResult.ok
    }

    func addInline(path: String, filenameOverride: String?) async -> AttachmentListAddInlineResult {
        capturedAddInlineCalls.append((path, filenameOverride))
        return mockAttachmentListAddInlineResult.first(where: {
            $0.lastPathComponent == path.suffix($0.lastPathComponent.count)
        })?.result ?? AttachmentListAddInlineResult.ok("12345")
    }

    func attachmentUploadDirectory() -> String {
        attachmentUploadDirectoryURL.path()
    }

    func attachments() async -> AttachmentListAttachmentsResult {
        .ok(mockAttachments)
    }

    func remove(id: Id) async -> AttachmentListRemoveResult {
        capturedRemoveIdCalls.append(id)
        return .ok
    }

    func removeWithCid(contentId: String) async -> AttachmentListRemoveWithCidResult {
        capturedRemoveContentIdCalls.append(contentId)
        return mockAttachmentListRemoveWithCidResult.first(where: {
            $0.cid == contentId
        })?.result ?? AttachmentListRemoveWithCidResult.ok
    }

    func retry(attachmentId: Id) async -> AttachmentListRetryResult {
        .ok
    }

    func swapAttachmentDisposition(contentId: String) async -> VoidDraftAttachmentDispositionSwapResult {
        capturedSwapInlineCalls.append(contentId)
        return mockAttachmentSwapWithCidResult
    }

    func watcher(callback: any AsyncLiveQueryCallback) async -> AttachmentListWatcherResult {
        .error(.reason(.crypto))
    }

    func watcherStream() async -> AttachmentListWatcherStreamResult {
        .ok(DraftAttachmentListUpdateStream.init(noPointer: .init()))
    }
}
