// Copyright (c) 2023 Proton Technologies AG
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

struct SheetLikeSpotlightView: View {
    let config = HostingProvider()

    let buttonTitle: String
    var closeAction: ((UIViewController?) -> Void)?
    // iPhone 15 Plus
    let maxWidthForIPhone: CGFloat = 430
    let message: String
    let spotlightImage: UIImage
    let title: String
    @State var isVisible = false

    var body: some View {
        GeometryReader { geometry in
            if isVisible {
                ZStack {
                    // White background for safe area
                    VStack(spacing: 0) {
                        Spacer()
                        ColorProvider.BackgroundNorm
                            .ignoresSafeArea(edges: [.bottom])
                            .padding([.horizontal], 0)
                            .frame(
                                maxWidth: maxWidthForIPhone,
                                idealHeight: geometry.safeAreaInsets.bottom
                            )
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack {
                        Spacer()
                        containerView
                        .background(ColorProvider.BackgroundNorm)
                        .padding([.horizontal], 0)
                        .frame(maxWidth: maxWidthForIPhone)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .transition(
                    .asymmetric(
                        insertion: AnyTransition.move(edge: .bottom).combined(with: .opacity),
                        removal: AnyTransition.move(edge: .bottom).combined(with: .opacity)
                    )
                )
            }
        }
        .onAppear(perform: {
            withAnimation {
                isVisible.toggle()
            }
        })
    }

    private var containerView: some View {
        VStack(spacing: 0) {
            ZStack {
                ColorProvider.BackgroundSecondary
                Image(uiImage: spotlightImage)
                    .resizable()
                    .frame(width: 171, height: 97)
                Button(action: {
                    dismissView()
                }, label: {
                    Image(uiImage: IconProvider.cross)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(ColorProvider.IconNorm)
                        .position(CGPoint(x: 28, y: 28))
                })
            }
            .frame(height: 169)
            .padding(.bottom, 24)
            Text(title)
                .padding(.bottom, 8)
                .foregroundColor(ColorProvider.TextNorm)
                .font(Font(UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)))
            Text(message)
                .padding(.bottom, 16)
                .foregroundColor(ColorProvider.TextWeak)
                .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
            Button(action: {
                dismissView()
            }, label: {
                Text(buttonTitle)
                    .frame(width: 327, height: 48)
                    .font(Font(UIFont.adjustedFont(forTextStyle: .body)))
                    .background(ColorProvider.InteractionNorm)
                    .foregroundColor(Color.white)
            })
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 32)
        }
    }

    private func dismissView() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isVisible.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.closeAction?(config.hostingController)
        }
    }
}

#Preview {
    SheetLikeSpotlightView(
        buttonTitle: "Got it",
        message: "You can now set reminders for crucial emails.",
        spotlightImage: Asset.snoozeSpotlight.image,
        title: L11n.Snooze.title
    )
}
