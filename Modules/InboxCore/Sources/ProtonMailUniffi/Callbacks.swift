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

import proton_app_uniffi

/**
 The Rust SDK by default strongly retains the callbacks/delegates set from the iOS app. This is because
 uniffi does not provide support to avoid retain cycles as stated in their
 documentation: https://mozilla.github.io/uniffi-rs/foreign_traits.html.

 This could change in the future, but in the meantime we replicate any callback declared in the Rust SDK
 with a proxy callback retaining a weak reference to the Swift object.
 */
public final class AsyncLiveQueryCallbackWrapper: Sendable, AsyncLiveQueryCallback {
    let callback: @Sendable () async -> Void

    public init(callback: @escaping @Sendable () async -> Void) {
        self.callback = callback
    }

    public func onUpdate() async {
        await callback()
    }
}

public final class LiveQueryCallbackWrapper: Sendable, LiveQueryCallback {
    let callback: @Sendable () -> Void

    public init(callback: @escaping @Sendable () -> Void) {
        self.callback = callback
    }

    public func onUpdate() {
        callback()
    }
}

public final class ExecuteWhenOnlineCallbackWrapper: Sendable, ExecuteWhenOnlineCallback {
    let callback: @Sendable () -> Void

    public init(callback: @escaping @Sendable () -> Void) {
        self.callback = callback
    }

    public func onOnline() {
        callback()
    }
}
