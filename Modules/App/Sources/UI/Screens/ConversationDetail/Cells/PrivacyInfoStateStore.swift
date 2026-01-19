// Copyright (c) 2026 Proton Technologies AG
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
import InboxCore
import InboxCoreUI
import proton_app_uniffi

@MainActor
final class PrivacyInfoStateStore: StateStore {
    enum Action: Sendable {
        case loadInfo
    }

    @Published var state: Loadable<TrackersUIModel>
    private let messageID: ID
    private let privacyInfoStreamProvider: WatchPrivacyInfoStreamProvider
    private var streamTask: Task<Void, Never>?
    private var privacyStream: (any AsyncWatchingStream)?

    init(
        messageID: ID,
        privacyInfoStreamProvider: WatchPrivacyInfoStreamProvider
    ) {
        self.state = .loading
        self.messageID = messageID
        self.privacyInfoStreamProvider = privacyInfoStreamProvider
    }

    func handle(action: Action) async {
        switch action {
        case .loadInfo:
            await loadPrivacyInfo()
        }
    }

    // MARK: - Private

    private func loadPrivacyInfo() async {
        guard state.loadedValue == nil else { return }

        do {
            privacyStream = try await privacyInfoStreamProvider.stream(for: messageID)

            if let initialInfo = privacyStream?.value as? PrivacyInfo,
                initialInfo.trackers != nil && initialInfo.utmLinks != nil
            {
                state = .loaded(initialInfo.toUIModel())
            }

            streamTask = Task { [weak self] in
                do {
                    while !Task.isCancelled {
                        let info = try await self?.privacyStream?.next() as? PrivacyInfo
                        guard let info, let self else { return }
                        if info.trackers != nil && info.utmLinks != nil {
                            state = .loaded(info.toUIModel())
                        }
                    }
                } catch {
                    AppLogger.log(error: error, category: .conversationDetail)
                }
                self?.privacyStream?.stop()
            }
        } catch {
            AppLogger.log(error: error, category: .conversationDetail)
        }
    }

    deinit {
        privacyStream?.stop()
    }
}
