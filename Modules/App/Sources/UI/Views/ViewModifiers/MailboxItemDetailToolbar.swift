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
import InboxDesignSystem
import SwiftUI

struct ConversationToolbar<TrailingButton: View>: ViewModifier {
    @Environment(\.presentationMode) var presentationMode
    private let title: AttributedString
    private let trailingButton: () -> TrailingButton?

    init(title: AttributedString, trailingButton: @escaping () -> TrailingButton?) {
        self.title = title
        self.trailingButton = trailingButton
    }

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        HStack {
                            Spacer()
                            Image(DS.Icon.icChevronTinyLeft)
                                .foregroundStyle(DS.Color.Icon.norm)
                        }
                        .padding(10)
                    })
                    .square(size: 40)
                }

                ToolbarItem(placement: .principal) {
                    Text(title)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .transition(.opacity)
                        .animation(.default, value: title)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingButton()
                }
            }
    }

}

extension View {

    func conversationTopToolbar(
        title: AttributedString,
        trailingButton: @escaping () -> some View
    ) -> some View {
        modifier(ConversationToolbar(title: title, trailingButton: trailingButton))
    }
}
