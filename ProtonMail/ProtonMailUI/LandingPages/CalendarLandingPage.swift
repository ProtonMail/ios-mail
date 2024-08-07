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

public struct CalendarLandingPage: View {
    @Environment(\.openURL)
    private var openURL

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    public init() {
    }

    public var body: some View {
        PartialOverlayActionSheet { dismiss in
            VStack {
                VStack(spacing: 16) {
                    IconProvider.calendarWordmarkNoBackground
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                        .colorScheme(.dark)

                    Text(L10n.CalendarLandingPage.headline)
                        .font(Font(UIFont.adjustedFont(forTextStyle: .title1, weight: .bold)))
                        .foregroundColor(ColorProvider.SidebarTextNorm)

                    Text(L10n.CalendarLandingPage.subheadline)
                        .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                        .foregroundColor(ColorProvider.SidebarTextWeak)
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 40)

                Button(L10n.CalendarLandingPage.getCalendar) {
                    dismiss()
                    openURL(.AppStore.calendar)
                }
                .buttonStyle(CTAButtonStyle())

                Spacer()
                    .frame(height: 34)

                if verticalSizeClass != .compact {
                    Image(.calendarLandingPage)
                        .resizable()
                        .scaledToFit()
                }
            }
        }
    }
}

#Preview {
    CalendarLandingPage()
}
