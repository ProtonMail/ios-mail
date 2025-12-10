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
import InboxCoreUI
import SwiftUI

@MainActor
final class TrackersInfoViewStore: StateStore {
    enum Action {
        case onSectionTap(section: Section)
        case onBlockedTrackerTap(domain: String, url: String)
        case onBlockedTrackerAlertDismiss
        case onLinkTap(url: String)
        case onGotItTap
    }

    struct State {
        var trackers: TrackersUIModel
        var isTrackersSectionExpanded: Bool
        var isLinksSectionExpanded: Bool

        var isBlockedTrackerPresented: Bool = false
        var presentedBlockedTracker: (domain: String, url: String) = ("", "") {
            didSet {
                isBlockedTrackerPresented = !presentedBlockedTracker.domain.isEmpty || !presentedBlockedTracker.url.isEmpty
            }
        }

        init(trackers: TrackersUIModel, isTrackersSectionExpanded: Bool = false, isLinksSectionExpanded: Bool = false) {
            self.trackers = trackers
            self.isTrackersSectionExpanded = isTrackersSectionExpanded
            self.isLinksSectionExpanded = isLinksSectionExpanded
        }
    }

    enum Section {
        case blockedTrackers
        case links
    }

    @Published var state: State

    private let openUrl: OpenURLAction
    private let dismiss: DismissAction

    init(state: State, openUrl: OpenURLAction, dismiss: DismissAction) {
        self.state = state
        self.openUrl = openUrl
        self.dismiss = dismiss
    }

    func handle(action: Action) async {
        switch action {
        case .onSectionTap(let section):
            withAnimation(.easeInOut(duration: 0.3)) {
                switch section {
                case .blockedTrackers:
                    state.isTrackersSectionExpanded.toggle()
                case .links:
                    state.isLinksSectionExpanded.toggle()
                }
            }

        case .onBlockedTrackerTap(let domain, let url):
            state.presentedBlockedTracker = (domain, url)

        case .onBlockedTrackerAlertDismiss:
            state.isBlockedTrackerPresented = false

        case .onLinkTap(let url):
            guard let url = URL(string: url) else { return }
            openUrl(url)

        case .onGotItTap:
            dismiss()
        }
    }
}
