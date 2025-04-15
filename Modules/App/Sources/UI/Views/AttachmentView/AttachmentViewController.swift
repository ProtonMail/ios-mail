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

import QuickLook
import SwiftUI

struct AttachmentViewController: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode

    typealias UIViewControllerType = UINavigationController
    typealias Coordinator = AttachmentViewCoordinator

    /// property accessed from the `Coordinator`
    let url: URL

    @MainActor
    func makeUIViewController(context: Context) -> UIViewControllerType {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: context.coordinator,
            action: #selector(context.coordinator.dismiss)
        )

        let navigationController = UINavigationController(rootViewController: controller)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}
