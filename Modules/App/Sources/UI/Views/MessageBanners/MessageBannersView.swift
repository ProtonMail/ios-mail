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
import OrderedCollections
import proton_app_uniffi
import SwiftUI

struct MessageBannersView: View {
    let types: OrderedSet<MessageBanner>
    
    var body: some View {
        BannersView(model: model(from: types))
    }
    
    // MARK: - Private
    
    private func model(from types: OrderedSet<MessageBanner>) -> OrderedSet<Banner> {
        let banners: [Banner] = types.compactMap { type in
            switch type {
            case .blockedSender:
                return .init(
                    icon: DS.Icon.icCircleSlash,
                    message: "You blocked this sender",
                    size: .small(.init(title: "Unblock", action: {})),
                    style: .regular
                )
            case .phishingAttempt:
                return .init(
                    icon: DS.Icon.icHook,
                    message: "Our system flagged this as suspicious. If it is not a phishing or scam email, mark as legitimate.",
                    size: .large(.one(.init(title: "Mark as legitimate", action: {}))),
                    style: .error
                )
            case .spam:
                return .init(
                    icon: DS.Icon.icFire,
                    message: "This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded.",
                    size: .large(.one(.init(title: "Mark as legitimate", action: {}))),
                    style: .error
                )
            case .expiry:
                return regularSmallNoButton(
                    icon: DS.Icon.icTrashClock,
                    message: "This message will expire in 15 days, 5 hours, and 58 minutes"
                )
            case .autoDelete:
                return regularSmallNoButton(
                    icon: DS.Icon.icTrashClock,
                    message: "This message will auto-delete in 20 days"
                )
            case .unsubscribeNewsletter:
                return .init(
                    icon: DS.Icon.icEnvelopes,
                    message: "This message is from a mailing list.",
                    size: .small(.init(title: "Unsubscribe", action: {})),
                    style: .regular
                )
            case .scheduledSend:
                return .init(
                    icon: DS.Icon.icClockPaperPlane,
                    message: "This message will be sent tomorrow at 08:00",
                    size: .small(.init(title: "Edit", action: {})),
                    style: .regular
                )
            case .snoozed:
                return .init(
                    icon: DS.Icon.icClock,
                    message: "Snoozed until tomorrow at 09:00",
                    size: .small(.init(title: "Unsnooze", action: {})),
                    style: .regular
                )
            case .embeddedImages:
                return .init(
                    icon: DS.Icon.icCogWheel,
                    message: "Display embedded images?",
                    size: .small(.init(title: "Display", action: {})),
                    style: .regular
                )
            case .remoteContent:
                return .init(
                    icon: DS.Icon.icCogWheel,
                    message: "Download images and other remote content?",
                    size: .small(.init(title: "Download", action: {})),
                    style: .regular
                )
            }
        }
        return OrderedSet(banners)
    }
    
    private func regularSmallNoButton(icon: ImageResource, message: String) -> Banner {
        .init(icon: icon, message: message, size: .small(.none), style: .regular)
    }
}
