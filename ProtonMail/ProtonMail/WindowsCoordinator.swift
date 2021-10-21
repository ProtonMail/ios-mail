//
//  WindowsCoordinator.swift
//  ProtonMail - Created on 12/11/2018.
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
import ProtonCore_Keymaker
import ProtonCore_Networking

// this view controller is placed into AppWindow only until it is correctly loaded from storyboard or correctly restored with use of MainKey
fileprivate class PlaceholderVC: UIViewController {
    var color: UIColor = .blue
    
    convenience init(color: UIColor) {
        self.init()
        self.color = color
    }
    
    override func loadView() {
        view = UINib(nibName: "LaunchScreen", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        #if DEBUG
        self.view.backgroundColor = color
        #else
        Snapshot().show(at: self.view)
        #endif
    }
}

class WindowsCoordinator: CoordinatorNew {
    private lazy var snapshot = Snapshot()
    
    private var deeplink: DeepLink?

    private var appWindow: UIWindow! = UIWindow(root: PlaceholderVC(color: .red), scene: nil) {
        didSet {
            guard appWindow == nil else { return }
            if let oldAppWindow = oldValue {
                oldAppWindow.rootViewController?.dismiss(animated: false)
            }
        }
    }

    private var lockWindow: UIWindow?
    
    private var services: ServiceFactory
    
    var currentWindow: UIWindow? {
        didSet {
            self.currentWindow?.makeKeyAndVisible()
        }
    }

    private var arePrimaryUserSettingsFetched = false
    
    enum Destination {
        enum SignInDestination: String { case form, mailboxPassword }
        case lockWindow, appWindow, signInWindow(SignInDestination)
    }
    
    internal var scene: AnyObject? {
        didSet {
            // UIWindowScene class is available on iOS 13 and newer, older platforms should not use this property
            if #available(iOS 13.0, *) {
                assert(scene is UIWindowScene, "Scene should be of type UIWindowScene")
            } else {
                assert(false, "Scenes are unavailable on iOS 12 and older")
            }
        }
    }
    
    init(services: ServiceFactory) {
        defer {
            NotificationCenter.default.addObserver(self, selector: #selector(lock), name: Keymaker.Const.requestMainKey, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(unlock), name: .didUnlock, object: nil)
            NotificationCenter.default.addObserver(forName: .didRevoke, object: nil, queue: .main) { [weak self] (noti) in
                if let uid = noti.userInfo?["uid"] as? String {
                    self?.didReceiveTokenRevoke(uid: uid)
                }
            }

            NotificationCenter.default.addObserver(forName: .fetchPrimaryUserSettings, object: nil, queue: .main) { [weak self] _ in
                if self?.arePrimaryUserSettingsFetched == false {
                    self?.arePrimaryUserSettingsFetched = true
                    self?.restoreAppStates()
                }
            }

            NotificationCenter.default.addObserver(forName: .switchView, object: nil, queue: .main) { notification in
                // trigger the menu to follow the deeplink or show inbox
                self.handleSwitchViewDeepLinkIfNeeded((notification.object as? DeepLink))
            }
            
            if #available(iOS 13.0, *) {
                // this is done by UISceneDelegate
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                                       name: UIApplication.willEnterForegroundNotification,
                                                       object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                                       name: UIApplication.didEnterBackgroundNotification,
                                                       object: nil)
            }
        }
        self.services = services
    }
    
    /// restore some cache after login/authorized
    func loginmigrate() {
        //let cacheService : AppCacheService = serviceHolder.get()
        //cacheService.restoreCacheAfterAuthorized()
    }
    
    func start() {
        let placeholder = UIWindow(root: PlaceholderVC(color: .white), scene: self.scene)
        self.currentWindow = placeholder
        
        //some cache may need user to unlock first. so this need to move to after windows showup
        let usersManager : UsersManager = self.services.get()
        usersManager.launchCleanUpIfNeeded()
//        usersManager.tryRestore()
        
        //we should not trigger the touch id here. because it also doing in the sign vc. so when need lock. we just go to lock screen first
        // clean this up later.

        let unlockManager: UnlockManager = self.services.get()
        let flow = unlockManager.getUnlockFlow()
        if flow == .requireTouchID || flow == .requirePin {
            self.lock()
        } else {
            DispatchQueue.main.async {
                // initiate unlock process which will send .didUnlock or .requestMainKey eventually
                unlockManager.initiateUnlock(flow: flow,
                                             requestPin: self.lock,
                                             requestMailboxPassword: self.lock)
            }
        }
    }
    
    @objc func willEnterForeground() {
        self.snapshot.remove()
    }
    
    @objc func didEnterBackground() {
        if let vc = self.currentWindow?.topmostViewController(),
           !(vc is ComposeContainerViewController) {
            vc.view.endEditing(true)
        }
        if let window = self.currentWindow {
            self.snapshot.show(at: window)
        }
    }
    
    @objc func lock() {
        guard sharedServices.get(by: UsersManager.self).hasUsers() else {
            keymaker.wipeMainKey()
            self.go(dest: .signInWindow(.form))
            return
        }
        self.go(dest: .lockWindow)
    }
    
    @objc func unlock() {
        self.lockWindow = nil
        let usersManager : UsersManager = self.services.get()
        
        guard usersManager.hasUsers() else {
            self.go(dest: .signInWindow(.form))
            return
        }
        if usersManager.count <= 0 {
            _ = usersManager.clean()
            self.go(dest: .signInWindow(.form))
        } else {
            self.go(dest: .appWindow)
        }
    }
    
    @objc func didReceiveTokenRevoke(uid: String) {
        let usersManager: UsersManager = services.get()
        let queueManager: QueueManager = services.get()
        
        if let user = usersManager.getUser(bySessionID: uid) {
            let shouldShowBadTokenAlert = usersManager.count == 1

            queueManager.unregisterHandler(user.mainQueueHandler)
            usersManager.logout(user: user, shouldShowAccountSwitchAlert: true).done { [weak self] (_) in
                guard let self = self else { return }
                
                guard let appWindow = self.appWindow else {return}
                
                if usersManager.hasUsers() {
                    appWindow.enumerateViewControllerHierarchy { controller, stop in
                        if let menu = controller as? MenuViewController {
                            //Work Around: trigger viewDidLoad of menu view controller
                            _ = menu.view
                            menu.navigateTo(label: MenuLabel(location: .inbox))
                        }
                    }
                }
            }.done { (_) in
                if shouldShowBadTokenAlert {
                    NSError.alertBadToken()
                }
            }.cauterize()
        }
    }
    
    func go(dest: Destination) {
        DispatchQueue.main.async { // cuz
            switch dest {
            case .signInWindow(let signInDestination):
                // just restart coordinator in case it's already displayed with right configuration
                if let signInVC = self.currentWindow?.rootViewController as? SignInCoordinator.VC,
                   signInVC.coordinator.startingPoint == signInDestination {
                    signInVC.coordinator.start()
                    return
                }
                self.lockWindow = nil
                self.appWindow = nil
                let signInEnvironment = SignInCoordinatorEnvironment.live(
                    services: sharedServices, forceUpgradeDelegate: ForceUpgradeManager.shared.forceUpgradeHelper
                )
                let coordinator: SignInCoordinator = .loginFlowForFirstAccount(
                    startingPoint: signInDestination, environment: signInEnvironment
                ) { [weak self] flowResult in
                    switch flowResult {
                    case .succeeded:
                        self?.go(dest: .appWindow)
                        delay(1) {
                            // Waiting for init of Menu coordinate to receive the notification
                            NotificationCenter.default.post(name: .switchView, object: nil)
                        }
                    case .userWantsToGoToTroubleshooting:
                        let troubleshootingVC = UIStoryboard.Storyboard.alert.storyboard.make(NetworkTroubleShootViewController.self)
                        troubleshootingVC.onDismiss = { [weak self] in
                            // restart the process after user returns from troubleshooting
                            self?.go(dest: .signInWindow(signInDestination))
                        }
                        let navigationVC = UINavigationController(rootViewController: troubleshootingVC)
                        navigationVC.modalPresentationStyle = .fullScreen
                        self?.currentWindow?.rootViewController?.present(navigationVC, animated: true, completion: nil)
                    case .alreadyLoggedIn, .loggedInFreeAccountsLimitReached, .errored:
                        // not sure what else I can do here instead of restarting the process
                        self?.go(dest: .signInWindow(.form))
                    case .dismissed:
                        assertionFailure("this should never happen as the loginFlowForFirstAccount is not dismissable")
                        self?.go(dest: .signInWindow(.form))
                    }
                }
                let newWindow = UIWindow(root: coordinator.actualViewController, scene: self.scene)
                self.navigate(from: self.currentWindow, to: newWindow, animated: false) {
                    coordinator.start()
                }

            case .lockWindow:
                guard self.lockWindow == nil else {
                    guard let lockVC = self.currentWindow?.rootViewController as? LockCoordinator.VC,
                          lockVC.coordinator.startedOrSheduledForAStart == false
                    else {
                        self.lockWindow = nil
                        return
                    }
                    lockVC.coordinator.start()
                    return
                }

                let coordinator = LockCoordinator(services: sharedServices) { [weak self] flowResult in
                    switch flowResult {
                    case .mailbox: self?.go(dest: .appWindow)
                    case .mailboxPassword: self?.go(dest: .signInWindow(.mailboxPassword))
                    case .signIn: self?.go(dest: .signInWindow(.form))
                    }
                }
                let lock = UIWindow(root: coordinator.actualViewController, scene: self.scene)
                self.lockWindow = lock
                coordinator.startedOrSheduledForAStart = true
                self.navigate(from: self.currentWindow, to: lock, animated: false) { [weak coordinator] in
                    if UIApplication.shared.applicationState != .background {
                        coordinator?.start()
                    } else {
                        coordinator?.startedOrSheduledForAStart = false
                    }
                }

            case .appWindow:
                self.lockWindow = nil
                if self.appWindow == nil || self.appWindow.rootViewController is PlaceholderVC {
                    self.appWindow = UIWindow(storyboard: .inbox, scene: self.scene)
                }
                if #available(iOS 13.0, *), self.appWindow.windowScene == nil {
                    self.appWindow.windowScene = self.scene as? UIWindowScene
                }
                if self.navigate(from: self.currentWindow, to: self.appWindow, animated: true), let deeplink = self.deeplink {
                    self.handleDeepLinkIfNeeded(deeplink)
                }
            }
        }
    }

    private func restoreAppStates() {
        guard appWindow != nil else { return }
        self.appWindow.enumerateViewControllerHierarchy { controller, stop in
            if let menu = controller as? MenuViewController {
                menu.coordinator.handleSwitchView(deepLink: self.deeplink)
                stop = true
            }
        }
    }
    
    @discardableResult func navigate(from source: UIWindow?, to destination: UIWindow, animated: Bool, completion: (() -> Void)? = nil) -> Bool {
        guard source != destination, source?.rootViewController?.restorationIdentifier != destination.rootViewController?.restorationIdentifier else {
            return false
        }
        
        let effectView = UIVisualEffectView(frame: UIScreen.main.bounds)
        source?.addSubview(effectView)
        destination.alpha = 0.0
        
        UIView.animate(withDuration: animated ? 0.5 : 0.0, animations: {
            effectView.effect = UIBlurEffect(style: .dark)
            destination.alpha = 1.0
        }, completion: { _ in
            let _ = source
            let _ = destination
            effectView.removeFromSuperview()
            
            // notify source's views they are disappearing
            source?.topmostViewController()?.viewWillDisappear(false)

            // notify destination views they are about to show up
            if let topDestination = destination.topmostViewController(), topDestination.isViewLoaded {
                topDestination.viewWillAppear(false)
                topDestination.viewDidAppear(false)
            }
            completion?()
        })
        self.currentWindow = destination
        return true
    }
    
    // Preserving and Restoring State
    
    func currentDeepLink() -> DeepLink? {
        let deeplink = DeepLink("Root")
        self.appWindow?.enumerateViewControllerHierarchy { controller, _ in
            guard let deeplinkable = controller as? Deeplinkable else { return }
            
            deeplink.append(deeplinkable.deeplinkNode)
            
            // this will let us restore correct user starting from MenuViewModel and transfer it down the hierarchy later
            // mostly relevant in multiuser environment when two or more windows with defferent users in each one
            if let menu = controller as? MenuViewController,
               let user = menu.viewModel.currentUser {
                let userNode = DeepLink.Node(name: MenuCoordinator.Setup.switchUser.rawValue, value: user.auth.sessionID)
                deeplink.append(userNode)
            }
        }
        guard let _ = deeplink.popFirst, let _ = deeplink.head else {
            return nil
        }
        return deeplink
    }
    
    internal func saveForRestoration(_ coder: NSCoder) {
        switch UIDevice.current.stateRestorationPolicy {
        case .deeplink:
            if let deeplink = self.currentDeepLink(),
                let data = try? JSONEncoder().encode(deeplink)
            {
                coder.encode(data, forKey: "deeplink")
            }
            
        case .multiwindow:
            assert(false, "Multiwindow environment should not use NSCoder-based restoration")
        }
    }
    
    internal func restoreState(_ coder: NSCoder) {
        switch UIDevice.current.stateRestorationPolicy {
        case .deeplink:
            if let data = coder.decodeObject(forKey: "deeplink") as? Data,
                let deeplink = try? JSONDecoder().decode(DeepLink.self, from: data)
            {
                self.followDeeplink(deeplink)
            }
            
        case .multiwindow:
            assert(false, "Multiwindow environment should not use NSCoder-based restoration")
        }
    }
    
    internal func followDeeplink(_ deeplink: DeepLink) {
        self.deeplink = deeplink
        _ = deeplink.popFirst
        self.start()
    }
    
    func followDeepDeeplinkIfNeeded(_ deeplink: DeepLink) {
        self.deeplink = deeplink
        _ = deeplink.popFirst

        if arePrimaryUserSettingsFetched {
            start()
        }
    }

    private func handleDeepLinkIfNeeded(_ deeplink: DeepLink) {
        guard arePrimaryUserSettingsFetched else { return }
        self.appWindow.enumerateViewControllerHierarchy { controller, stop in
            if let menu = controller as? MenuViewController,
                let coordinator = menu.coordinator {
                coordinator.follow(deeplink)
                stop = true
            }
        }
    }

    private func handleSwitchViewDeepLinkIfNeeded(_ deepLink: DeepLink?) {
        self.deeplink = deepLink
        guard arePrimaryUserSettingsFetched && appWindow != nil else {
            return
        }
        self.appWindow.enumerateViewControllerHierarchy { controller, stop in
            if let menu = controller as? MenuViewController,
                let coordinator = menu.coordinator {
                coordinator.handleSwitchView(deepLink: deepLink)
                stop = true
            }
        }
    }
}
