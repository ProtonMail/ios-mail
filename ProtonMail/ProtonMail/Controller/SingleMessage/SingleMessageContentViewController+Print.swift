//
//  SingleMessageViewController+Print.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

extension SingleMessageContentViewController {
    func presentPrintController() {
        let headerController: CustomViewPrintable = self

        guard let webView = messageBodyViewController?.webView else {
            return
        }

        let headerPrinter = headerController.printPageRenderer()

        var customViewRenderers: [CustomViewPrintRenderer] = [
            headerPrinter
        ]

        if let attachmentPrinter = attachmentViewController?.printPageRenderer() {
            customViewRenderers.append(attachmentPrinter)
            attachmentViewController?.printingWillStart(renderer: attachmentPrinter)
        }

        headerController.printingWillStart(renderer: headerPrinter)

        let messagePrintRenderer = MessagePrintRenderer(
            webView: webView,
            customViewRenderers: customViewRenderers
        )

        let printController = UIPrintInteractionController.shared
        printController.printPageRenderer = messagePrintRenderer
        printController.present(animated: true)
    }
}

extension SingleMessageContentViewController: CustomViewPrintable {
    func printPageRenderer() -> CustomViewPrintRenderer {
        let newHeader = EmailHeaderView(frame: .init(x: 0, y: 0, width: 300, height: 300))
        if #available(iOS 13, *) {
            newHeader.overrideUserInterfaceStyle = .light
        }
        newHeader.inject(recepientDelegate: self)
        newHeader.makeConstraints()
        newHeader.isShowingDetail = false
        newHeader.backgroundColor = .white
        newHeader.updateHeaderData(HeaderData(message: self.viewModel.message))
        newHeader.updateHeaderLayout()
        newHeader.updateShowImageConstraints()
        newHeader.updateSpamScoreConstraints()

        if self.viewModel.isExpanded {
            newHeader.detailsButtonTapped()
        }

        newHeader.layoutIfNeeded()

        return CustomViewPrintRenderer(newHeader)
    }

    func printingWillStart(renderer: CustomViewPrintRenderer) {
        guard let newHeader = renderer.view as? EmailHeaderView else { return }
        newHeader.prepareForPrinting(true)
        newHeader.frame = .init(x: 18, y: 40, width: 560, height: newHeader.getHeight())
        newHeader.layoutIfNeeded()

        renderer.updateImage(in: newHeader.frame)
    }
}

extension SingleMessageContentViewController: RecipientViewDelegate {
    func recipientViewNeedsLockCheck(completion: @escaping LockCheckComplete) {
        self.viewModel.nonExapndedHeaderViewModel?.lockIcon(completion: completion)
    }
}
