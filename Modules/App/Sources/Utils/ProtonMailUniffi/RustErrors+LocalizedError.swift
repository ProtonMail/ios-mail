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

extension DraftError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let draftErrorReason):
            draftErrorReason.errorMessage.string
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

private extension DraftErrorReason {
    var errorMessage: LocalizedStringResource {
        switch self {
        case .unknownMimeType:
            L10n.Error.unknownMimeType
        }
    }
}

extension EventError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .reason(let eventErrorReason):
            eventErrorReason.errorMessage
        case .other(let protonError):
            protonError.localizedDescription
        }
    }
}

private extension EventErrorReason {
    var errorMessage: String {
        switch self {
        case .placeholder:
            "Unknown error"
        }
    }
}
