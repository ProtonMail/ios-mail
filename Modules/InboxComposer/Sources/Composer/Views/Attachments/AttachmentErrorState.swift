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

import Collections
import InboxCore
import SwiftUI

actor AttachmentErrorState {
    private var queue: OrderedSet<AttachmentError> = []
    private var alreadySeen: OrderedSet<AttachmentError> = []
    private(set) var errorToPresent: AttachmentError? = nil {
        didSet {
            if let errorToPresent { onErrorToPresent(errorToPresent) }
        }
    }
    var onErrorToPresent: (AttachmentError) -> Void = { _ in }

    func setOnErrorToPresent(_ closure: @escaping (AttachmentError) -> Void) {
        onErrorToPresent = closure
    }

    func enqueue(_ errors: [AttachmentError]) {
        for error in errors where !alreadySeen.contains(error) {
            queue.append(error)
        }
        nextErrorToPresent()
    }

    private func dequeue() -> AttachmentError? {
        guard !queue.isEmpty else { return nil }
        let first = queue.removeFirst()
        alreadySeen.append(first)
        return first
    }

    func errorDismissedShowNextError() async {
        errorToPresent = nil
        try? await Task.sleep(for: .milliseconds(100))
        nextErrorToPresent()
    }

    func nextErrorToPresent() {
        guard errorToPresent == nil else { return }
        errorToPresent = dequeue()
    }
}

#Preview {

    final class ContentState: ObservableObject, @unchecked Sendable {
        let errorState: AttachmentErrorState = .init()
        @Published var isAlertPresented: Bool = false
        var presentedError: AttachmentError? = nil

        init() {
            Task {
                await errorState.setOnErrorToPresent { error in
                    DispatchQueue.main.async { [weak self] in
                        self?.presentedError = error
                        self?.isAlertPresented = true
                    }
                }
            }
        }
    }

    struct ContentView: View {
        @StateObject private var state: ContentState

        init() {
            self._state = .init(wrappedValue: .init())
        }

        var body: some View {
            VStack {
                Button("Show Alert".notLocalized) {
                    Task {
                        await state.errorState.enqueue([
                            .overSizeLimit(origin: .adding(.defaultAddAttachmentError(count: 1))),
                            .somethingWentWrong(origin: .adding(.defaultAddAttachmentError(count: 1)))
                        ])
                    }
                }
            }
            .alert(
                Text(state.presentedError?.title ?? LocalizedStringResource(stringLiteral: .empty)),
                isPresented: $state.isAlertPresented,
                presenting: state.presentedError,
                actions: { actionsForAttachmentAlert(error: $0) },
                message: { Text($0.message) }
            )
        }

        @ViewBuilder
        func actionsForAttachmentAlert(error: AttachmentError) -> some View {
            Button(role: .cancel) {
                Task {
                    await state.errorState.errorDismissedShowNextError()
                }
            } label: {
                Text("Got it".notLocalized)
            }
        }
    }
    return ContentView()
}
