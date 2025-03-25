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

import proton_app_uniffi
import SwiftUI

final class AttachmentAlertState: ObservableObject, @unchecked Sendable {
    @Published var isAlertPresented: Bool = false
    private(set) var presentedError: AttachmentError? = nil
    private let attachmentErrorState: AttachmentErrorState = .init()

    init() {
        Task {
            await attachmentErrorState.setOnErrorToPresent { [weak self] error in
                DispatchQueue.main.async {
                    self?.presentedError = error
                    self?.isAlertPresented = true
                }
            }
        }
    }

    func enqueueAlertsForFailedAttachmentAdditions(errors: [DraftAttachmentError]) {
        let attachmentErrors = aggregateAddingAttachmentErrors(errors)
        Task { await attachmentErrorState.enqueue(attachmentErrors) }
    }

    func enqueueAlertsForFailedAttachmentUploads(attachments: [DraftAttachment]) {
        let attachmentErrors = aggregateUploadingAttachmentErrors(attachments)
        Task { await attachmentErrorState.enqueue(attachmentErrors) }
    }

    func errorDismissedShowNextError() {
        Task {
            await attachmentErrorState.errorDismissedShowNextError()
        }
    }
}

extension AttachmentAlertState {

    private func aggregateAddingAttachmentErrors(_ errors: [DraftAttachmentError]) -> [AttachmentError] {
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

        var result = [AttachmentError]()
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

    private func aggregateUploadingAttachmentErrors(_ attachments: [DraftAttachment]) -> [AttachmentError] {
        var tooLargeFailures = [DraftAttachment]()
        var tooManyAttachmentsFailures = [DraftAttachment]()
        var otherFailures = [DraftAttachment]()

        for attachment in attachments {
            guard let error = attachment.state.attachmentError else { continue }

            switch error {
            case .reason(let reason):
                switch reason {
                case .tooManyAttachments:
                    tooManyAttachmentsFailures.append(attachment)
                case .attachmentTooLarge:
                    tooLargeFailures.append(attachment)
                default:
                    otherFailures.append(attachment)
                }
            case .other:
                otherFailures.append(attachment)
            }
        }

        var result = [AttachmentError]()
        if !tooLargeFailures.isEmpty {
            result.append(.overSizeLimit(origin: .uploading(tooLargeFailures.map(\.toUploadAttachmentError))))
        }
        if !tooManyAttachmentsFailures.isEmpty {
            result.append(.tooMany(origin: .uploading(tooManyAttachmentsFailures.map(\.toUploadAttachmentError))))
        }
        if !otherFailures.isEmpty {
            result.append(.somethingWentWrong(origin: .uploading(otherFailures.map(\.toUploadAttachmentError))))
        }
        return result
    }
}

extension DraftAttachment {

    var toUploadAttachmentError: UploadAttachmentError {
        UploadAttachmentError(name: attachment.name, attachmentId: attachment.id, errorTimeStamp: stateModifiedTimestamp)
    }
}
