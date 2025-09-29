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

import Combine
import InboxCore
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

final class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {

    typealias TransitionAnimation =
        @MainActor (
            _ view: UIView,
            _ duration: TimeInterval,
            _ options: UIView.AnimationOptions,
            _ animations: (() -> Void)?,
            _ completion: ((Bool) -> Void)?
        ) -> Void

    weak var windowScene: UIWindowScene?
    var overlayWindow: UIWindow?
    var appProtectionWindow: UIWindow?
    var appProtectionCancellable: AnyCancellable?
    var appProtectionStore = AppProtectionStore(mailSession: { AppContext.shared.mailSession })
    var mailSessionFactory: () -> MailSession = { AppContext.shared.mailSession }
    var transitionAnimation: TransitionAnimation = UIView.transition

    var checkAutoLockSetting: (_ completion: @MainActor @escaping @Sendable (Bool) -> Void) -> Void = { completion in
        Task {
            do {
                let value = try await AppContext.shared.mailSession.shouldAutoLock().get()
                await completion(value)
            } catch {
                AppLogger.log(error: error, category: .appSettings)
                await completion(false)
            }
        }
    }

    var toastStateStore: ToastStateStore? {
        didSet {
            if let toastStateStore {
                setupOverlayWindow(with: toastStateStore)
            }
        }
    }

    private var appProtection: AppProtection = .none {
        didSet {
            handleLockScreenVisibility(type: appProtection.lockScreenType)
        }
    }

    private let windowColorSchemeUpdater = WindowColorSchemeUpdater()

    // MARK: - UISceneDelegate

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let scene = scene as? UIWindowScene {
            windowScene = scene
            appProtectionWindow = appProtectionWindow(windowScene: scene)
        }

        if let shortcutItem = connectionOptions.shortcutItem {
            Task {
                _ = await AppLifeCycle.shared.scene(scene, performActionFor: shortcutItem)
            }
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        AppLifeCycle.shared.sceneWillEnterForeground()
        appProtectionStore.checkProtection()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        AppLifeCycle.shared.sceneWillResignActive()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        AppLifeCycle.shared.sceneDidEnterBackground()
        coverAppContent()
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem) async -> Bool {
        await AppLifeCycle.shared.scene(windowScene, performActionFor: shortcutItem)
    }

    // MARK: - Private

    private func setupOverlayWindow(with toastStateStore: ToastStateStore) {
        if let windowScene {
            overlayWindow = window(windowScene: windowScene, with: toastStateStore)
        }
    }

    private func window(windowScene: UIWindowScene, with toastStateStore: ToastStateStore) -> UIWindow {
        let window = PassThroughWindow(windowScene: windowScene)
        window.rootViewController = overlayRootController(with: toastStateStore)
        window.isHidden = false

        windowColorSchemeUpdater.subscribeToColorSchemeChanges(window: window)

        return window
    }

    private func appProtectionWindow(windowScene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: windowScene)
        window.isHidden = true

        windowColorSchemeUpdater.subscribeToColorSchemeChanges(window: window)

        appProtectionCancellable = appProtectionStore
            .protection
            .receive(on: Dispatcher.mainScheduler)
            .sink(receiveValue: { [weak self] appProtection in
                self?.appProtection = appProtection
            })

        return window
    }

    private func handleLockScreenVisibility(type: LockScreenState.LockScreenType?) {
        guard let type else {
            hideAppProtectionWindow()
            return
        }
        checkAutoLockSetting { [weak self] shouldShowLockScreen in
            if shouldShowLockScreen {
                self?.showLockScreen(lockScreenType: type)
            } else {
                self?.hideAppProtectionWindow()
            }
        }
    }

    @MainActor
    private func showLockScreen(lockScreenType: LockScreenState.LockScreenType) {
        appProtectionWindow?.isHidden = false
        appProtectionWindow?.makeKey()
        appProtectionWindow?.rootViewController = lockScreenController(for: lockScreenType)
        appProtectionWindow?.accessibilityViewIsModal = true
    }

    private func lockScreenController(for lockScreenType: LockScreenState.LockScreenType) -> UIViewController {
        let controller = UIHostingController(
            rootView:
                LockScreen(
                    state: .init(type: lockScreenType),
                    mailSession: mailSessionFactory(),
                    dismissLock: { [weak self] in
                        self?.appProtectionStore.dismissLock()
                    }
                )
        )
        controller.view.backgroundColor = .clear
        return controller
    }

    @MainActor
    private func hideAppProtectionWindow() {
        guard let appProtectionWindow, !appProtectionWindow.isHidden else { return }
        overlayWindow?.makeKey()
        transitionAnimation(
            appProtectionWindow, 0.2, .transitionCrossDissolve,
            {
                appProtectionWindow.rootViewController = nil
            },
            { _ in
                appProtectionWindow.isHidden = true
            })
    }

    @MainActor
    private func coverAppContent() {
        appProtectionWindow?.rootViewController = coverController
        appProtectionWindow?.isHidden = false
    }

    private func overlayRootController(with toastStateStore: ToastStateStore) -> UIViewController {
        let controller = UIHostingController(rootView: ToastSceneView().environmentObject(toastStateStore))
        controller.view.backgroundColor = .clear

        return controller
    }

    private var coverController: UIViewController {
        let controller = UIHostingController(rootView: BlurredCoverView(showLogo: true))
        controller.view.backgroundColor = .clear
        return controller
    }

}
