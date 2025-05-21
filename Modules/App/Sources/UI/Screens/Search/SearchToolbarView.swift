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
import InboxDesignSystem
import SwiftUI

struct SearchTextFieldState {
    var searchText: String = ""
    var isClearButtonVisible: Bool {
        searchText.withoutWhitespace.count > 1
    }
}

enum SearchToolbarEvent {
    case onSubmitSearch(query: String)
    case onCancel
    case onExitSelection
}

struct SearchToolbarView: View {
    @State private(set) var textFieldState: SearchTextFieldState = .init()
    @ObservedObject var selectedState: SelectionModeState
    @FocusState.Binding var isFocused: Bool

    let onEvent: (SearchToolbarEvent) -> Void

    var body: some View {
        ZStack {
            if selectedState.hasItems {
                selectionView
            } else {
                HStack {
                    searchTextField
                    cancelButton
                }
                .padding(.bottom, DS.Spacing.standard)
            }
        }
    }

    private var selectionView: some View {
        HStack {
            Button(
                action: {
                    onEvent(.onExitSelection)
                },
                label: {
                    HStack {
                        Spacer()
                        Image(DS.Icon.icChevronTinyLeft)
                            .resizable()
                            .square(size: 24)
                    }
                    .padding(10)
                }
            )
            .square(size: 40)

            SelectionTitleView(title: selectedState.title)
            Spacer()
        }
        .tint(DS.Color.Text.norm)
    }

    private var searchTextField: some View {
        HStack(spacing: 0) {
            Image(systemName: DS.SFSymbols.magnifier)
                .resizable()
                .square(size: Layout.iconSquareSize)
                .foregroundStyle(DS.Color.Icon.hint)
                .padding(.leading, DS.Spacing.moderatelyLarge)

            TextField(L10n.Search.searchPlaceholder.string, text: $textFieldState.searchText)
                .font(.body)
                .padding(.leading, DS.Spacing.standard)
                .frame(maxHeight: Layout.searchBarHeight)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmitWrapper(query: $textFieldState.searchText) { query in
                    onEvent(.onSubmitSearch(query: query))
                }

            if textFieldState.isClearButtonVisible {
                Button {
                    textFieldState.searchText = ""
                } label: {
                    Image(DS.Icon.icCrossCircleFilled)
                        .resizable()
                        .square(size: Layout.iconSquareSize)
                        .foregroundStyle(DS.Color.Icon.hint)
                }
                .padding(.trailing, DS.Spacing.mediumLight - Layout.searchBarCornerRadius / 2)
                .frame(height: Layout.buttonHeight)
            }
        }
        .background(DS.Color.Background.deep)
        .cornerRadius(Layout.searchBarCornerRadius)
        .frame(maxHeight: .infinity)
    }

    private var cancelButton: some View {
        Button(action: { onEvent(.onCancel) }) {
            Text(CommonL10n.cancel)
                .font(.body)
                .lineLimit(1)
                .foregroundColor(DS.Color.Text.accent)
        }
    }
}

private extension SearchToolbarView {

    enum Layout {
        static let searchBarHeight: CGFloat = 40
        static var searchBarCornerRadius: CGFloat {
            searchBarHeight / 2
        }
        static let iconSquareSize: CGFloat = 20
        static var buttonHeight: CGFloat {
            searchBarHeight - 4.0
        }
    }
}
