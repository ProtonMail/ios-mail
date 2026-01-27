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

import SwiftUI

struct PanGestureRecognizer: UIGestureRecognizerRepresentable {
    let onChanged: (CGPoint) -> Void
    let onEnded: () -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gestureRecognizer = UIPanGestureRecognizer()
        gestureRecognizer.delegate = context.coordinator
        return gestureRecognizer
    }

    func handleUIGestureRecognizerAction(_ gestureRecognizer: UIPanGestureRecognizer, context: Context) {
        guard let view = gestureRecognizer.view else {
            // Still handle cleanup even if view is nil to avoid UI side effects
            if gestureRecognizer.state == .ended || gestureRecognizer.state == .cancelled {
                onEnded()
            }
            return
        }

        let translation = gestureRecognizer.translation(in: view)

        switch gestureRecognizer.state {
        case .began, .changed:
            onChanged(translation)
        case .ended, .cancelled:
            onEnded()
        default:
            break
        }
    }

    func updateUIGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer, context: Context) {
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
