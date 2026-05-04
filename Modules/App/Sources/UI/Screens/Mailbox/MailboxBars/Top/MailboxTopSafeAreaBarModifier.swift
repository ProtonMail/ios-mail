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

import InboxCoreUI
import SwiftUI
import SwiftUIIntrospect

@available(iOS 26, *)
struct MailboxTopSafeAreaBarModifier: ViewModifier {
    let topBarState: MailboxTopBarState?
    let action: (MailboxTopBarAction) -> Void

    @State private var topAreaInset: CGFloat = 0
    @State private var barHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .introspect(.list, on: SupportedIntrospectionPlatforms.list) { collectionView in
                collectionView.contentInset = .init(top: topAreaInset + barHeight, left: 0, bottom: 0, right: 0)
                collectionView.scrollIndicatorInsets = .init(top: topAreaInset + barHeight, left: 0, bottom: 0, right: 0)
            }
            .ignoresSafeArea(.container, edges: .top)
            .safeAreaBar(edge: .top) {
                if let state = topBarState {
                    MailboxTopBarView(state: state, action: action)
                        .onGeometryChange(for: CGFloat.self, of: \.size.height) { newValue in
                            barHeight = newValue
                        }
                }
            }
            .onChange(of: topBarState) { _, newValue in
                if newValue == nil {
                    barHeight = 0
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
        action: @escaping (MailboxTopBarAction) -> Void
    ) -> some View {
        modifier(MailboxTopSafeAreaBarModifier(topBarState: state, action: action))
    }
}
