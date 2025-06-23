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

final class DebouncedTask {
    private let duration: Duration
    private let onBlockCompletion: () -> Void
    private let executionBlock: (() async -> Void)
    private var task: Task<(), Never>?

    init(duration: Duration, block executionBlock: @escaping () async -> Void, onBlockCompletion: @escaping () -> Void) {
        self.duration = duration
        self.onBlockCompletion = onBlockCompletion
        self.executionBlock = executionBlock
    }

    func debounce() {
        self.task = Task { [weak self] in
            guard let self else { return }
            defer { if !Task.isCancelled { onBlockCompletion() } }

            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            await executionBlock()
        }
    }

    func executeImmediately() async {
        cancel()
        await executionBlock()
        onBlockCompletion()
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
