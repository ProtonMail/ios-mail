//
//  WindowSceneDelegate.swift
//  ProtonMail - Created on 23/07/2019.
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
    

import Foundation

@available(iOS 13.0, *)
class WindowSceneDelegate: UIResponder, UIWindowSceneDelegate {
    lazy var coordinator: WindowsCoordinator = {
        if UIDevice.current.stateRestorationPolicy == .coders {
            return (UIApplication.shared.delegate as? AppDelegate)!.coordinator
        } else {
            return WindowsCoordinator()
        }
    }()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        self.coordinator.scene = scene
        
        if UIDevice.current.stateRestorationPolicy == .deeplink,
            let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity,
            let data = userActivity.userInfo!["deeplink"] as? Data,
            let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data)
        {
            self.coordinator.followDeeplink(deeplink)
        } else {
            self.coordinator.start()
        }
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return self.currentUserActivity(in: scene)
    }
    
    private func currentUserActivity(in scene: UIScene) -> NSUserActivity? {
        let deeplink = DeepLink("Root")
        self.coordinator.currentWindow.enumerateViewControllerHierarchy { controller, _ in
            guard let deeplinkable = controller as? Deeplinkable else { return }
            deeplink.append(deeplinkable.deeplinkNode)
        }
        guard let _ = deeplink.popFirst, let _ = deeplink.head,
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
        if nil == UIApplication.shared.openSessions.first(where: { $0.scene?.activationState != .background }) {
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
