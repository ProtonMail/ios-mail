//
//  SpringboardShortcutsService.swift
//  ProtonMail - Created on 06/08/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

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
            case .search: return .init(type: .search)
            case .favorites: return .init(type: .favorite)
            case .compose: return .init(type: .compose)
            }
        }
    }
    
    override init() {
        super.init()
        self.updateShortcuts()
        NotificationCenter.default.addObserver(forName: .didSignIn, object: nil, queue: nil, using: { [weak self] _ in self?.addShortcuts() })
        NotificationCenter.default.addObserver(forName: .didSignOut, object: nil, queue: nil, using: { [weak self] _ in self?.removeShortcuts() })
    }
    
    private func updateShortcuts() {
        if SignInManager.shared.isSignedIn() {
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
