//
//  SpringboardShortcutsService.swift
//  Proton Mail - Created on 06/08/2019.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import LifetimeTracker
import ProtonCore_UIFoundations
import UIKit

class SpringboardShortcutsService: NSObject, Service {
    enum QuickActions: String, CaseIterable {
        case search, favorites, compose

        var deeplink: DeepLink {
            switch self {
            case .search:
                let deeplink = DeepLink(String(describing: MenuViewController.self))
                deeplink.append(DeepLink.Node(name: String(describing: MailboxViewController.self), value: Message.Location.inbox))
                deeplink.append(.init(name: String(describing: SearchViewController.self)))
                return deeplink
            case .favorites:
                let deeplink = DeepLink(String(describing: MenuViewController.self))
                deeplink.append(DeepLink.Node(name: String(describing: MailboxViewController.self), value: Message.Location.starred))
                return deeplink
            case .compose:
                let deeplink = DeepLink(String(describing: MenuViewController.self))
                deeplink.append(DeepLink.Node(name: String(describing: MailboxViewController.self), value: Message.Location.inbox))
                deeplink.append(DeepLink.Node(name: String(describing: ComposeContainerViewController.self)))
                return deeplink
            }
        }

        var localization: String {
            switch self {
            case .search: return LocalString._springboard_shortcuts_search
            case .favorites: return LocalString._springboard_shortcuts_starred
            case .compose: return LocalString._springboard_shortcuts_composer
            }
        }

        var icon: UIApplicationShortcutIcon {
            switch self {
            case .search: return .init(templateImageName: "ic-magnifier")
            case .favorites: return .init(templateImageName: "ic-star-filled")
            case .compose: return .init(templateImageName: "ic-pen-square")
            }
        }
    }

    override init() {
        super.init()
        self.updateShortcuts()
        NotificationCenter.default.addObserver(forName: .didSignIn, object: nil, queue: nil, using: { [weak self] _ in self?.addShortcuts() })
        NotificationCenter.default.addObserver(forName: .didSignOut, object: nil, queue: nil, using: { [weak self] _ in self?.removeShortcuts() })
        trackLifetime()
    }

    private func updateShortcuts() {
        if sharedServices.get(by: UsersManager.self).hasUsers() {
            self.addShortcuts()
        } else {
            self.removeShortcuts()
        }
    }

    private func addShortcuts() {
        UIApplication.shared.shortcutItems = QuickActions.allCases.compactMap {
            guard let deeplink = try? JSONEncoder().encode($0.deeplink) else {
                assert(false, "Broken springboard shortcut item at \(#file):\(#line)")
                return nil
            }
            return UIMutableApplicationShortcutItem(type: $0.rawValue,
                                                    localizedTitle: $0.localization,
                                                    localizedSubtitle: nil,
                                                    icon: $0.icon,
                                                    userInfo: ["deeplink": deeplink as NSSecureCoding])
        }
    }
    private func removeShortcuts() {
        UIApplication.shared.shortcutItems = []
    }
}

extension SpringboardShortcutsService: LifetimeTrackable {
    static var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }
}
