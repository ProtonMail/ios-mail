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

import Combine
import InboxCore
import InboxCoreUI
import InboxDesignSystem
import OrderedCollections
import proton_app_uniffi
import SwiftUI

struct MessageBannersView: View {
    let types: OrderedSet<MessageBanner>
    let timerPublisher: Publishers.Autoconnect<Timer.TimerPublisher>
    
    @State private var currentDate: Date = DateEnvironment.currentDate()

    init(types: OrderedSet<MessageBanner>, timer: Timer.Type) {
        self.types = types
        self.timerPublisher = timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
    
    var body: some View {
        BannersView(model: model(from: types, currentDate: currentDate))
            .onReceive(timerPublisher) { _ in
                currentDate = DateEnvironment.currentDate()
            }
    }
    
    // MARK: - Private
    
    private func model(from types: OrderedSet<MessageBanner>, currentDate: Date) -> OrderedSet<Banner> {
        let banners: [Banner] = types.compactMap { type in
            switch type {
            case .blockedSender:
                return .init(
                    icon: DS.Icon.icCircleSlash,
                    message: L10n.MessageBanner.blockedSenderTitle,
                    size: .small(.init(title: L10n.MessageBanner.blockedSenderAction, action: {})),
                    style: .regular
                )
            case .phishingAttempt:
                return .init(
                    icon: DS.Icon.icHook,
                    message: L10n.MessageBanner.phishingAttemptTitle,
                    size: .large(.one(.init(title: L10n.MessageBanner.phishingAttemptAction, action: {}))),
                    style: .error
                )
            case .spam:
                return .init(
                    icon: DS.Icon.icFire,
                    message: L10n.MessageBanner.spamTitle,
                    size: .large(.one(.init(title: L10n.MessageBanner.spamAction, action: {}))),
                    style: .error
                )
            case .expiry(let timestamp):
                let timestamp = Int(timestamp)
                let duration = MessageExpiryDurationCalculator.duration(from: timestamp, currentDate: currentDate)
                let formattedTime = MessageExpiryTimeFormatter.string(from: timestamp, currentDate: currentDate)

                return smallNoButton(
                    icon: DS.Icon.icTrashClock,
                    message: L10n.MessageBanner.expiryTitle(formattedTime: formattedTime),
                    style: duration.isOneMinuteOrMore ? .regular : .error
                )
            case .autoDelete:
                return smallNoButton(
                    icon: DS.Icon.icTrashClock,
                    message: L10n.MessageBanner.autoDeleteTitle(formattedTime: "20 days"),
                    style: .regular
                )
            case .unsubscribeNewsletter:
                return .init(
                    icon: DS.Icon.icEnvelopes,
                    message: L10n.MessageBanner.unsubscribeNewsletterTitle,
                    size: .small(.init(title: L10n.MessageBanner.unsubscribeNewsletterAction, action: {})),
                    style: .regular
                )
            case .scheduledSend:
                return .init(
                    icon: DS.Icon.icClockPaperPlane,
                    message: L10n.MessageBanner.scheduledSendTitle(formattedTime: "tomorrow at 08:00"),
                    size: .small(.init(title: L10n.MessageBanner.scheduledSendAction, action: {})),
                    style: .regular
                )
            case .snoozed:
                return .init(
                    icon: DS.Icon.icClock,
                    message: L10n.MessageBanner.snoozedTitle(formattedTime: "tomorrow at 09:00"),
                    size: .small(.init(title: L10n.MessageBanner.snoozedAction, action: {})),
                    style: .regular
                )
            case .embeddedImages:
                return .init(
                    icon: DS.Icon.icCogWheel,
                    message: L10n.MessageBanner.embeddedImagesTitle,
                    size: .small(.init(title: L10n.MessageBanner.embeddedImagesAction, action: {})),
                    style: .regular
                )
            case .remoteContent:
                return .init(
                    icon: DS.Icon.icCogWheel,
                    message: L10n.MessageBanner.remoteContentTitle,
                    size: .small(.init(title: L10n.MessageBanner.remoteContentAction, action: {})),
                    style: .regular
                )
            }
        }
        return OrderedSet(banners)
    }
    
    private func smallNoButton(
        icon: ImageResource,
        message: LocalizedStringResource,
        style: Banner.Style
    ) -> Banner {
        .init(icon: icon, message: message, size: .small(.none), style: style)
    }
}
