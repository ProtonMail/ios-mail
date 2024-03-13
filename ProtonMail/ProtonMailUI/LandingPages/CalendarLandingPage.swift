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

    @Environment(\.presentationMode)
    private var presentationMode

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    @State private var verticalOffset: CGFloat = 0

    private let cornerRadius = 20.0
    private let dragGestureDismissalThreshold = 100.0
    private let screenHeight: CGFloat

    public var body: some View {
        VStack {
            Spacer()

            VStack {
                VStack {
                    Image(.grabber)
                }
                .frame(height: 20)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.interactiveSpring) {
                                verticalOffset = max(0, value.translation.height)
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > dragGestureDismissalThreshold {
                                dismiss()
                            } else {
                                withAnimation {
                                    verticalOffset = 0
                                }
                            }
                        }
                )

                HStack {
                    CrossButton {
                        dismiss()
                    }
                    .padding(.leading, 8)
                    .padding(.vertical, 4)

                    Spacer()
                }

                VStack(spacing: 16) {
                    IconProvider.calendarWordmarkNoBackground
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                        .colorScheme(.dark)

                    Text(L11n.CalendarLandingPage.headline)
                        .font(Font(UIFont.adjustedFont(forTextStyle: .title1, weight: .bold)))
                        .foregroundColor(ColorProvider.SidebarTextNorm)

                    Text(L11n.CalendarLandingPage.subheadline)
                        .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                        .foregroundColor(ColorProvider.SidebarTextWeak)
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 40)

                Button(L11n.CalendarLandingPage.getCalendar) {
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
            .background(ColorProvider.SidebarBackground)
            .colorScheme(.light)
            .padding(.bottom, cornerRadius)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .circular))
            .padding(.bottom, -cornerRadius)
            .offset(y: verticalOffset)
            .ignoresSafeArea(edges: [.bottom])
        }
        .ignoresSafeArea(edges: [.bottom])
        .onAppear {
            verticalOffset = screenHeight

            withAnimation {
                verticalOffset = 0
            }
        }
    }

    @MainActor
    public init() {
        screenHeight = UIScreen.main.bounds.height
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.25)) {
            verticalOffset = screenHeight
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
