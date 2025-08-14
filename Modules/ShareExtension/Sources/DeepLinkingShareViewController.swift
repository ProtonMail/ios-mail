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
import SwiftUI
import TestableShareExtension

final class DeepLinkingShareViewController: UINavigationController {
    private let draftStubWriter = DraftStubWriter()

    override func beginRequest(with context: NSExtensionContext) {
        super.beginRequest(with: context)

        Task {
            do {
                try await createDraftStub(basedOn: context)
                openMainApp(in: context)
            } catch {
                AppLogger.log(error: error, category: .shareExtension)

                let errorScreen = ErrorScreen(error: error) {
                    context.cancelRequest(withError: error)
                }

                showView(errorScreen)
            }
        }
    }

    private nonisolated func createDraftStub(basedOn context: NSExtensionContext) async throws -> Void {
        let extensionItems = context.inputItems.map { $0 as! NSExtensionItem }
        let sharedContent = try await SharedItemsParser.parse(extensionItems: extensionItems)
        try await draftStubWriter.createDraftStub(basedOn: sharedContent)
    }

    private func openMainApp(in context: NSExtensionContext) {
        let mainAppOpener = MainAppOpener {
            context.completeRequest(returningItems: nil)
        }

        showView(mainAppOpener)
    }

    private func showView<Content: View>(_ view: Content) {
        let hosting = UIHostingController(rootView: view)
        setViewControllers([hosting], animated: false)
    }
}

/// The purpose of this struct is to access openURL, which is available much earlier than UIApplication
private struct MainAppOpener: View {
    @Environment(\.openURL) private var openURL
    private let dismissShareExtension: () -> Void

    init(dismissShareExtension: @escaping () -> Void) {
        self.dismissShareExtension = dismissShareExtension
    }

    var body: some View {
        ProgressView()
            .task {
                openURL(URL(string: "\(Bundle.URLScheme.protonmail)://composer")!)
                dismissShareExtension()
            }
    }
}
