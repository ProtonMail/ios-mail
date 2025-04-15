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

import InboxCore
import OrderedCollections
import SwiftUI

public struct ToastSceneView: View {
    @EnvironmentObject public var toastStateStore: ToastStateStore

    public init() {}

    public var body: some View {
        Color.clear
            .ignoresSafeArea(.all)
            .toastView(state: $toastStateStore.state)
    }
}

private extension View {

    func toastView(state: Binding<ToastStateStore.State>) -> some View {
        modifier(ToastModifier(state: state))
    }

}

private struct ToastModifier: ViewModifier {
    @Binding var state: ToastStateStore.State
    @State private var automaticDismissalTasks: OrderedDictionary<Toast, DispatchWorkItem> = [:]

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(Array(zip(state.toasts.indices, state.toasts)), id: \.1) { index, toast in
                        toastView(toast: toast).zIndex(Double(-index))
                    }
                }
                .animation(.toastAnimation, value: state.toasts)
            )
            .onChange(of: state.toasts, initial: true) { _, new in
                if new.isEmpty {
                    state.toastHeights = [:]
                }

                new.forEach { toast in
                    if automaticDismissalTasks[toast] == nil && toast.duration > 0 {
                        let automaticDismissalTask = DispatchWorkItem {
                            dismissToast(toast: toast)
                        }

                        automaticDismissalTasks[toast] = automaticDismissalTask

                        Dispatcher.dispatchOnMainAfter(.now() + toast.duration, automaticDismissalTask)
                    }
                }
            }
    }

    @ViewBuilder
    private func toastView(toast: Toast) -> some View {
        VStack {
            Spacer()
            ToastView(model: toast, didSwipeDown: { dismissToast(toast: toast) })
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                            .onPreferenceChange(HeightPreferenceKey.self) { value in
                                state.toastHeights[toast] = value
                            }
                    }
                }
        }
        .transition(.move(edge: .bottom))
    }

    private func dismissToast(toast: Toast) {
        state.toasts = state.toasts.filter { $0 != toast }
        state.toastHeights[toast] = nil

        automaticDismissalTasks[toast]?.cancel()
        automaticDismissalTasks[toast] = nil
    }
}
