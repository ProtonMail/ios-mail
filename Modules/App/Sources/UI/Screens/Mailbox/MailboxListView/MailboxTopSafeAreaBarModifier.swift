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

import SwiftUI

@available(iOS 26, *)
struct MailboxTopSafeAreaBarModifier: ViewModifier {
    let topBarState: MailboxTopBarState?
    let onEvent: (MailboxTopBarEvent) -> Void

    @State private var topAreaInset: CGFloat = 0
    @State private var barHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .contentMargins(.top, topAreaInset + barHeight, for: .scrollContent)
            .ignoresSafeArea(.container, edges: .top)
            .safeAreaBar(edge: .top) {
                if let viewModel = topBarState {
                    MailboxTopBarView(state: viewModel, onEvent: onEvent)
                        .onGeometryChange(for: CGFloat.self, of: \.size.height) { newValue in
                            barHeight = newValue
                        }
                        .onDisappear {
                            barHeight = 0
                        }
                }
            }
            .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { newValue in
                topAreaInset = newValue
            }
    }
}

extension View {
    @available(iOS 26, *)
    @ViewBuilder
    func mailboxTopSafeAreaBar(
        state: MailboxTopBarState?,
        onEvent: @escaping (MailboxTopBarEvent) -> Void
    ) -> some View {
        modifier(MailboxTopSafeAreaBarModifier(topBarState: state, onEvent: onEvent))
    }
}
