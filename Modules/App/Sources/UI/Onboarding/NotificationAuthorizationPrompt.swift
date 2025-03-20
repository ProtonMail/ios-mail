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

struct NotificationAuthorizationPrompt: View {
    private let trigger: NotificationAuthorizationRequestTrigger
    private let userDidRespond: (Bool) -> Void

    @State private var bodyHeight: CGFloat = 0

    init(trigger: NotificationAuthorizationRequestTrigger, userDidRespond: @escaping (Bool) -> Void) {
        self.trigger = trigger
        self.userDidRespond = userDidRespond
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Image(DS.Images.notificationPrompt)

            Spacer()
                .frame(height: DS.Spacing.standard)

            Text(trigger.title)
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(DS.Color.Text.norm)

            Spacer()
                .frame(height: DS.Spacing.compact)

            Text(trigger.body)
                .font(.subheadline)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
                .frame(height: DS.Spacing.jumbo)

            Button(L10n.Notifications.cta.string) {
                userDidRespond(true)
            }
            .buttonStyle(BigButtonStyle())

            Spacer()
                .frame(height: DS.Spacing.extraLarge)

            Button(L10n.Notifications.dismiss.string) {
                userDidRespond(false)
            }
            .buttonStyle(SmallButtonStyle())
        }
        .presentationDetents([.height(bodyHeight)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
        .presentationCornerRadius(DS.Radius.extraLarge)
        .padding(.horizontal, DS.Spacing.extraLarge)
        .padding(.top, DS.Spacing.huge + DS.Spacing.extraLarge)
        .background(DS.Color.Background.norm)
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { newValue in
            bodyHeight = newValue
        }
    }
}

private extension NotificationAuthorizationRequestTrigger {
    var title: LocalizedStringResource {
        switch self {
        case .onboardingFinished:
            L10n.Notifications.title1
        case .messageSent:
            L10n.Notifications.title2
        }
    }

    var body: LocalizedStringResource {
        switch self {
        case .onboardingFinished:
            L10n.Notifications.body1
        case .messageSent:
            L10n.Notifications.body2
        }
    }
}

#Preview("onboarding finished") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NotificationAuthorizationPrompt(trigger: .onboardingFinished) { accepted in
                print(accepted)
            }
        }
}

#Preview("message sent") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NotificationAuthorizationPrompt(trigger: .messageSent) { accepted in
                print(accepted)
            }
        }
}
