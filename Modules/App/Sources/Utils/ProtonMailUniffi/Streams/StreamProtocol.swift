//
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

import Combine
import InboxCore
import proton_app_uniffi

protocol StreamProtocol: Cancellable, Sendable {
    func nextAsync() async throws
}

extension StreamProtocol {
    func observe(callback: @escaping @Sendable () async -> Void) -> AnyCancellable {
        Task {
            do {
                while true {
                    try await nextAsync()
                    await callback()
                }
            } catch ProtonError.unexpected(.internal) {
                // this is the current cancellation error
            } catch {
                AppLogger.log(error: error)
            }
        }

        return AnyCancellable(self)
    }

    func observe(callback: AsyncLiveQueryCallbackWrapper) -> AnyCancellable {
        observe {
            await callback.onUpdate()
        }
    }
}
