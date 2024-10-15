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

import DesignSystem
import SwiftUI

struct SearchScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.Background.norm
                    .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    searchTextField
                }
                ToolbarItem(placement: .topBarTrailing) {
                    cancelButton
                }
            }
        }
    }

    private var searchTextField: some View {
        HStack(spacing: 0) {
            Image(DS.Icon.icMagnifier)
                .square(size: Layout.iconSquareSize)
                .foregroundStyle(DS.Color.Icon.hint)
                .padding(.leading, DS.Spacing.moderatelyLarge)

            TextField(L10n.Search.searchPlaceholder.string, text: $searchText)
                .font(.body)
                .padding(.leading, DS.Spacing.standard)
                .frame(maxHeight: Layout.searchBarHeight)
                .submitLabel(.search)
                .focused($isTextFieldFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(DS.Icon.icCrossCircleFilled)
                        .square(size: Layout.iconSquareSize)
                        .foregroundStyle(DS.Color.Icon.hint)
                }
                .padding(.trailing, DS.Spacing.mediumLight)
            }
        }
        .background(DS.Color.Background.deep)
        .cornerRadius(Layout.searchBarCornerRadius)
        .frame(maxHeight: Layout.searchBarHeight)
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private var cancelButton: some View {
        Button(action: { dismiss.callAsFunction() }) {
            Text(L10n.Search.cancel)
                .font(.body)
                .lineLimit(1)
                .foregroundColor(DS.Color.Text.accent)
        }
    }
}

private extension SearchScreen {

    enum Layout {
        static let searchBarHeight: CGFloat = 40
        static let searchBarCornerRadius: CGFloat = 20
        static let iconSquareSize: CGFloat = 20
    }
}
