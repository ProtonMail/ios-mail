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

import ProtonCoreUIFoundations
import SwiftUI

public struct ContactAutoSyncBanner: View {
    let title: String
    let buttonTitle: String
    let buttonTriggered: () -> Void
    let dismiss: () -> Void

    public init(
        title: String,
        buttonTitle: String,
        buttonTriggered: @escaping () -> Void,
        dismiss: @escaping () -> Void
    ) {
        self.title = title
        self.buttonTitle = buttonTitle
        self.buttonTriggered = buttonTriggered
        self.dismiss = dismiss
    }

    public var body: some View {
        HStack {
            Image(.contactSync)
            VStack(alignment: .leading, spacing: 8, content: {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(Color(ColorProvider.TextWeak))
                    .multilineTextAlignment(.leading)
                Button(action: {
                    buttonTriggered()
                }, label: {
                    Text(buttonTitle)
                        .foregroundColor(Color(ColorProvider.BrandNorm))
                        .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline, weight: .semibold)))
                })
            })
            VStack {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(uiImage: IconProvider.cross)
                        .renderingMode(.template)
                        .foregroundColor(ColorProvider.IconNorm)
                })
                Spacer()
            }.padding(.init(top: 4, leading: 0, bottom: 0, trailing: 0))
        }
        .padding()
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(ColorProvider.SeparatorNorm), lineWidth: 1)
        )
        .padding(.init(top: 12, leading: 16, bottom: 16, trailing: 16))
    }
}

struct ContactAutoSyncBanner_Previews: PreviewProvider {
    static var previews: some View {
        ContactAutoSyncBanner(
            title: "Automatically add new contacts from your device.",
            buttonTitle: "Enable auto-import",
            buttonTriggered: {},
            dismiss: {}
        )
        .previewLayout(.fixed(width: 393, height: 150))
    }
}
