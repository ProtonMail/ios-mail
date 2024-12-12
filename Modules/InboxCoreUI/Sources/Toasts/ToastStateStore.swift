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
import OrderedCollections

public final class ToastStateStore: ObservableObject {
    public struct State {
        public var toasts: OrderedSet<Toast>
        public var toastHeights: [Toast: CGFloat]

        public var maxHeight: CGFloat {
            toastHeights.values.max() ?? .zero
        }
    }

    @Published public var state: State

    public init(initialState: State) {
        self.state = initialState
    }

    public func present(toast: Toast) {
        state.toasts.append(toast)
    }

    public func dismiss(toast: Toast) {
        state.toasts.remove(toast)
    }
}

extension ToastStateStore.State {

    public static var initial: Self {
        .init(toasts: [], toastHeights: [:])
    }

}
