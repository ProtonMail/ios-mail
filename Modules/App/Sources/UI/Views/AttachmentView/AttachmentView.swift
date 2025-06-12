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
import SwiftUI
import proton_app_uniffi

struct AttachmentView: View {
    @StateObject private var loader: AttachmentViewLoader
    private let attachmentId: ID

    init(config: AttachmentViewConfig) {
        _loader = StateObject(wrappedValue: .init(mailbox: config.mailbox))
        self.attachmentId = config.id
    }

    var body: some View {
        ZStack {
            switch loader.state {
            case .loading:
                progressView
            case .attachmentReady(let url):
                AttachmentViewController(url: url)
            case .error(let error):
                errorView(error: error)
            }
        }
        .task {
            await loader.load(attachmentId: attachmentId)
        }
    }

    private var progressView: some View {
        NavigationView {
            ProgressView()
                .modifier(ShowDoneNavBarButton())
        }
    }

    private func errorView(error: Error) -> some View {
        NavigationView {
            ErrorView(error: error)
                .modifier(ShowDoneNavBarButton())
        }
    }
}

private struct ShowDoneNavBarButton: ViewModifier {
    @Environment(\.presentationMode) var presentationMode

    func body(content: Content) -> some View {
        content
            .navigationBarItems(
                leading:
                    Button(
                        action: {
                            presentationMode.wrappedValue.dismiss()
                        },
                        label: {
                            Text(CommonL10n.done)
                                .fontWeight(.semibold)
                        })
            )
    }
}

struct AttachmentViewConfig: Identifiable {
    let id: ID
    let mailbox: MailboxProtocol
}
