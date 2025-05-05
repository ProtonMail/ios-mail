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

    weak var windowScene: UIWindowScene?
    var overlayWindow: UIWindow?
    var appProtectionWindow: UIWindow?
    var appProtectionCancellable: AnyCancellable?
    var appProtectionStore = AppProtectionStore(mailSession: { AppContext.shared.mailSession })
    var pinVerifierFactory: () -> PINVerifier = { AppContext.shared.mailSession }

    var toastStateStore: ToastStateStore? {
        didSet {
            if let toastStateStore {
                setupOverlayWindow(with: toastStateStore)
            }
        }
    }

    private var appProtection: AppProtection = .none {
        didSet {
            appProtectionWindow?.rootViewController = lockScreenController(for: appProtection.lockScreenType)
            appProtectionWindow?.isHidden = appProtection.lockScreenType == nil
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
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        AppLifeCycle.shared.sceneWillEnterForeground()
        appProtectionStore.checkProtection()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        AppLifeCycle.shared.sceneDidEnterBackground()
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

    private func lockScreenController(for lockScreenType: LockScreenState.LockScreenType?) -> UIViewController? {
        guard let lockScreenType else {
            return nil
        }

        return UIHostingController(rootView:
            LockScreen(
                state: .init(type: lockScreenType),
                pinVerifier: pinVerifierFactory(),
                output: { [weak self] output in
                    switch output {
                    case .logOut:
                        break // FIXME: - To add later
                    case .authenticated:
                        self?.appProtectionStore.dismissLock()
                    }
                }
            )
        )
    }

    private func overlayRootController(with toastStateStore: ToastStateStore) -> UIViewController {
        let controller = UIHostingController(rootView: ToastSceneView().environmentObject(toastStateStore))
        controller.view.backgroundColor = .clear

        return controller
    }

}

private extension AppProtection {

    var lockScreenType: LockScreenState.LockScreenType? {
        switch self {
        case .none:
            return nil
        case .biometrics:
            return .biometric
        case .pin:
            return .pin
        }
    }

}
