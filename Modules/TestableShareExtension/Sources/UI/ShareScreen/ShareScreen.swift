//
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

import InboxComposer
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

public struct ShareScreen: View {
    @ObservedObject private var model: ShareScreenModel
    @StateObject private var toastStateStore = ToastStateStore(initialState: .initial)

    public init(model: ShareScreenModel) {
        self.model = model
    }

    public var body: some View {
        switch model.state {
        case .preparing:
            Color.clear
                .task {
                    await model.prepare()
                }
        case .locked(let lockScreenType, let mailSession):
            LockScreen(
                state: .init(type: lockScreenType),
                mailSession: mailSession as! LockScreen.MailSessionType,
                dismissLock: {
                    Task {
                        await model.onAppUnlocked()
                    }
                }
            )
            .padding(.top)
        case .composing(let draft, let dependencies, let upsellCoordinator):
            ComposerScreen(
                draft: draft,
                draftOrigin: .new,
                dependencies: dependencies,
                isAddingAttachmentsEnabled: false,
                onDismiss: { reason in
                    model.onComposerDismissed(reason: reason)
                }
            )
            .overlay {
                ToastSceneView()
            }
            .environmentObject(toastStateStore)
            .environmentObject(upsellCoordinator)
        case .error(let error):
            ErrorScreen(
                error: error,
                dismissExtension: {
                    model.dismissShareExtension(error: error)
                },
            )
        }
    }
}
