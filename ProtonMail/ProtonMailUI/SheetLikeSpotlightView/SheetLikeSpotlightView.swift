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

@MainActor
public struct SheetLikeSpotlightView: View {
    public let config: HostingProvider

    let buttonTitle: String
    private var closeAction: ((UIViewController?, Bool) -> Void)?
    // iPhone 15 Plus
    let maxWidthForIPhone: CGFloat = 430
    let message: String
    let spotlightImage: ImageResource
    let title: String
    @State var isVisible = false
    private let imageAlignBottom: Bool
    private let maxHeightOfTheImage: CGFloat?
    private let showNewBadge: Bool
    private let closingMethods: Set<ClosingMethod>

    init(
        config: HostingProvider,
        buttonTitle: String,
        closeAction: ((UIViewController?, Bool) -> Void)? = nil,
        message: String,
        spotlightImage: ImageResource,
        title: String,
        isVisible: Bool = false,
        imageAlignBottom: Bool = false,
        maxHeightOfTheImage: CGFloat? = nil,
        showNewBadge: Bool = false,
        closingMethods: Set<ClosingMethod> = [.xInCorner]
    ) {
        self.config = config
        self.buttonTitle = buttonTitle
        self.closeAction = closeAction
        self.message = message
        self.spotlightImage = spotlightImage
        self.title = title
        self.isVisible = isVisible
        self.imageAlignBottom = imageAlignBottom
        self.maxHeightOfTheImage = maxHeightOfTheImage
        self.showNewBadge = showNewBadge
        self.closingMethods = closingMethods
    }

    public var body: some View {
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

                VStack {
                    if imageAlignBottom {
                        Spacer()
                    }
                    Image(spotlightImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, 28)
                        .frame(maxHeight: maxHeightOfTheImage)
                }

                HStack(alignment: .top) {
                    if closingMethods.contains(.xInCorner) {
                        Button(action: {
                            dismissView()
                        }, label: {
                            Image(uiImage: IconProvider.cross)
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(ColorProvider.IconNorm)
                                .position(CGPoint(x: 12, y: 4))
                        })
                    }

                    if showNewBadge {
                        Spacer()

                        Text(L10n.Spotlight.new)
                            .foregroundColor(ColorProvider.TextAccent)
                            .font(Font(UIFont.adjustedFont(forTextStyle: .caption2, weight: .bold)))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(ColorProvider.InteractionNormDisabled.opacity(0.4))
                            .clipShape(Capsule())
                    }
                }
                .padding([.top, .trailing], 24)
                .padding(.leading, 16)
            }
            .frame(maxHeight: 169)
            .padding(.bottom, 24)

            Text(title)
                .padding(.bottom, 8)
                .padding(.horizontal, 8)
                .foregroundColor(ColorProvider.TextNorm)
                .font(Font(UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)))
                .multilineTextAlignment(.center)

            Text(message)
                .padding([.horizontal, .bottom], 16)
                .foregroundColor(ColorProvider.TextWeak)
                .font(Font(UIFont.adjustedFont(forTextStyle: .subheadline)))
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)

            Button(action: {
                dismissView(didTapActionButton: true)
            }, label: {
                Text(buttonTitle)
                    .frame(width: 327, height: 48)
                    .font(Font(UIFont.adjustedFont(forTextStyle: .body)))
                    .background(ColorProvider.InteractionNorm)
                    .foregroundColor(Color.white)
            })
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if closingMethods.contains(.dismissButton) {
                Button(action: {
                    dismissView()
                }, label: {
                    Text(LocalString._general_dismiss_button)
                })
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ColorProvider.BrandNorm)
                .padding(.top, 16)
            }

            Spacer()
                .frame(height: 32)
        }
    }

    private func dismissView(didTapActionButton: Bool = false) {
        withAnimation(.easeInOut(duration: 0.25)) {
            isVisible.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.closeAction?(config.hostingController, didTapActionButton)
        }
    }
}

extension SheetLikeSpotlightView {
    enum ClosingMethod {
        case xInCorner
        case dismissButton
    }
}

#Preview {
    SheetLikeSpotlightView(
        config: HostingProvider(),
        buttonTitle: "Got it",
        message: "Set when an email should reappear in your inbox with the snooze feature, now available in the toolbar.",
        spotlightImage: .jumpToNextSpotlight,
        title: "Snooze it for later",
        imageAlignBottom: true,
        closingMethods: [.xInCorner, .dismissButton]
    )
}
