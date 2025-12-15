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

@preconcurrency import Combine
import proton_app_uniffi

/// This class allows to enqueue updates synchronously ensuring the updates order
/// and provides streams to consume the updates in the MainActor async context.
@MainActor
final class ScrollerUpdatesAsync {
    nonisolated private let messagePublisher = PassthroughSubject<MessageScrollerUpdate, Never>()
    nonisolated private let conversationPublisher = PassthroughSubject<ConversationScrollerUpdate, Never>()

    private var task: Task<Void, Never>? {
        didSet {
            taskDidChange?(task)
        }
    }

    var taskDidChange: ((Task<Void, Never>?) -> Void)?

    var messageStream: AsyncStream<MessageScrollerUpdate> {
        messagePublisher.valuesWithBuffering
    }

    var conversationStream: AsyncStream<ConversationScrollerUpdate> {
        conversationPublisher.valuesWithBuffering
    }

    /// For each update `handleUpdate` is called. Observing one stream terminates any previous observed stream immediately.
    func observe<T: Sendable>(
        _ keyPath: KeyPath<ScrollerUpdatesAsync, AsyncStream<T>>,
        handleUpdate: @escaping (T) async -> Void
    ) async {
        task?.cancel()
        task = Task { [weak self] in
            guard let stream = self?[keyPath: keyPath] else { return }
            for await update in stream {
                guard !Task.isCancelled else { return }
                await handleUpdate(update)
            }
        }
        await Task.yield()  // give Task time to start observing the stream
    }

    nonisolated func enqueueUpdate(_ update: MessageScrollerUpdate) {
        messagePublisher.send(update)
    }

    nonisolated func enqueueUpdate(_ update: ConversationScrollerUpdate) {
        conversationPublisher.send(update)
    }
}
