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

struct MailboxItemDetailToolbar: ViewModifier {
    @Environment(\.presentationMode) var presentationMode
    let purpose: Purpose

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        HStack {
                            Spacer()
                            Image(uiImage: DS.Icon.icChevronLeft)
                        }
                        .padding(10)
                    })
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .stroke(DS.Color.Border.norm)
                    }
                    .accessibilityIdentifier(MailboxItemDetailToolbarIdentifiers.backButton)
                }
                ToolbarItem(placement: .principal) {
                    purpose.principalView
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    purpose.trailingView
                }
            }
            .tint(DS.Color.Text.norm)
    }
}

extension MailboxItemDetailToolbar {

    enum Purpose {
        case itemDetail(isStarStateKnown: Bool, isStarred: Bool)
        case simpleNavigation(title: String)

        @ViewBuilder
        var principalView: some View {
            switch self {
            case .itemDetail:
                EmptyView()
            case .simpleNavigation(let title):
                if title.isEmpty {
                    EmptyView()
                } else {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, DS.Spacing.medium)
                }
            }
        }

        @ViewBuilder
        var trailingView: some View {
            switch self {
            case .itemDetail(let isStarStateKnown, let isStarred):
                if isStarStateKnown {
                    Button(action: {
                        // TODO:
                    }, label: {
                        Image(uiImage: isStarred ? DS.Icon.icStarFilled : DS.Icon.icStar)
                            .foregroundStyle(isStarred ? DS.Color.Star.selected : DS.Color.Star.default)
                    })
                    .accessibilityIdentifier(MailboxItemDetailToolbarIdentifiers.starButton)
                } else {
                    EmptyView()
                }
            case .simpleNavigation:
                EmptyView()
            }
        }
    }
}

extension View {
    @MainActor
    func navigationToolbar(purpose: MailboxItemDetailToolbar.Purpose) -> some View {
        return self.modifier(MailboxItemDetailToolbar(purpose: purpose))
    }
}

private struct MailboxItemDetailToolbarIdentifiers {
    static let backButton = "detail.backButton"
    static let starButton = "detail.starButton"
}
