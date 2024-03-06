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

import Foundation
import ProtonCoreUIFoundations
import SwiftUI

public final class ComponentViewController<Content>: UIHostingController<Content> where Content: View {

    public override init(rootView: Content) {
        super.init(rootView: rootView)
        view.backgroundColor = .clear
        view.isOpaque = false
        modalPresentationStyle = .overCurrentContext
    }

    @MainActor
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Fix the UI issue after rotation when using overCurrentContext
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            let newFrame = self.presentingViewController?.view.bounds ?? .zero
            self.view.frame = newFrame
        }
    }
}
