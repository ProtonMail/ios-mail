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

struct MessageBannerView: View {
    let model: MessageBanner
    
    init(model: MessageBanner) {
        self.model = model
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.moderatelyLarge) {
            Image(DS.Icon.icFire)
                .foregroundColor(model.style.color.icon)
            Text(model.message)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundStyle(model.style.color.text)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let button = model.button {
                Button(
                    action: button.action,
                    label: {
                        Text(button.title)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundStyle(model.style.color.button.text)
                            .padding(.init(vertical: DS.Spacing.medium, horizontal: DS.Spacing.large))
                            .background(model.style.color.button.background, in: Capsule())
                    }
                )
            }
        }
        .padding(.init(
            vertical: model.button == nil ? DS.Spacing.large : DS.Spacing.mediumLight,
            horizontal: DS.Spacing.large
        ))
        .background {
            RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                .fill(model.style.color.background)
                .stroke(model.style.color.border, lineWidth: 1)
        }
        .safeAreaPadding([.horizontal, .bottom], DS.Spacing.large)
    }
}

#Preview {
    ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 0) {
            MessageBannerView(
                model: .init(
                    message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                    button: nil,
                    style: .regular
                )
            )
            MessageBannerView(
                model: .init(
                    message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                    button: nil,
                    style: .error
                )
            )
            MessageBannerView(
                model: .init(
                    message: "Lorem ipsum dolor sit amet",
                    button: .init(title: "Action", action: {}),
                    style: .regular
                )
            )
            MessageBannerView(
                model: .init(
                    message: "Lorem ipsum dolor sit amet",
                    button: .init(title: "Action", action: {}),
                    style: .error
                )
            )
            MessageBannerView(
                model: .init(
                    message: "Lorem ipsum dolor sit amet",
                    button: .init(title: "Action", action: {}),
                    style: .regular
                )
            )
            MessageBannerView(
                model: .init(
                    message: "Lorem ipsum dolor sit amet",
                    button: nil,
                    style: .error
                )
            )
        }
    }
}
