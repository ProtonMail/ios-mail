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

import InboxCore
import InboxIAP
import SwiftUI
import proton_app_uniffi

struct IntroductionViewModifier: ViewModifier {
    @EnvironmentObject private var upsellCoordinator: UpsellCoordinator
    @Environment(\.upsellEligibility) private var upsellEligibility

    private let dependencies: Dependencies

    @State private var state = ViewState()

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func body(content: Content) -> some View {
        content
            .sheet(
                isPresented: $state.isOnboardingPresented,
                onDismiss: onboardingScreenDismissed,
                content: { OnboardingScreen() }
            )
            .sheet(
                isPresented: $state.isNotificationPromptPresented,
                content: {
                    NotificationAuthorizationPrompt(
                        trigger: .onboardingFinished,
                        userDidRespond: userDidRespondToAuthorizationRequest
                    )
                }
            )
            .sheet(
                item: $state.upsellPresented,
                onDismiss: upsellDismissed,
                content: { upsellScreenModel in
                    UpsellScreen(model: upsellScreenModel)
                }
            )
            .sheet(
                item: $state.onboardingUpsellPresented,
                onDismiss: upsellDismissed,
                content: { upsellScreenModel in
                    OnboardingUpsellScreen(model: upsellScreenModel)
                }
            )
            .sheet(
                isPresented: $state.isWhatsNewScreenPresented,
                onDismiss: whatsNewScreenDismissed,
                content: {
                    WhatsNewScreen()
                }
            )
            .onAppear {
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    await presentAppropriateIntroductoryView()
                }
            }
            .onChange(of: upsellEligibility) { _, newValue in
                if case .eligible = newValue {
                    Task {
                        await presentAppropriateIntroductoryView()
                    }
                }
            }
    }

    private func calculateIntroductionProgress() async -> IntroductionProgress {
        if !dependencies.userDefaults[.hasSeenAlphaOnboarding] {
            .onboarding
        } else if await dependencies.notificationAuthorizationStore.shouldRequestAuthorization(trigger: .onboardingFinished) {
            .notifications
        } else if case .eligible(let upsellType) = upsellEligibility, !dependencies.userDefaults[.hasSeenOnboardingUpsell(ofType: upsellType)] {
            .upsell(upsellType)
        } else if dependencies.userDefaults[.lastWhatsNewVersion] == nil {
            .whatsNew
        } else {
            .finished
        }
    }

    private func presentAppropriateIntroductoryView() async {
        let introductionProgress = await calculateIntroductionProgress()

        state.isOnboardingPresented = introductionProgress == .onboarding
        state.isNotificationPromptPresented = introductionProgress == .notifications
        state.isWhatsNewScreenPresented = introductionProgress == .whatsNew

        switch introductionProgress {
        case .onboarding, .notifications, .whatsNew:
            // handled above
            break
        case .upsell(let upsellType):
            do {
                switch upsellType {
                case .standard:
                    state.onboardingUpsellPresented = try await upsellCoordinator.presentOnboardingUpsellScreen()
                case .blackFriday:
                    state.upsellPresented = try await upsellCoordinator.presentUpsellScreen(
                        entryPoint: .postOnboarding,
                        upsellType: upsellType
                    )
                }
            } catch {
                AppLogger.log(error: error, category: .payments)
                upsellDismissed()
            }
        case .finished:
            break
        }
    }

    private func whatsNewScreenDismissed() {
        dependencies.userDefaults[.lastWhatsNewVersion] = NewFeatureIntroduction.whatsNewVersion

        Task {
            await presentAppropriateIntroductoryView()
        }
    }

    private func onboardingScreenDismissed() {
        dependencies.userDefaults[.hasSeenAlphaOnboarding] = true

        Task {
            await presentAppropriateIntroductoryView()
        }
    }

    private func userDidRespondToAuthorizationRequest(accepted: Bool) {
        Task {
            await dependencies.notificationAuthorizationStore.userDidRespondToAuthorizationRequest(accepted: accepted)
            await presentAppropriateIntroductoryView()
        }
    }

    private func upsellDismissed() {
        if case .eligible(let upsellType) = upsellEligibility {
            dependencies.userDefaults[.hasSeenOnboardingUpsell(ofType: upsellType)] = true
        }

        // ensure that the standard onboarding upsell will never be shown even if a promo upsell has been shown in its place
        dependencies.userDefaults[.hasSeenOnboardingUpsell(ofType: .standard)] = true

        Task {
            await presentAppropriateIntroductoryView()
        }
    }
}

extension IntroductionViewModifier {
    struct Dependencies {
        let notificationAuthorizationStore: NotificationAuthorizationStore
        let userDefaults: UserDefaults
    }

    enum IntroductionProgress: Equatable {
        case onboarding
        case notifications
        case upsell(UpsellType)
        case whatsNew
        case finished
    }

    struct ViewState {
        var isOnboardingPresented = false
        var isNotificationPromptPresented = false
        var isWhatsNewScreenPresented = false
        var upsellPresented: UpsellScreenModel?
        var onboardingUpsellPresented: OnboardingUpsellScreenModel?
    }
}

extension View {
    func introductionViews(dependencies: IntroductionViewModifier.Dependencies) -> some View {
        modifier(IntroductionViewModifier(dependencies: dependencies))
    }
}
