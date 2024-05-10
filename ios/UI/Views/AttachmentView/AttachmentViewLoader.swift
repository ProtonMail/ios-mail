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

import SwiftUI

final class AttachmentViewLoader: @unchecked Sendable, ObservableObject {
    @Published private(set) var state: State
    private let dataSource: AttachmentDataSource
    private let queue: DispatchQueue = DispatchQueue(label: "\(Bundle.defaultIdentifier).AttachmentViewLoader")

    init(state: State = .loading, dataSource: AttachmentDataSource) {
        self.state = state
        self.dataSource = dataSource
    }

    func load(attachmentId: PMLocalAttachmentId) async {
        let result = await dataSource.attachment(for: attachmentId)
        switch result {
        case .success(let url):
            await updateState(.attachmentReady(url))
        case .failure(let error):
            await updateState(.error(error))
        }
    }

    @MainActor
    private func updateState(_ newState: State) {
        queue.sync {
            state = newState
        }
    }

    private func deleteAttachment() {
        switch state {
        case .loading, .error:
            break
        case .attachmentReady(let url):
            try? FileManager.default.removeItem(atPath: url.path())
        }
    }

    deinit {
        deleteAttachment()
    }
}

extension AttachmentViewLoader {
    enum State {
        case loading
        case attachmentReady(URL)
        case error(Error)
    }
}
