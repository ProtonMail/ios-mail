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

import UIKit

protocol ContentPrintable: UIViewController {
    func exportPDF(renderer: UIPrintPageRenderer, fileName: String, sourceView: UIView)
    func presentPrintController(renderer: UIPrintPageRenderer, jobName: String)
}

extension ContentPrintable {
    func exportPDF(renderer: UIPrintPageRenderer, fileName: String, sourceView: UIView) {
        /*
         `paperRect` and `printableRect` must be set via KVO, because there is no official API for it.
         They could be overridden in `MessagePrintRenderer`, but it would interfere with printing.
         `UIPrintInteractionController` adjusts these properties depending on the paper size requested by the user.
         */
        let a4Size = CGSize(width: 595, height: 842)
        let paperRect = CGRect(origin: .zero, size: a4Size)
        let printableRect = paperRect.insetBy(dx: 18, dy: 40)
        renderer.setValue(paperRect, forKey: "paperRect")
        renderer.setValue(printableRect, forKey: "printableRect")

        let pdfData = renderer.createPDF()
        let tempFile = SecureTemporaryFile(data: pdfData, name: fileName)

        let activity = UIActivityViewController(activityItems: [tempFile.url], applicationActivities: nil)
        activity.completionWithItemsHandler = { _, _, _, _ in
            // hold onto the file until it is no longer necessary
            _ = tempFile
        }
        if let popOver = activity.popoverPresentationController {
            popOver.sourceView = sourceView
            popOver.sourceRect = sourceView.bounds
        }
        present(activity, animated: true)
    }

    func presentPrintController(renderer: UIPrintPageRenderer, jobName: String) {
        let printController = UIPrintInteractionController.shared
        printController.printPageRenderer = renderer

        let printInfo = UIPrintInfo.printInfo()
        printInfo.jobName = jobName
        printController.printInfo = printInfo

        printController.present(animated: true)
    }
}
