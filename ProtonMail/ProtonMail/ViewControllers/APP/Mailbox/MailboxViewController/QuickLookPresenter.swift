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

import Foundation
import QuickLook

protocol QuickLookPresenterDelegate: AnyObject {
    func previewControllerDidDismiss(_ presenter: QuickLookPresenter, itemURL: URL)
}

final class QuickLookPresenter: NSObject {
    static func canPreviewItem(at url: URL) -> Bool {
        QuickViewViewController.canPreview(url as QLPreviewItem)
    }

    private let previewItem: URL
    let viewController = QuickViewViewController()
    weak var delegate: QuickLookPresenterDelegate?

    init(url: URL, delegate: QuickLookPresenterDelegate) {
        self.previewItem = url
        self.delegate = delegate
        super.init()
        viewController.delegate = self
        viewController.dataSource = self
    }

    func present(from parent: UIViewController) {
        parent.present(viewController, animated: true)
    }
}

extension QuickLookPresenter: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewItem as QLPreviewItem
    }
}

extension QuickLookPresenter: QLPreviewControllerDelegate {
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        delegate?.previewControllerDidDismiss(self, itemURL: previewItem)
    }
}
