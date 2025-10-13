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

private struct UIKitLifecycle {
    let onDidAppear: () -> Void
}

extension View {
    public func onDidAppear(onDidAppearBlock: @escaping () -> Void) -> some View {
        modifier(
            ObservingModifier(
                lifecycle: .init(
                    onDidAppear: onDidAppearBlock
                )
            )
        )
    }
}

private struct ObservingModifier: ViewModifier {
    let lifecycle: UIKitLifecycle

    func body(content: Content) -> some View {
        content
            .background(ObservingView(lifecycle: lifecycle))
    }
}

private struct ObservingView: UIViewControllerRepresentable {
    let lifecycle: UIKitLifecycle

    func makeUIViewController(context: Context) -> ObservingViewController {
        .init(lifecycle: lifecycle)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

private final class ObservingViewController: UIViewController {
    private let lifecycle: UIKitLifecycle

    init(lifecycle: UIKitLifecycle) {
        self.lifecycle = lifecycle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        lifecycle.onDidAppear()
    }
}
