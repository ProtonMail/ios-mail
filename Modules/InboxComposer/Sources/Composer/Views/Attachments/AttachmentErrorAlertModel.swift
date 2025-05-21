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
import proton_app_uniffi

enum AttachmentErrorAlertModel: Hashable {
    case overSizeLimit(origin: AttachmentErrorOrigin)
    case tooMany(origin: AttachmentErrorOrigin)
    case somethingWentWrong(origin: AttachmentErrorOrigin)

    var origin: AttachmentErrorOrigin {
        switch self {
        case .overSizeLimit(let origin), .tooMany(let origin), .somethingWentWrong(let origin):
            origin
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .overSizeLimit:
            L10n.AttachmentError.attachmentsOverSizeLimitTitle
        case .tooMany(let origin):
            switch origin {
            case .adding:
                L10n.AttachmentError.tooManyAttachmentsTitle
            case .uploading:
                L10n.AttachmentError.tooManyAttachmentsFromServerTitle
            }
        case .somethingWentWrong:
            L10n.AttachmentError.somethingWentWrongTitle
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .overSizeLimit(let origin):
            origin.errorCount > 1
            ? L10n.AttachmentError.multipleAttachmentOverSizeLimitMessage(count: origin.errorCount)
            : L10n.AttachmentError.singleAttachmentOverSizeLimitMessage
        case .tooMany:
            switch origin {
            case .adding:
                L10n.AttachmentError.tooManyAttachmentsMessage
            case .uploading:
                /**
                 When the too many attachments error comes from the server, it could mean different things because of lack of granularity:
                 - single attachment over 25 MB,
                 - total attachment size over 25 MB,
                 - total number of attachments over 100
                 For this reason we go with a more generic message.
                 */
                L10n.AttachmentError.tooManyAttachmentsFromServerMessage
            }
        case .somethingWentWrong:
            L10n.AttachmentError.somethingWentWrongMessage
        }
    }

    var actions: [AttachmentErrorActions] {
        switch self {
        case .overSizeLimit(let origin), .tooMany(let origin), .somethingWentWrong(let origin):
            switch origin {
            case .adding:
                return [.gotIt]
            case .uploading:
                return [.gotItRemovingFromDraft]
            }
        }
    }
}

enum AttachmentErrorOrigin: Hashable {
    case adding([AddAttachmentError])
    case uploading([UploadAttachmentError])

    var errorCount: Int {
        switch self {
        case .adding(let array):
            array.count
        case .uploading(let array):
            array.count
        }
    }
}

struct UploadAttachmentError: Identifiable, Hashable {
    var id: String { "\(attachmentId)-\(errorTimeStamp)" }
    let name: String
    let attachmentId: Id
    let errorTimeStamp: Int64
}

struct AddAttachmentError: Identifiable, Hashable {
    let id: String

    init(timestamp: TimeInterval) {
        self.id = timestamp.description
    }

    static var makeUnique: AddAttachmentError {
        .init(timestamp: Date.now.timeIntervalSince1970)
    }
}

enum AttachmentErrorActions: String, Identifiable, Hashable {
    case gotIt
    case gotItRemovingFromDraft

    var id: String {
        self.rawValue
    }

    var title: String {
        switch self {
        case .gotIt, .gotItRemovingFromDraft:
            L10n.Alert.gotIt.string
        }
    }

    var removeAttachment: Bool {
        switch self {
        case .gotIt:
            false
        case .gotItRemovingFromDraft:
            true
        }
    }
}

extension Collection where Element == AddAttachmentError {
    static func defaultAddAttachmentError(count: Int) -> [AddAttachmentError] {
        [AddAttachmentError].init(repeating: .makeUnique, count: count)
    }
}
