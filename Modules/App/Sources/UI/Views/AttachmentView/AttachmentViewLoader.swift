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

import InboxCore
import SwiftUI
import proton_app_uniffi

@MainActor
final class AttachmentViewLoader: ObservableObject {
    @Published private(set) var state: State
    private let mailbox: MailboxProtocol
    private let queue: DispatchQueue = DispatchQueue(label: "\(Bundle.defaultIdentifier).AttachmentViewLoader")
    private var temporaryFileURL: URL?

    init(state: State = .loading, mailbox: MailboxProtocol) {
        self.state = state
        self.mailbox = mailbox
    }

    func load(attachmentId: ID) async {
        switch await mailbox.getAttachment(localAttachmentId: attachmentId) {
        case .ok(let result):
            let sourceURL = URL(fileURLWithPath: result.dataPath)

            do {
                let tempURL = try copyToTemporaryDirectory(from: sourceURL)
                updateState(.attachmentReady(tempURL))
            } catch {
                AppLogger.log(error: error)
                updateState(.error(.other(.unexpected(.fileSystem))))
            }
        case .error(let error):
            updateState(.error(error))
        }
    }

    /// Copies a file to the temporary directory for QLPreviewController compatibility.
    ///
    /// QLPreviewController has issues accessing files in app group sandbox folders.
    private func copyToTemporaryDirectory(from sourceURL: URL) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = sourceURL.lastPathComponent
        let tempURL = tempDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: tempURL)
        temporaryFileURL = tempURL
        return tempURL
    }

    func cleanupTemporaryFile() {
        guard let url = temporaryFileURL else { return }
        try? FileManager.default.removeItem(at: url)
        temporaryFileURL = nil
    }

    private func updateState(_ newState: State) {
        queue.sync {
            state = newState
        }
    }
}

extension AttachmentViewLoader {
    enum State {
        case loading
        case attachmentReady(URL)
        case error(ActionError)
    }
}
