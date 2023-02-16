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

enum EncryptedSearchIndexState: Int, CaseIterable {
    /// Content search has not yet been enabled, or is actively disabled by the user
    case disabled = 0
    /// Indexing has been stopped because the size of the search index has hit the storage limit
    case partial
    /// Indexing has been stopped because there is less than 100MB storage left on the device
    case lowstorage
    /// The search index is currently beeing build and downloading is in progress
    case downloading
    /// The index building is paused, either actively by the user or due to an interrupt
    case paused
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
    /// Currently not used (for metadata indexing of free users)
    case metadataIndexing
    /// Currently not used (for metadata indexing of free users)
    case metadataIndexingComplete
}
