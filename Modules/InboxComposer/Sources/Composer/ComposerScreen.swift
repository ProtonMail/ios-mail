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
    private let contactProvider: ComposerContactProvider

    public init(messageId: Id, contactProvider: ComposerContactProvider, userSession: MailUserSession) {
        self.contactProvider = contactProvider
        self._model = StateObject(
            wrappedValue:
                ComposerScreenModel(
                    messageId: messageId,
                    contactProvider: contactProvider,
                    userSession: userSession
                )
        )
    }

    public init(draft: AppDraftProtocol, draftOrigin: DraftOrigin, contactProvider: ComposerContactProvider) {
        self.contactProvider = contactProvider
        self._model = StateObject(wrappedValue: ComposerScreenModel(draft: draft, draftOrigin: draftOrigin, contactProvider: contactProvider))
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
            ComposerView(draft: draft, draftOrigin: draftOrigin, contactProvider: contactProvider)
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
    }
}

#Preview {
    ComposerScreen(draft: .emptyMock, draftOrigin: .new, contactProvider: .mockInstance)
}
