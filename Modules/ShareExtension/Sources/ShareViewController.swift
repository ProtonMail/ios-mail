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
import InboxCoreUI
import SwiftUI
import TestableShareExtension
import UIKit

final class ShareViewController: UINavigationController {
    private let toastStateStore = ToastStateStore(initialState: .initial)

    override func viewDidLoad() {
        super.viewDidLoad()

        setNavigationBarHidden(true, animated: false)

        guard let extensionContext else {
            fatalError()
        }

        Task { @MainActor in
            do {
                let composerScreen = try await ComposerScreenFactory.makeComposer(extensionContext: extensionContext)
                    .environmentObject(toastStateStore)

                setRootView(composerScreen)
            } catch {
                AppLogger.log(error: error, category: .shareExtension)

                let errorView = ErrorView(
                    error: error,
                    dismissExtension: {
                        extensionContext.cancelRequest(withError: error)
                    },
                    launchMainApp: { [unowned self] in
                        await self.application()?.open(URL(string: "\(Bundle.URLScheme.protonmail):")!)
                    }
                )

                setRootView(errorView)
            }
        }
    }

    private func setRootView<Content: View>(_ rootView: Content) {
        let hostingController = UIHostingController(rootView: rootView)
        setViewControllers([hostingController], animated: false)
    }
}
