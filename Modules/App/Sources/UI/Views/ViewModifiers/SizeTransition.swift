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

extension View {
    public func sizeTransition(inProgress: Binding<Bool>) -> some View {
        modifier(SizeTransitionObservingModifier(sizeTransitionInProgress: inProgress))
    }
}

private struct SizeTransitionObservingModifier: ViewModifier {
    let sizeTransitionInProgress: Binding<Bool>

    func body(content: Content) -> some View {
        content
            .background(SizeTransitionObservingView(sizeTransitionInProgress: sizeTransitionInProgress))
    }
}

private struct SizeTransitionObservingView: UIViewControllerRepresentable {
    let sizeTransitionInProgress: Binding<Bool>

    func makeUIViewController(context: Context) -> SizeTransitionObservingViewController {
        .init(sizeTransitionInProgress: sizeTransitionInProgress)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

private final class SizeTransitionObservingViewController: UIViewController {
    private let sizeTransitionInProgress: Binding<Bool>

    init(sizeTransitionInProgress: Binding<Bool>) {
        self.sizeTransitionInProgress = sizeTransitionInProgress
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        sizeTransitionInProgress.wrappedValue = true

        coordinator.animate(alongsideTransition: nil) { [sizeTransitionInProgress] _ in
            sizeTransitionInProgress.wrappedValue = false
        }
    }
}
