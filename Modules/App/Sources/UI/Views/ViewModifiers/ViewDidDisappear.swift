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

struct UIKitLifecycle {
    //    let onWillAppear: () -> Void
    let onDidAppear: () -> Void
    //    let onWillDisappear: () -> Void
    //    let onDidDisappear: () -> Void
}

extension View {
    public func onWillAppear(
        perform onWillAppearBlock: @escaping () -> Void,
        didAppear onDidAppearBlock: @escaping () -> Void,
        willDisappear onWillDisappearBlock: @escaping () -> Void,
        didDisappear onDidDisappearBlock: @escaping () -> Void
    ) -> some View {
        modifier(
            ObservingModifier(
                lifecycle: .init(
                    //                    onWillAppear: onWillAppearBlock,
                    onDidAppear: onDidAppearBlock,
                    //                    onWillDisappear: onWillDisappearBlock,
                    //                    onDidDisappear: onDidDisappearBlock,
                )
            )
        )
    }

    func onDidAppear(perform block: @escaping () -> Void) -> some View {
        modifier(
            ObservingModifier(
                lifecycle: .init(
                    //                    onWillAppear: onWillAppearBlock,
                    onDidAppear: block,
                    //                    onWillDisappear: onWillDisappearBlock,
                    //                    onDidDisappear: onDidDisappearBlock,
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

    //    override func viewWillAppear(_ animated: Bool) {
    //        super.viewWillDisappear(animated)
    //
    //        lifecycle.onWillAppear()
    //    }
    //
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        lifecycle.onDidAppear()
    }
    //
    //    override func viewWillDisappear(_ animated: Bool) {
    //        super.viewWillDisappear(animated)
    //
    //        lifecycle.onWillDisappear()
    //    }

    //    override func viewDidDisappear(_ animated: Bool) {
    //        super.viewDidDisappear(animated)
    //
    //        lifecycle.onDidDisappear()
    //    }
}
