// Copyright (c) 2025 Proton Technologies AG
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

struct TrackersUIModel: Identifiable, Hashable {
    let id = UUID()
    let blockedTrackers: [TrackerDomain]
    let cleanedLinks: [CleanedLink]

    var isEmpty: Bool {
        blockedTrackers.isEmpty && cleanedLinks.isEmpty
    }

    var totalTrackersCount: Int {
        blockedTrackers.reduce(0) { $0 + $1.urls.count }
    }

    var totalLinksCount: Int {
        cleanedLinks.count
    }

    var areTrackersPresented: Bool {
        blockedTrackers.count > 0 || (blockedTrackers.isEmpty && cleanedLinks.isEmpty)
    }

    var areLinksPresented: Bool {
        cleanedLinks.count > 0
    }

    static var empty: TrackersUIModel {
        .init(blockedTrackers: [], cleanedLinks: [])
    }
}

struct CleanedLink: Hashable {
    let original: String
    let cleaned: String
}

// MARK: - PrivacyInfo to UI Model conversion

extension PrivacyInfo {
    func toUIModel() -> TrackersUIModel {
        let trackers: [TrackerDomain]? =
            switch trackers {
            case .detected(let trackerInfo):
                trackerInfo.trackers
            case .pending, .disabled:
                nil
            }

        return TrackersUIModel(
            blockedTrackers: trackers ?? [],
            cleanedLinks: utmLinks?.links.map { CleanedLink(original: $0.originalUrl, cleaned: $0.cleanedUrl) } ?? []
        )
    }
}
