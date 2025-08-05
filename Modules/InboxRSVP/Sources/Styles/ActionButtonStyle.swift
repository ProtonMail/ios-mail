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

import InboxDesignSystem
import SwiftUI

struct ActionButtonStyle: ButtonStyle {
    let textColor: Color
    let fontWeight: Font.Weight
    let backgroundColor: Color
    let pressedBackgroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(fontWeight)
            .foregroundStyle(textColor)
            .padding(.all, 12)
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? pressedBackgroundColor : backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.massive))
    }
}

extension ActionButtonStyle {

    static var answerButtonStyle: Self {
        .init(
            textColor: DS.Color.Text.inverted,
            fontWeight: .semibold,
            backgroundColor: DS.Color.InteractionBrand.norm,
            pressedBackgroundColor: DS.Color.InteractionBrand.pressed
        )
    }

    static var retryButtonStyle: Self {
        .init(
            textColor: DS.Color.Text.norm,
            fontWeight: .regular,
            backgroundColor: DS.Color.InteractionWeak.norm,
            pressedBackgroundColor: DS.Color.InteractionWeak.pressed
        )
    }

}
