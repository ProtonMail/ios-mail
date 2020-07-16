//
//  WindowSceneDelegate.swift
//  ProtonMail - Created on 23/07/2019.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
    

import Foundation

@available(iOS 13.0, *)
class WindowSceneDelegate: UIResponder, UIWindowSceneDelegate {
    lazy var coordinator: WindowsCoordinator = {
        if UIDevice.current.stateRestorationPolicy == .multiwindow {
            // each window scene has it's own windowCoordinator
            return WindowsCoordinator(services: sharedServices)
        } else {
            // windowCoordinator is shared across whole app
            return (UIApplication.shared.delegate as? AppDelegate)!.coordinator
        }
    }()
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard case let app = UIApplication.shared, let delegate = app.delegate as? AppDelegate else { return }
        _ = URLContexts.first { context in
            delegate.application(app, open: context.url)
        }
    }
    
    // in case of Handoff will be called AFTER scene(_:willConnectTo:options:)
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let data = userActivity.userInfo?["deeplink"] as? Data,
            let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data)
        {
            self.coordinator.followDeeplink(deeplink)
        }
    }
    
    // will be called by system if app is foreground, otherwise shortcut is passed via scene(_:willConnectTo:options:)
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        if let data = shortcutItem.userInfo?["deeplink"] as? Data,
            let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data)
        {
            self.coordinator.followDeeplink(deeplink)
        }
        completionHandler(true)
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        self.coordinator.scene = scene
        
        if let userInfo = connectionOptions.notificationResponse?.notification.request.content.userInfo {
            sharedServices.get(by: PushNotificationService.self)
                            .setNotificationOptions(userInfo, fetchCompletionHandler: { /* nothing */ })
        }
        
        if let shortcutItem = connectionOptions.shortcutItem,
            let scene = scene as? UIWindowScene
        {
            self.windowScene(scene, performActionFor: shortcutItem, completionHandler: { _ in })
            return
        } else if UIDevice.current.stateRestorationPolicy == .multiwindow,
            let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity
        {
            self.scene(scene, continue: userActivity)
            return
        } else if connectionOptions.handoffUserActivityType != nil {
            // coordinator will be started by windowScene(_:performActionFor:completionHandler:)
            return
        }
        
        self.coordinator.start()
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        // to prevent built-in restoration on iPhones, which is broken up to at least iOS 13.3 beta 2
        guard UIDevice.current.stateRestorationPolicy == .multiwindow else { return nil }
        return self.currentUserActivity(in: scene)
    }
    
    private func currentUserActivity(in scene: UIScene) -> NSUserActivity? {
        guard let deeplink = self.coordinator.currentDeepLink() ,
            let data = try? JSONEncoder().encode(deeplink) else
        {
            return scene.userActivity
        }
        
        let userActivity = NSUserActivity(activityType: "RestoreWindow")
        userActivity.userInfo?["deeplink"] = data
        
        return userActivity
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        self.coordinator.willEnterForeground()
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        self.coordinator.didEnterBackground()
        
        // app gone background if all of scenes are background
        if UIApplication.shared.applicationState == .background ||
            nil == UIApplication.shared.openSessions.compactMap({ $0.scene }).first(where: { $0.activationState != .background })
        {
            UIApplication.shared.delegate?.applicationDidEnterBackground?(UIApplication.shared)
        }
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
