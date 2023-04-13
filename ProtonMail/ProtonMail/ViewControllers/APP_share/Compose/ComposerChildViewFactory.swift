// Copyright (c) 2022 Proton Technologies AG
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

struct ComposerChildViewFactory {
    static func makeHeaderView() -> ComposeHeaderViewController {
        let header = ComposeHeaderViewController(
            nibName: String(describing: ComposeHeaderViewController.self),
            bundle: nil
        )
        return header
    }

    static func makeAttachmentView(
        viewModel: ComposeViewModel,
        contextProvider: CoreDataContextProviderProtocol,
        delegate: ComposerAttachmentVCDelegate,
        isUploading: @escaping (Bool) -> Void
    ) -> ComposerAttachmentVC {
        let attachments = viewModel.getAttachments() ?? []
        let attachmentView = ComposerAttachmentVC(
            attachments: attachments,
            contextProvider: contextProvider,
            delegate: delegate)
        attachmentView.addNotificationObserver()
        attachmentView.isUploading = isUploading
        return attachmentView
    }

    static func createEditor(
        parentView: ComposeContainerViewController,
        headerView: ComposeHeaderViewController,
        viewModel: ComposeViewModel,
        openScheduleSendActionSheet: @escaping () -> Void,
        delegate: ComposeContentViewControllerDelegate
    ) -> ContainableComposeViewController {
        let editor = ContainableComposeViewController(viewModel: viewModel)
        editor.openScheduleSendActionSheet = openScheduleSendActionSheet
        editor.injectHeader(headerView)
        editor.enclosingScroller = parentView
        editor.delegate = delegate
        return editor
    }
}
