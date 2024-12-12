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

import InboxCoreUI
import SwiftUI

final class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {

    weak var windowScene: UIWindowScene?
    var overlayWindow: UIWindow?

    var toastStateStore: ToastStateStore? {
        didSet {
            if let toastStateStore {
                setupOverlayWindow(with: toastStateStore)
            }
        }
    }

    // MARK: - UISceneDelegate

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        windowScene = scene as? UIWindowScene
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

        return window
    }

    private func overlayRootController(with toastStateStore: ToastStateStore) -> UIViewController {
        let controller = UIHostingController(rootView: ToastSceneView().environmentObject(toastStateStore))
        controller.view.backgroundColor = .clear

        return controller
    }

}
