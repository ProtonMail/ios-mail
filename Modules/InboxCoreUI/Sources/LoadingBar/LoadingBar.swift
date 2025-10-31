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

public struct LoadingBar: View {
    private let isLoading: Bool
    private let configuration: LoadingBarConfiguration
    @StateObject private var stateStore: LoadingBarStateStore
    @State private var timer: Publishers.Autoconnect<Timer.TimerPublisher>

    public init(isLoading: Bool) {
        let configuration = LoadingBarConfiguration()
        self.isLoading = isLoading
        self.configuration = configuration
        _stateStore = .init(wrappedValue: .init(configuration: configuration))
        _timer = .init(
            wrappedValue:
                Timer
                .publish(every: configuration.cycleDuration, on: .main, in: .common)
                .autoconnect()
        )
    }

    public var body: some View {
        Group {
            if stateStore.isLoading {
                CyclingProgressBar(configuration: configuration)
                    .transition(.opacity)
                    .onReceive(timer) { _ in
                        stateStore.handle(action: .cycleCompleted)
                    }
            }
        }
        .onChange(of: isLoading) { _, newValue in
            if newValue {
                stateStore.handle(action: .startLoading)
            } else {
                stateStore.handle(action: .stopLoading)
            }
        }
        .animation(.easeInOut, value: stateStore.isLoading)
    }
}
