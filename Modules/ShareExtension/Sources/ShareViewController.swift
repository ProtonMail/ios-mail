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

import Combine
import InboxCore
import InboxCoreUI
import SwiftUI
import TestableShareExtension

final class ShareViewController: UINavigationController {
    private var cancellables = Set<AnyCancellable>()

    override func beginRequest(with context: NSExtensionContext) {
        super.beginRequest(with: context)

        let model = ShareScreenModel(apiEnvId: .current, extensionContext: context)
        showMainScreen(basedOn: model)
        setUpBindings(observing: model)
    }

    override func viewDidLoad() {
        DynamicFontSize.capSupportedSizeCategories()

        super.viewDidLoad()

        isNavigationBarHidden = true
    }

    private func showMainScreen(basedOn model: ShareScreenModel) {
        let screen = ShareScreen(model: model)
        let hostingController = UIHostingController(rootView: screen)
        setViewControllers([hostingController], animated: false)
    }

    private func setUpBindings(observing model: ShareScreenModel) {
        model.$alert.sink { [weak self] message in
            guard let self else { return }

            if presentedViewController != nil {
                dismiss(animated: true)
            }

            if let message {
                let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
                present(alert, animated: true)
            }
        }
        .store(in: &cancellables)
    }
}
