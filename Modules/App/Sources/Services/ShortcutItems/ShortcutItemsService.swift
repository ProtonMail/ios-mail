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
import UIKit
import proton_app_uniffi

final class ShortcutItemsService: ApplicationServiceWillResignActive {
    typealias ActiveUserSession = () -> MailUserSession?
    typealias ResolveSystemLabelID = (MailUserSession, SystemLabel) async throws -> ID?

    private let activeUserSession: ActiveUserSession
    private let resolveSystemLabelID: ResolveSystemLabelID

    init(activeUserSession: @escaping ActiveUserSession, resolveSystemLabelID: @escaping ResolveSystemLabelID) {
        self.activeUserSession = activeUserSession
        self.resolveSystemLabelID = resolveSystemLabelID
    }

    convenience init(appContext: AppContext) {
        self.init(
            activeUserSession: { appContext.sessionState.userSession },
            resolveSystemLabelID: { try await resolveSystemLabelId(ctx: $0, label: $1).get() }
        )
    }

    func willResignActive() {
        Task {
            await updateShortcutItems()
        }
    }

    func updateShortcutItems() async {
        if let userSession = activeUserSession() {
            let shortcutItems = await shortcutItems(for: userSession)
            setShortcutItems(shortcutItems)
        } else {
            setShortcutItems(nil)
        }
    }

    private func shortcutItems(for userSession: MailUserSession) async -> [UIApplicationShortcutItem] {
        var shortcutItems: [UIApplicationShortcutItem] = []

        for mailShortcutItem in MailShortcutItem.allCases {
            do {
                guard let shortcutItem = try await applicationShortcutItem(for: mailShortcutItem, userSession: userSession) else {
                    continue
                }

                shortcutItems.append(shortcutItem)
            } catch {
                AppLogger.log(error: error)
            }
        }

        return shortcutItems
    }

    private func applicationShortcutItem(
        for mailShortcutItem: MailShortcutItem,
        userSession: MailUserSession
    ) async throws -> UIApplicationShortcutItem? {
        guard let route = try await route(for: mailShortcutItem, userSession: userSession) else {
            return nil
        }

        let deepLink = DeepLinkRouteCoder.encode(route: route)

        return .init(
            type: mailShortcutItem.rawValue,
            localizedTitle: mailShortcutItem.title.string,
            localizedSubtitle: nil,
            icon: mailShortcutItem.icon,
            userInfo: [
                MailShortcutItem.UserInfoDeepLinkKey: deepLink.absoluteString as NSSecureCoding
            ]
        )
    }

    private func route(for mailShortcutItem: MailShortcutItem, userSession: MailUserSession) async throws -> Route? {
        switch mailShortcutItem {
        case .search:
            return .search
        case .starred:
            let remoteSystemLabel = SystemLabel.starred

            guard let localSystemLabel = try await resolveSystemLabelID(userSession, remoteSystemLabel) else {
                return nil
            }

            return .mailbox(selectedMailbox: .systemFolder(labelId: localSystemLabel, systemFolder: remoteSystemLabel))
        case .compose:
            return .composer(fromShareExtension: false)
        }
    }

    private func setShortcutItems(_ shortcutItems: [UIApplicationShortcutItem]?) {
        UIApplication.shared.shortcutItems = shortcutItems
    }
}
