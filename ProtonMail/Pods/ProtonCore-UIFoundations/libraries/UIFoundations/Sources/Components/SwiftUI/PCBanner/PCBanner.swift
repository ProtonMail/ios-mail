//
//  PCBanner.swift
//  ProtonCore-UIFoundations - Created on 02.04.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import SwiftUI

public struct PCBanner: View {
    @Binding public var style: PCBannerStyle
    @Binding public var content: PCBannerContent

    enum Constants {
        static let verticalInset: CGFloat = 8
        static let buttonRadius: CGFloat = 8
        static let bannerRadius: CGFloat = 6
    }

    public init(style: Binding<PCBannerStyle>, content: Binding<PCBannerContent>) {
        self._style = style
        self._content = content
    }

    public var body: some View {
        HStack {
            Text(.init(content.message))
                .font(.subheadline)
                .foregroundColor(ColorProvider.TextInverted)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let buttonTitle = content.buttonTitle {
                Button(action: { content.buttonAction?() }, label: {
                    Text(buttonTitle)
                        .font(.subheadline)
                        .foregroundColor(ColorProvider.TextInverted)
                        .padding(.horizontal)
                        .padding(.vertical, Constants.verticalInset)
                        .background(style.buttonBackgroundColor)
                        .cornerRadius(Constants.buttonRadius)
                })
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(style.backgroundColor)
        .cornerRadius(Constants.bannerRadius)
    }
}

#endif
