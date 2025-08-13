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

import proton_app_uniffi

extension Optional where Wrapped == Undo {
    /// Creates a fire-and-forget undo action.
    ///
    /// - Parameters:
    ///   - userSession: Context used when performing the undo.
    ///   - onFinish: A closure invoked **on the main actor** after the undo completes
    ///               (successfully or after throwing is handled by the caller). Use this to
    ///               update UI, e.g. hide a toast.
    /// - Returns: A closure you can call to start the undo operation, or `nil` if `self` is `nil`.
    ///
    /// The returned closure launches a `Task` that awaits the undo operation, then hops to the
    /// main actor to call `onFinish`. UI updates inside `onFinish` are safe.
    func undoAction(
        userSession: MailUserSession,
        onFinish: @MainActor @escaping @Sendable () -> Void
    ) -> (() -> Void)? {
        guard case .some(let wrapped) = self else {
            return nil
        }

        return {
            Task {
                try await wrapped.undo(ctx: userSession).get()
                await onFinish()
            }
        }
    }
}
