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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

public struct UpsellScreen: View {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @EnvironmentObject private var toastStateStore: ToastStateStore

    @State private var model: UpsellScreenModel

    private let headerHeight: CGFloat = 60

    public init(model: UpsellScreenModel) {
        self.model = model
    }

    public var body: some View {
        sizeClassDependentBody
            .background(background)
            .foregroundStyle(Color.white)
            .mask {
                VStack(spacing: .zero) {
                    LinearGradient.fading
                        .frame(height: headerHeight)

                    Color.black
                }
            }
            .overlay(alignment: .top) {
                header
            }
            .ignoresSafeArea(edges: [.bottom])
            .interactiveDismissDisabled()
            .preferredColorScheme(.dark)
            .colorScheme(.light)
    }

    @ViewBuilder
    private var background: some View {
        if model.isPromo {
            DS.Images.Upsell.BlackFriday.background.image.resizable()
        } else {
            LinearGradient.screenBackground
        }
    }

    @ViewBuilder
    private var sizeClassDependentBody: some View {
        if verticalSizeClass == .compact {
            HStack {
                infoSection

                interactiveArea
                    .padding(.top, headerHeight)
            }
        } else {
            VStack(spacing: .zero) {
                infoSection

                Divider()
                    .overlay(Color.white.opacity(0.12))

                interactiveArea
                    .padding(.top, DS.Spacing.large)
                    .background(BlurredBackground(fallbackBackgroundColor: nil))
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Image(symbol: .xmarkCircleFill)
                    .font(.system(size: 30))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color(hex: "3B2D53"))
                    .square(size: 44)
            }
        }
        .frame(height: headerHeight)
    }

    // MARK: info section

    @ViewBuilder
    private var infoSection: some View {
        let coordinateSpaceName = UUID().uuidString

        ScrollView(showsIndicators: false) {
            VStack(spacing: .zero) {
                if verticalSizeClass != .compact {
                    logo

                    Spacer.exactly(DS.Spacing.extraLarge)
                }

                if let title = model.title {
                    titleView(title: title)

                    Spacer.exactly(DS.Spacing.standard)
                }

                if let subtitle = model.subtitle {
                    subtitleView(subtitle: subtitle)

                    Spacer.exactly(DS.Spacing.huge)
                }

                PlanComparisonGrid(highlightStroke: model.highlightStroke)
            }
            .padding(.top, headerHeight)
            .padding(.bottom, DS.Spacing.extraLarge)
            .onGeometryChange(
                for: CGFloat.self,
                of: { -$0.frame(in: .named(coordinateSpaceName)).minY },
                action: model.scrollingOffsetDidChange
            )
        }
        .scrollClipDisabled(!reduceTransparency)
        .coordinateSpace(name: coordinateSpaceName)
        .padding(.horizontal, DS.Spacing.extraLarge)
    }

    private var logo: some View {
        Image(model.logo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: model.logoHeight)
            .padding(.horizontal, model.logoHorizontalPadding)
            .scaleEffect(model.logoScaleFactor)
            .opacity(model.logoOpacity)
    }

    private func titleView(title: LocalizedStringResource) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
    }

    private func subtitleView(subtitle: LocalizedStringResource) -> some View {
        Text(subtitle)
            .font(.callout)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: interactive area

    private var interactiveArea: some View {
        VStack(spacing: .zero) {
            if model.planInstances.count > 1 {
                chooseYourPlanPrompt
            }

            ZStack {
                purchasingOptions
                    .visible(!model.isBusy)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .visible(model.isBusy)
            }

            Spacer.exactly(DS.Spacing.standard)

            autoRenewalNotice
        }
        .padding(.horizontal, DS.Spacing.large)
        .padding(.bottom, DS.Spacing.extraLarge)
        .multilineTextAlignment(.center)
    }

    private var chooseYourPlanPrompt: some View {
        Text(L10n.chooseSubscription)
            .font(.footnote)
            .fontWeight(.semibold)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var purchasingOptions: some View {
        VStack(spacing: .zero) {
            if model.isPromo {
                SubscriptionPeriodRadioButton(
                    planInstance: model.planInstances[0],
                    isSelected: false
                ) {}
            } else {
                SubscriptionPeriodRadioGroup(
                    planInstances: model.planInstances,
                    selectedInstanceID: $model.selectedInstanceId
                )
            }

            Spacer.exactly(DS.Spacing.moderatelyLarge)

            getPlanButton
        }
    }

    private var getPlanButton: some View {
        Button(L10n.getPlan(named: model.planName).string) {
            Task {
                await model.onPurchaseTapped(toastStateStore: toastStateStore, dismiss: dismiss.callAsFunction)
            }
        }
        .buttonStyle(BigButtonStyle(flavor: .inverted(backgroundColorOverride: model.ctaBackgroundOverride)))
    }

    private var autoRenewalNotice: some View {
        Text(model.autoRenewalNotice)
            .font(.caption)
            .foregroundStyle(Color.white.opacity(0.9))
    }
}

#Preview("regular") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UpsellScreen(model: .preview(entryPoint: .mailboxTopBar))
        }
        .environmentObject(ToastStateStore(initialState: .initial))
}

#Preview("black friday") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UpsellScreen(model: .preview(entryPoint: .mailboxTopBarPromo))
        }
        .environmentObject(ToastStateStore(initialState: .initial))
}
