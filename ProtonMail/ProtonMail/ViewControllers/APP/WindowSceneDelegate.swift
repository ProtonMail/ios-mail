//
//  WindowSceneDelegate.swift
//  Proton Mail - Created on 23/07/2019.
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

import UIKit

@available(iOS 13.0, *)
class WindowSceneDelegate: UIResponder, UIWindowSceneDelegate {
    lazy var coordinator: WindowsCoordinator = {
        if UIDevice.current.stateRestorationPolicy == .multiwindow {
            // each window scene has it's own windowCoordinator
            return WindowsCoordinator(services: sharedServices, darkModeCache: userCachedStatus)
        } else {
            // windowCoordinator is shared across whole app
            return (UIApplication.shared.delegate as? AppDelegate)!.coordinator
        }
    }()

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        _ = URLContexts.first { context in
            self.handleUrlOpen(context.url)
        }
    }

    // in case of Handoff will be called AFTER scene(_:willConnectTo:options:)
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let data = userActivity.userInfo?["deeplink"] as? Data,
            let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data) {
            self.coordinator.followDeeplink(deeplink)
        } else {
            self.coordinator.start()
        }
    }

    // will be called by system if app is foreground, otherwise shortcut is passed via scene(_:willConnectTo:options:)
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        if let data = shortcutItem.userInfo?["deeplink"] as? Data,
            let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data) {
            self.coordinator.followDeepDeeplinkIfNeeded(deeplink)
            completionHandler(true)
        } else {
            completionHandler(false)
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        self.coordinator.scene = scene

        let notificationInfo = connectionOptions.notificationResponse?.notification.request.content.userInfo
        if let userInfo = notificationInfo {
            sharedServices.get(by: PushNotificationService.self)
                            .setNotificationOptions(userInfo, fetchCompletionHandler: { /* nothing */ })
        }

        if let shortcutItem = connectionOptions.shortcutItem,
            let _ = scene as? UIWindowScene {
            handleShortcutAction(shortcutItem: shortcutItem)
            return
        } else if UIDevice.current.stateRestorationPolicy == .multiwindow,
            let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            self.scene(scene, continue: userActivity)

            _ = connectionOptions.urlContexts.first { context in
                self.handleUrlOpen(context.url)
            }

            return
        } else if connectionOptions.handoffUserActivityType != nil {
            // coordinator will be started by windowScene(_:performActionFor:completionHandler:)
            return
        }

        self.coordinator.start(launchedByNotification: notificationInfo != nil)

        // For default mail function
        _ = connectionOptions.urlContexts.first { context in
            self.handleUrlOpen(context.url)
        }
    }

    // handle the shorcut item in scene(_:willConnectTo:options:)
    func handleShortcutAction(shortcutItem: UIApplicationShortcutItem) {
        if let data = shortcutItem.userInfo?["deeplink"] as? Data,
           let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data) {
            self.coordinator.followDeeplink(deeplink)
        } else {
            self.coordinator.start()
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        UIApplication.shared.delegate?.applicationWillEnterForeground?(UIApplication.shared)
        self.coordinator.willEnterForeground()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        self.coordinator.didEnterBackground()

        // app gone background if all of scenes are background
        if UIApplication.shared.applicationState == .background ||
            nil == UIApplication.shared.openSessions.compactMap({ $0.scene }).first(where: { $0.activationState != .background }) {
            UIApplication.shared.delegate?.applicationDidEnterBackground?(UIApplication.shared)
        }
    }

    private func handleUrlOpen(_ url: URL) -> Bool {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        if ["protonmail", "mailto"].contains(urlComponents.scheme) || "mailto".caseInsensitiveCompare(urlComponents.scheme ?? "") == .orderedSame {
            var path = url.absoluteString
            if urlComponents.scheme == "protonmail" {
                path = path.preg_replace("protonmail://", replaceto: "")
            }

            let deeplink = DeepLink(String(describing: MailboxViewController.self), sender: Message.Location.inbox.rawValue)
            deeplink.append(DeepLink.Node(name: "toMailboxSegue", value: Message.Location.inbox))
            deeplink.append(DeepLink.Node(name: "toComposeMailto", value: path))
            self.coordinator.followDeepDeeplinkIfNeeded(deeplink)
            return true
        }

        guard urlComponents.host == "signup" else {
            return false
        }
        guard let queryItems = urlComponents.queryItems, let verifyObject = queryItems.filter({$0.name == "verifyCode"}).first else {
            return false
        }

        guard let code = verifyObject.value else {
            return false
        }
        /// TODO::fixme change to deeplink
        let info: [String: String] = ["verifyCode": code]
        let notification = Notification(name: .customUrlSchema,
                                        object: nil,
                                        userInfo: info)
        NotificationCenter.default.post(notification)

        return true
    }
}

@available(iOS 13.0, *)
enum Scenes: String {
    case fullApp
    case messageView
    case composer

    var delegateClass: AnyClass {
        switch self {
        case .fullApp:  return WindowSceneDelegate.self
        default:        fatalError("not implemented yet")
        }
    }
}
