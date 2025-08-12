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

import InboxCore
import SwiftUI

struct ComposerControllerRepresentable: UIViewControllerRepresentable {
    let state: ComposerState
    @Binding var bodyAction: ComposerBodyAction?
    let imageProxy: ImageProxy
    let invalidAddressAlertStore: InvalidAddressAlertStateStore
    let onEvent: (ComposerController.Event) -> Void

    func makeUIViewController(context: Context) -> ComposerController {
        let controller = ComposerController(
            state: state,
            imageProxy: imageProxy,
            invalidAddressAlertStore: invalidAddressAlertStore,
            onEvent: onEvent
        )
        context.coordinator.controller = controller
        return controller
    }

    func updateUIViewController(_ controller: ComposerController, context: Context) {
        context.coordinator.updateState(state)
        // DispatchQueue.main required to avoid publishing changes (bodyAction) during view updates
        DispatchQueue.main.async {
            if let action = bodyAction {
                bodyAction = nil
                context.coordinator.handleBodyAction(action: action)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var controller: ComposerController!

        func updateState(_ state: ComposerState) {
            controller.state = state
        }

        func handleBodyAction(action: ComposerBodyAction) {
            controller.handleBodyAction(action: action)
        }
    }
}
