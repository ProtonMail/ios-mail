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
                title: "Transformed from the ground up".notLocalized.stringResource,
                subtitle: "Completely reengineered on Rust architecture, the new Proton Mail is rebuilt for performance, user experience, and scalability.".notLocalized.stringResource
            ),
            .init(
                image: DS.Images.onboardingSecondPage,
                title: "New inbox unboxed".notLocalized.stringResource,
                subtitle: "We’re excited to unveil the vibrant new design and improved user experience. For now, you can preview the new list and message views.".notLocalized.stringResource
            ),
            .init(
                image: DS.Images.onboardingThirdPage,
                title: "Your feedback is key".notLocalized.stringResource,
                subtitle: "We’re rolling out all the features in the next months. Please continue to test the app and let us know how we can make it better!".notLocalized.stringResource
            )
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
    @State var state: ViewState
    @State private var totalHeight: CGFloat = 1

    init(selectedPageIndex: Int = 0) {
        _state = .init(initialValue: .init(selectedPageIndex: selectedPageIndex))
    }

    var didAppear: ((Self) -> Void)?

    // MARK: - View

    var body: some View {
        ZStack {
            DS.Color.Background.secondary.ignoresSafeArea()
            VStack(spacing: DS.Spacing.extraLarge) {
                spacing(height: DS.Spacing.small)
                header
                pages
                dotsIndexIndicator
                actionButton
                spacing(height: DS.Spacing.extraLarge)
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .edgesIgnoringSafeArea(.all)
                        .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                        .onPreferenceChange(HeightPreferenceKey.self) { value in
                            totalHeight = value
                        }
                }
            )
        }
        .pickerViewStyle([.height(totalHeight)])
        .onAppear { didAppear?(self) }
        .accessibilityElement()
        .accessibilityIdentifier(OnboardingScreenIdentifiers.rootItem)
    }

    // MARK: - Private

    private var header: some View {
        Text("Introducing our next-gen app!".notLocalized)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(DS.Color.Text.norm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, DS.Spacing.large)
    }

    private var pages: some View {
        HeightPreservingTabView(selection: $state.selectedPageIndex) {
            ForEachEnumerated(state.pages, id: \.element) { model, index in
                OnboardingPageView(model: model).tag(index)
            }
        }
        .animation(.easeIn, value: state.selectedPageIndex)
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private var dotsIndexIndicator: some View {
        OnboardingDotsIndexView(
            pagesCount: state.pages.count,
            selectedPageIndex: state.selectedPageIndex,
            onTap: { selectedIndex in state = state.copy(\.selectedPageIndex, to: selectedIndex) }
        )
    }

    private var actionButton: some View {
        Button(
            action: {
                if !state.hasNextPage {
                    dismiss()
                }

                state = state
                    .copy(\.selectedPageIndex, to: min(state.selectedPageIndex + 1, state.maxPageIndex))
            },
            label: {
                Text(state.hasNextPage ? "Next".notLocalized : "Start testing".notLocalized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DS.Color.Text.inverted)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(DS.Color.InteractionBrand.norm, in: RoundedRectangle(cornerRadius: DS.Radius.huge))
                    .padding(.horizontal, DS.Spacing.large)
            }
        )
        .accessibilityIdentifier(OnboardingScreenIdentifiers.actionButton)
    }

    private var hasNextPage: Bool {
        state.selectedPageIndex < state.pages.count - 1
    }

    private func spacing(height: CGFloat) -> some View {
        Spacer().frame(height: height)
    }
}

/// A variant of `TabView` that sets an appropriate `height` on its frame based on content.
private struct HeightPreservingTabView<SelectionValue: Hashable, Content: View>: View {
    let selection: Binding<SelectionValue>?
    @ViewBuilder let content: () -> Content

    @State private var height: CGFloat = .zero
    /// `minHeight` needs to start as something non-zero or we won't measure the interior content height
    private let minHeight: CGFloat = 1

    var body: some View {
        TabView(selection: selection) {
            content()
                .background {
                    GeometryReader { reader in
                        Color.clear
                            .preference(key: TabViewHeightPreference.self, value: reader.frame(in: .local).height)
                    }
                }
        }
        .frame(minHeight: minHeight)
        .frame(height: height)
        .onPreferenceChange(TabViewHeightPreference.self) { height in
            self.height = height
        }
    }
}

private struct TabViewHeightPreference: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    OnboardingScreen()
}

private struct OnboardingScreenIdentifiers {
    static let rootItem = "onboarding.rootItem"
    static let actionButton = "onboarding.actionButton"
}
