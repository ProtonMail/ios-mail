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

import SwiftUI

@MainActor
public protocol StateStore: ObservableObject where Action: Sendable {
    associatedtype State
    associatedtype Action

    var state: State { get set }

    func handle(action: Action) async
    func binding<Value>(_ keyPath: WritableKeyPath<State, Value> & Sendable) -> Binding<Value>
}

extension StateStore {
    public func binding<Value>(_ keyPath: WritableKeyPath<State, Value> & Sendable) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.state[keyPath: keyPath] = $0 }
        )
    }

    public func handle(action: Action) {
        Task {
            await handle(action: action)
        }
    }
}

@MainActor
public protocol StateStore_v2 {
    associatedtype State
    associatedtype Action

    var state: State { get set }

    func handle(action: Action) async
}

extension StateStore_v2 {
    public func handle(action: Action) {
        Task {
            await handle(action: action)
        }
    }
}
