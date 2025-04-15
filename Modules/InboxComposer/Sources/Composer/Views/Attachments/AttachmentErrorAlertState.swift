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

import Collections
import InboxCore
import proton_app_uniffi
import SwiftUI

actor AttachmentErrorAlertState {
    private(set) var queue: OrderedSet<AttachmentErrorAlertModel> = []
    private var idsAlreadySeen: Set<String> = []
    private(set) var errorToPresent: AttachmentErrorAlertModel? = nil {
        didSet {
            if let errorToPresent { onErrorToPresent(errorToPresent) }
        }
    }
    var onErrorToPresent: (AttachmentErrorAlertModel) -> Void = { _ in }

    func setOnErrorToPresent(_ closure: @escaping (AttachmentErrorAlertModel) -> Void) {
        onErrorToPresent = closure
    }

    func enqueueAdditionErrors(_ errors: [DraftAttachmentError]) {
        let attachmentErrors = aggregateAddingAttachmentErrors(errors)
        queue.append(contentsOf: attachmentErrors)
        nextErrorToPresent()
    }

    func enqueueAnyUploadError(_ draftAttachments: [DraftAttachment]) {
        let attachmentErrors = aggregateUploadingAttachmentErrors(draftAttachments)
        queue.append(contentsOf: attachmentErrors)
        nextErrorToPresent()
    }

    private func dequeue() -> AttachmentErrorAlertModel? {
        guard !queue.isEmpty else { return nil }
        let first = queue.removeFirst()
        return first
    }

    func errorDismissedShowNextError() async {
        errorToPresent = nil
        try? await Task.sleep(for: .milliseconds(100))
        nextErrorToPresent()
    }

    func nextErrorToPresent() {
        guard errorToPresent == nil else { return }
        errorToPresent = dequeue()
    }
}

extension AttachmentErrorAlertState {

    /// Groups together `DraftAttachmentError` by error type to reduce the total number of alerts.
    private func aggregateAddingAttachmentErrors(_ errors: [DraftAttachmentError]) -> [AttachmentErrorAlertModel] {
        var attachmentTooLargeCount = 0
        var tooManyAttachmentsCount = 0
        var otherCount = 0

        for error in errors {
            switch error {
            case .reason(let reason):
                switch reason {
                case .tooManyAttachments:
                    tooManyAttachmentsCount += 1
                case .attachmentTooLarge:
                    attachmentTooLargeCount += 1
                default:
                    otherCount += 1
                }
            case .other:
                otherCount += 1
            }
        }

        var result = [AttachmentErrorAlertModel]()
        if attachmentTooLargeCount > 0 {
            result.append(.overSizeLimit(origin: .adding(.defaultAddAttachmentError(count: attachmentTooLargeCount))))
        }
        if tooManyAttachmentsCount > 0 {
            result.append(.tooMany(origin: .adding(.defaultAddAttachmentError(count: tooManyAttachmentsCount))))
        }
        if otherCount > 0 {
            result.append(.somethingWentWrong(origin: .adding(.defaultAddAttachmentError(count: otherCount))))
        }
        return result
    }

    /// Groups together `DraftAttachment` by error type to reduce the total number of alerts.
    private func aggregateUploadingAttachmentErrors(_ attachments: [DraftAttachment]) -> [AttachmentErrorAlertModel] {
        var tooLargeFailures = [DraftAttachment]()
        var tooManyFailures = [DraftAttachment]()
        var otherFailures = [DraftAttachment]()

        for attachment in attachments {
            guard let error = attachment.state.attachmentError else { continue }

            switch error {
            case .reason(let reason):
                switch reason {
                case .tooManyAttachments:
                    tooManyFailures.append(attachment)
                case .attachmentTooLarge:
                    tooLargeFailures.append(attachment)
                default:
                    otherFailures.append(attachment)
                }
            case .other:
                otherFailures.append(attachment)
            }
        }

        var result = [AttachmentErrorAlertModel]()
        if !tooLargeFailures.isEmpty, let uploadingError = mapUnseenToUploadingErrorOrigin(tooLargeFailures) {
            result.append(.overSizeLimit(origin: uploadingError))
        }
        if !tooManyFailures.isEmpty, let uploadingError = mapUnseenToUploadingErrorOrigin(tooManyFailures) {
            result.append(.tooMany(origin: uploadingError))
        }
        if !otherFailures.isEmpty, let uploadingError = mapUnseenToUploadingErrorOrigin(otherFailures) {
            result.append(.somethingWentWrong(origin: uploadingError))
        }
        return result
    }

    private func mapUnseenToUploadingErrorOrigin(_ items: [DraftAttachment]) -> AttachmentErrorOrigin? {
        let errors: [UploadAttachmentError] = items.map(\.toUploadAttachmentError)
        let errorsToEnqueue = errors.filter { !idsAlreadySeen.contains($0.id) }
        idsAlreadySeen = idsAlreadySeen.union(errorsToEnqueue.map(\.id))
        return errorsToEnqueue.isEmpty ? nil : .uploading(errorsToEnqueue)
    }
}

extension DraftAttachment {

    var toUploadAttachmentError: UploadAttachmentError {
        UploadAttachmentError(name: attachment.name, attachmentId: attachment.id, errorTimeStamp: stateModifiedTimestamp)
    }
}

#Preview {

    final class ContentState: ObservableObject, @unchecked Sendable {
        let errorState: AttachmentErrorAlertState = .init()
        @Published var isAlertPresented: Bool = false
        var presentedError: AttachmentErrorAlertModel? = nil

        init() {
            Task {
                await errorState.setOnErrorToPresent { error in
                    DispatchQueue.main.async { [weak self] in
                        self?.presentedError = error
                        self?.isAlertPresented = true
                    }
                }
            }
        }
    }

    struct ContentView: View {
        @StateObject private var state: ContentState

        init() {
            self._state = .init(wrappedValue: .init())
        }

        var body: some View {
            VStack {
                Button("Show Alert".notLocalized) {
                    Task {
                        await state.errorState.enqueueAnyUploadError([
                            DraftAttachment.makeMock(state: .uploaded, timestamp: 1),
                            DraftAttachment.makeMock(state: .error(.reason(.attachmentTooLarge)), timestamp: 2),
                            DraftAttachment.makeMock(state: .error(.other(.network)), timestamp: 3),
                            DraftAttachment.makeMock(state: .error(.reason(.attachmentTooLarge)), timestamp: 4),
                        ])
                    }
                }
            }
            .alert(
                Text(state.presentedError?.title ?? LocalizedStringResource(stringLiteral: .empty)),
                isPresented: $state.isAlertPresented,
                presenting: state.presentedError,
                actions: { actionsForAttachmentAlert(error: $0) },
                message: { Text($0.message) }
            )
        }

        @ViewBuilder
        func actionsForAttachmentAlert(error: AttachmentErrorAlertModel) -> some View {
            Button(role: .cancel) {
                Task {
                    await state.errorState.errorDismissedShowNextError()
                }
            } label: {
                Text("Got it".notLocalized)
            }
        }
    }
    return ContentView()
}
