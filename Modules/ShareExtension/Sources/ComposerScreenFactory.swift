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

import Foundation
import InboxComposer
import InboxCore
import TestableShareExtension
import proton_app_uniffi

enum ComposerScreenFactory {
    @MainActor
    static func makeComposer(
        extensionContext: NSExtensionContext,
        userSession: MailUserSession,
        onDismiss: @escaping (ComposerDismissReason) -> Void
    ) async throws -> ComposerScreen {
        let inputItems = extensionContext.inputItems.map { $0 as! NSExtensionItem }
        let sharedContent = try await SharedItemsParser.parse(extensionItems: inputItems)
        let draft = try await newDraft(session: userSession, createMode: .empty).get()
        try await DraftPrecomposer.populate(draft: draft, with: sharedContent)

        let dependencies = ComposerScreen.Dependencies(
            contactProvider: .productionInstance(session: userSession),
            userSession: userSession
        )

        return ComposerScreen(draft: draft, draftOrigin: .new, dependencies: dependencies, onDismiss: onDismiss)
    }
}
