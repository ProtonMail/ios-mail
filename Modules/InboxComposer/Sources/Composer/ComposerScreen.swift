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
import InboxCoreUI
import InboxDesignSystem
import proton_app_uniffi
import SwiftUI

public struct ComposerScreen: View {
    @Environment(\.dismissTestable) var dismiss: Dismissable
    @EnvironmentObject var toastStateStore: ToastStateStore
    @StateObject private var model: ComposerScreenModel
    private let onSendingEvent: (SendEvent) -> Void
    private let dependencies: Dependencies

    public init(messageId: ID, dependencies: Dependencies, onSendingEvent: @escaping (SendEvent) -> Void) {
        self.dependencies = dependencies
        self.onSendingEvent = onSendingEvent
        self._model = StateObject(
            wrappedValue:
                ComposerScreenModel(
                    messageId: messageId,
                    userSession: dependencies.userSession
                )
        )
    }

    public init(
        draft: AppDraftProtocol,
        draftOrigin: DraftOrigin,
        dependencies: Dependencies,
        onSendingEvent: @escaping (SendEvent) -> Void
    ) {
        self.dependencies = dependencies
        self.onSendingEvent = onSendingEvent
        self._model = StateObject(
            wrappedValue: ComposerScreenModel(
                draft: draft,
                draftOrigin: draftOrigin
            )
        )
    }

    public var body: some View {
        switch model.state {
        case .loadingDraft:
            ComposerLoadingView(dismissAction: {
                model.cancel()
                dismiss()
            })
            .onChange(of: model.draftError) { _, newValue in
                guard let newValue else { return }
                toastStateStore.present(toast: .error(message: newValue.localizedDescription))
                dismiss()
            }
        case .draftLoaded(let draft, let draftOrigin):
            ComposerView(
                draft: draft,
                draftOrigin: draftOrigin,
                draftSavedToastCoordinator: .init(mailUSerSession: dependencies.userSession, toastStoreState: toastStateStore),
                contactProvider: dependencies.contactProvider,
                onSendingEvent: onSendingEvent
            )
            .interactiveDismissDisabled()
        }
    }
}

extension ComposerScreen {

    public struct Dependencies {
        let contactProvider: ComposerContactProvider
        let userSession: MailUserSession

        public init(contactProvider: ComposerContactProvider, userSession: MailUserSession) {
            self.contactProvider = contactProvider
            self.userSession = userSession
        }
    }
}

struct ComposerLoadingView: View {
    var dismissAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ComposerTopBar(isSendEnabled: false, dismissAction: dismissAction)
            Spacer()
            ProtonSpinner()
            Spacer()
        }
        .background(DS.Color.Background.norm)
    }
}

#Preview {
    let toastStateStore = ToastStateStore(initialState: .initial)

    ComposerScreen(
        draft: .emptyMock,
        draftOrigin: .new,
        dependencies: .init(contactProvider: .mockInstance, userSession: .init(noPointer: .init())),
        onSendingEvent: { _ in }
    )
    .environmentObject(toastStateStore)
}
