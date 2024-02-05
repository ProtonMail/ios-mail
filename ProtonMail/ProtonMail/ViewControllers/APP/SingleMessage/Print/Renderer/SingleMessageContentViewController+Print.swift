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
import WebKit

extension SingleMessageContentViewController {
    func createPrintingSources() -> (webView: WKWebView, renderers: [CustomViewPrintRenderer])? {
        let headerController: CustomViewPrintable = self
        guard let webView = messageBodyViewController?.webView else {
            return nil
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
        return (webView, customViewRenderers)
    }
}

extension SingleMessageContentViewController: ContentPrintable {}

extension SingleMessageContentViewController: CustomViewPrintable {
    func printPageRenderer() -> CustomViewPrintRenderer {
        let style = overrideUserInterfaceStyle
        overrideUserInterfaceStyle = .light
        let headerView = PrintHeaderView(
            headerData: HeaderData(message: viewModel.message),
            recipientDelegate: self
        )
        overrideUserInterfaceStyle = style
        return CustomViewPrintRenderer(headerView)
    }

    func printingWillStart(renderer: CustomViewPrintRenderer) {
        guard let newHeader = renderer.view as? PrintHeaderView else { return }
        newHeader.frame = .init(x: 18, y: 40, width: 560, height: newHeader.frame.height)
        newHeader.layoutIfNeeded()

        renderer.updateImage(in: newHeader.frame)
    }
}

extension SingleMessageContentViewController: RecipientViewDelegate {
    func recipientViewNeedsLockCheck(completion: @escaping LockCheckComplete) {
        let status = viewModel.messageInfoProvider.checkedSenderContact?.encryptionIconStatus
        if let color = status?.iconColor.color {
            // To show correct icon in `print`
            // View is force to render as light mode under printing but iconWithColor follows device settings
            let trait = UITraitCollection(userInterfaceStyle: overrideUserInterfaceStyle)
            let resolvedColor = color.resolvedColor(with: trait)
            let icon = status?.icon.maskWithColor(color: resolvedColor)
            completion(icon, 0)
        } else {
            completion(status?.iconWithColor, 0)
        }
    }
}
