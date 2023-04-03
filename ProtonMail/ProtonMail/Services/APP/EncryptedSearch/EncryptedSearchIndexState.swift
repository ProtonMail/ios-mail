// Copyright (c) 2022 Proton Technologies AG
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

enum EncryptedSearchIndexState: Equatable {
    static var allCases: [EncryptedSearchIndexState] = [
        .disabled,
        .partial,
        .downloading,
        .paused(nil),
        .refresh,
        .complete,
        .undetermined,
        .background,
        .backgroundStopped
    ]

    /// Content search has not yet been enabled, or is actively disabled by the user
    case disabled
    /// Indexing has been stopped because the size of the search index has hit the storage limit
    case partial
    /// The search index is currently being build and downloading is in progress
    case downloading
    /// The index building is paused, either actively by the user or due to an interrupt
    case paused(BuildSearchIndex.InterruptReason?)
    /// The search index has been completed, and new messages are added to the search index
    case refresh
    /// The search index is completely built and there are no newer messages on the server
    case complete
    /// There has been an error and the current state cannot be determined
    case undetermined
    /// The index is currently build in the background
    case background
    /// The index has been built in the background but has not yet finished
    case backgroundStopped

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.disabled, .disabled):
            return true
        case (.partial, .partial):
            return true
        case (.downloading, .downloading):
            return true
        case let (.paused(reasonL), .paused(reasonR)):
            return reasonL == reasonR
        case (.refresh, .refresh):
            return true
        case (.complete, .complete):
            return true
        case (.undetermined, .undetermined):
            return true
        case (.background, .background):
            return true
        case (.backgroundStopped, .backgroundStopped):
            return true
        default:
            return false
        }
    }
}

extension Collection where Element == EncryptedSearchIndexState {
    /// Doesn't care value inside associated values
    func containsCase(_ state: Element) -> Bool {
        for stateCase in self {
            switch (stateCase, state) {
            case (.paused, .paused):
                return true
            case let (lhs, rhs):
                if lhs == rhs {
                    return true
                }
            }
        }
        return false
    }
}
