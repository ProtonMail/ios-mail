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

import SwiftUI

public struct NotificationAuthorizationPrompt: View {
    public let config = HostingProvider()
    private let variant: Variant
    private let enableAction: () -> Void

    public var body: some View {
        SheetLikeSpotlightView(
            config: config,
            buttonTitle: L10n.Authorization.Notifications.cta,
            closeAction: { hostingVC, didTapActionButton in
                hostingVC?.dismiss(animated: false)

                if didTapActionButton {
                    enableAction()
                }
            },
            message: variant.message,
            spotlightImage: .pushNotificationPermissionPrompt,
            title: variant.title,
            imageAlignBottom: false,
            maxHeightOfTheImage: 125,
            showNewBadge: false,
            closingMethods: [.dismissButton]
        )
    }

    public init(variant: Variant, enableAction: @escaping () -> Void) {
        self.variant = variant
        self.enableAction = enableAction
    }
}

public extension NotificationAuthorizationPrompt {
    enum Variant {
        case onboardingFinished
        case messageSent

        var title: String {
            switch self {
            case .onboardingFinished:
                L10n.Authorization.Notifications.title1
            case .messageSent:
                L10n.Authorization.Notifications.title2
            }
        }

        var message: String {
            switch self {
            case .onboardingFinished:
                L10n.Authorization.Notifications.body1
            case .messageSent:
                L10n.Authorization.Notifications.body2
            }
        }
    }
}

#Preview("onboarding finished") {
    NotificationAuthorizationPrompt(variant: .onboardingFinished) {}
}

#Preview("message sent") {
    NotificationAuthorizationPrompt(variant: .messageSent) {}
}
