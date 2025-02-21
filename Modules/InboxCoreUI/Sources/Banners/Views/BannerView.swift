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

struct BannerView: View {
    let model: Banner
    
    init(model: Banner) {
        self.model = model
    }
    
    var body: some View {
        container()
            .background {
                RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                    .fill(model.style.color.background)
                    .stroke(model.style.color.border, lineWidth: 1)
            }
            .safeAreaPadding([.horizontal, .bottom], DS.Spacing.large)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private func container() -> some View {
        switch model.size {
        case .small(let button):
            HStack(alignment: .center, spacing: DS.Spacing.moderatelyLarge) {
                iconText(icon: model.icon, text: model.message, style: model.style.color.content, lineLimit: 2)
                if let button = button {
                    smallButton(model: button, style: model.style.color.button)
                }
            }
            .padding(.init(
                vertical: button == nil ? DS.Spacing.large : DS.Spacing.mediumLight,
                horizontal: DS.Spacing.large
            ))
        case .large(let type):
            VStack(alignment: .leading, spacing: DS.Spacing.medium) {
                HStack(alignment: .top, spacing: DS.Spacing.moderatelyLarge) {
                    iconText(icon: model.icon, text: model.message, style: model.style.color.content, lineLimit: nil)
                }
                switch type {
                case .one(let button):
                    largeButton(model: button, style: model.style.color.button)
                case .two(let left, let right):
                    HStack(alignment: .center, spacing: DS.Spacing.standard) {
                        largeButton(model: left, style: model.style.color.button)
                        largeButton(model: right, style: model.style.color.button)
                    }
                }
            }
            .padding(.init(vertical: DS.Spacing.medium, horizontal: DS.Spacing.large))
        }
    }
    
    private func iconText(
        icon: ImageResource,
        text: String,
        style: Banner.ContentStyle,
        lineLimit: Int?
    ) -> some View {
        Group {
            Image(icon)
                .foregroundColor(style.icon)
            Text(text)
                .font(.footnote)
                .fontWeight(.regular)
                .foregroundStyle(style.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(lineLimit)
        }
    }
    
    private func smallButton(model: Banner.Button, style: Banner.ButtonStyle) -> some View {
        button(model: model, style: style, maxWidth: nil)
    }
    
    private func largeButton(model: Banner.Button, style: Banner.ButtonStyle) -> some View {
        button(model: model, style: style, maxWidth: .infinity)
    }
    
    private func button(
        model: Banner.Button,
        style: Banner.ButtonStyle,
        maxWidth: CGFloat?
    ) -> some View {
        Button(
            action: model.action,
            label: {
                Text(model.title)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(style.text)
                    .frame(maxWidth: maxWidth)
                    .padding(.init(vertical: DS.Spacing.medium, horizontal: DS.Spacing.large))
                    .background(style.background, in: Capsule())
            }
        )
    }
}

#Preview {
    ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 0) {
            BannerView(
                model: .init(
                    icon: DS.Icon.icFire,
                    message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                    size: .small(nil),
                    style: .regular
                )
            )
            BannerView(
                model: .init(
                    icon: DS.Icon.icFire,
                    message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
                    size: .small(nil),
                    style: .error
                )
            )
            BannerView(
                model: .init(
                    icon: DS.Icon.icFire,
                    message: "Lorem ipsum dolor sit amet",
                    size: .small(.init(title: "Action", action: {})),
                    style: .regular
                )
            )
            BannerView(
                model: .init(
                    icon: DS.Icon.icFire,
                    message: "Lorem ipsum dolor sit amet",
                    size: .small(.init(title: "Action", action: {})),
                    style: .error
                )
            )
            BannerView(
                model: .init(
                    icon: DS.Icon.icFire,
                    message: "Lorem ipsum dolor sit amet",
                    size: .small(.init(title: "Action", action: {})),
                    style: .regular
                )
            )
            BannerView(
                model: .init(
                    icon: DS.Icon.icFire,
                    message: "Lorem ipsum dolor sit amet",
                    size: .small(nil),
                    style: .error
                )
            )
            BannerView(
                model: .init(
                    icon: DS.Icon.icFire,
                    message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam tempus ipsum non purus pretium.",
                    size: .large(.one(.init(title: "Action", action: {}))),
                    style: .regular
                )
            )
            BannerView(
                model: .init(
                    icon: DS.Icon.icFire,
                    message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam tempus ipsum non purus pretium.",
                    size: .large(
                        .two(left: .init(title: "Left", action: {}), right: .init(title: "Right", action: {}))
                    ),
                    style: .error
                )
            )
        }
    }
}
