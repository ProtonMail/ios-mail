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

import InboxCore
import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct OnboardingScreen: View {
    struct ViewState: Copying {
        let pages: [OnboardingPage] = [
            .init(
                image: DS.Images.onboardingFirstPage,
                title: L10n.Onboarding.FirstPage.title,
                subtitle: L10n.Onboarding.FirstPage.subtitle
            ),
            .init(
                image: DS.Images.onboardingSecondPage,
                title: L10n.Onboarding.SecondPage.title,
                subtitle: L10n.Onboarding.SecondPage.subtitle
            ),
            .init(
                image: DS.Images.onboardingThirdPage,
                title: L10n.Onboarding.ThirdPage.title,
                subtitle: L10n.Onboarding.ThirdPage.subtitle
            ),
        ]
        var selectedPageIndex: Int

        var hasNextPage: Bool {
            selectedPageIndex < maxPageIndex
        }

        var maxPageIndex: Int {
            pages.count - 1
        }
    }

    @Environment(\.dismissTestable) var dismiss: Dismissable
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.userInterfaceIdiom) private var userInterfaceIdiom
    @State var state: ViewState
    @State private var totalHeight: CGFloat = 1

    private var isLandscapePhone: Bool {
        userInterfaceIdiom == .phone && verticalSizeClass == .compact
    }

    init(selectedPageIndex: Int = 0) {
        _state = .init(initialValue: .init(selectedPageIndex: selectedPageIndex))
    }

    var didAppear: ((Self) -> Void)?

    // MARK: - View

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DS.Color.Background.secondary.ignoresSafeArea()
                VStack(spacing: DS.Spacing.extraLarge) {
                    spacing(height: DS.Spacing.small)
                    pages(width: geometry.size.width, safeAreaPadding: geometry.safeAreaInsets.leading)
                    dotsIndexIndicator
                    actionButton
                    spacing(height: DS.Spacing.extraLarge)
                }
                .onGeometryChange(
                    for: CGFloat.self,
                    of: \.size.height,
                    action: { height in totalHeight = height }
                )
            }
            .pickerViewStyle([.height(totalHeight)])
            .onAppear { didAppear?(self) }
            .accessibilityElement()
            .accessibilityIdentifier(OnboardingScreenIdentifiers.rootItem)
        }
    }

    // MARK: - Private

    private func pages(width: CGFloat, safeAreaPadding: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: .zero) {
                    ForEachEnumerated(state.pages, id: \.element) { model, index in
                        OnboardingPageView(
                            isLandscapePhone: isLandscapePhone,
                            safeAreaPadding: safeAreaPadding,
                            model: model
                        )
                        .tag(index)
                        .id(index)
                        .frame(width: width + safeAreaPadding * 2)
                    }
                }
                .scrollTargetLayout()
            }
            .ignoresSafeArea(edges: .horizontal)
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: selectedPageIndex)
            .animation(.easeIn, value: state.selectedPageIndex)
            .onLoad { proxy.scrollTo(state.selectedPageIndex) }
            .onChange(of: isLandscapePhone) { _, _ in
                proxy.scrollTo(state.selectedPageIndex)
            }
        }
    }

    private var selectedPageIndex: Binding<Int?> {
        .init(
            get: { state.selectedPageIndex },
            set: { newPageIndex in
                if let pageIndex = newPageIndex {
                    state.selectedPageIndex = pageIndex
                }
            }
        )
    }

    private var dotsIndexIndicator: some View {
        OnboardingDotsIndexView(
            pagesCount: state.pages.count,
            selectedPageIndex: state.selectedPageIndex,
            onTap: { selectedIndex in state = state.copy(\.selectedPageIndex, to: selectedIndex) }
        )
    }

    private var actionButton: some View {
        Button(state.hasNextPage ? L10n.Onboarding.nextButtonTitle.string : L10n.Onboarding.startButtonTitle.string) {
            if !state.hasNextPage {
                dismiss()
            }

            state =
                state
                .copy(\.selectedPageIndex, to: min(state.selectedPageIndex + 1, state.maxPageIndex))
        }
        .buttonStyle(BigButtonStyle())
        .padding(.horizontal, DS.Spacing.large)
        .accessibilityIdentifier(OnboardingScreenIdentifiers.actionButton)
    }

    private func spacing(height: CGFloat) -> some View {
        Spacer().frame(height: height)
    }
}

#Preview {
    OnboardingScreen()
}

private struct OnboardingScreenIdentifiers {
    static let rootItem = "onboarding.rootItem"
    static let actionButton = "onboarding.actionButton"
}
