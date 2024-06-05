// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreUIFoundations
import UIKit

class AttachmentPreviewViewController: ProtonMailViewController {
    private var attachmentPreviewWasCancelled = false
    private var attachmentPreviewPresenter: QuickLookPresenter?
    private let viewModel: AttachmentPreviewViewModelProtocol

    init(viewModel: some AttachmentPreviewViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showAttachmentPreviewBanner(at indexPath: IndexPath, index: Int) {
        let downloadBanner = PMBanner(
            message: L10n.AttachmentPreview.downloadingAttachment,
            style: PMBannerNewStyle.info
        )
        downloadBanner.addButton(text: LocalString._general_cancel_button) { [weak self, weak downloadBanner] _ in
            self?.attachmentPreviewWasCancelled = true
            downloadBanner?.dismiss()
        }
        downloadBanner.show(at: .bottom, on: self)
        Task {
            do {
                let file = try await self.viewModel.requestPreviewOfAttachment(at: indexPath, index: index)
                await MainActor.run { [weak self] in
                    guard self?.attachmentPreviewWasCancelled == false else {
                        self?.attachmentPreviewWasCancelled = false
                        return
                    }
                    self?.showAttachment(from: file)
                }
            } catch {
                await MainActor.run {
                    let banner = PMBanner(
                        message: error.localizedDescription,
                        style: PMBannerNewStyle.error
                    )
                    banner.show(at: .bottom, on: self)
                }
            }
        }
    }

    func showAttachment(from file: SecureTemporaryFile) {
        guard QuickLookPresenter.canPreviewItem(at: file.url), let navigationController else {
            let banner = PMBanner(message: L10n.AttachmentPreview.cannotPreviewMessage,
                                  style: PMBannerNewStyle.info)
            banner.show(at: .bottom, on: self)
            return
        }

        attachmentPreviewPresenter = QuickLookPresenter(file: file)
        attachmentPreviewPresenter?.present(from: navigationController)
    }
}
