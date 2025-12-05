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
import SwiftUI

public struct LoadingBar<Content: View>: View {
    private let isLoading: Bool
    private let configuration: LoadingBarConfiguration
    private let content: () -> Content
    @StateObject private var stateStore: LoadingBarStateStore

    public init(isLoading: Bool, @ViewBuilder content: @escaping () -> Content) {
        let configuration = LoadingBarConfiguration()
        self.isLoading = isLoading
        self.configuration = configuration
        self.content = content
        _stateStore = .init(wrappedValue: .init(configuration: configuration))
    }

    // MARK: - View

    public var body: some View {
        ZStack(alignment: .top) {
            content()
            if stateStore.isLoading {
                CyclingProgressBar(configuration: configuration) {
                    stateStore.handle(action: .cycleCompleted)
                }
            }
        }
        .onChange(of: isLoading, initial: true) { _, newValue in
            let action: LoadingBarStateStore.Action = newValue ? .startLoading : .stopLoading
            stateStore.handle(action: action)
        }
    }
}
