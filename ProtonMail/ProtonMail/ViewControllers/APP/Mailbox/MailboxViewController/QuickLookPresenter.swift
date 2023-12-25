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

final class QuickLookPresenter: NSObject {
    static func canPreviewItem(at url: URL) -> Bool {
        QuickViewViewController.canPreview(url as QLPreviewItem)
    }

    private let previewItemFile: SecureTemporaryFile
    let viewController = QuickViewViewController()

    init(file: SecureTemporaryFile) {
        self.previewItemFile = file
        super.init()
        viewController.dataSource = self
    }

    func present(from parent: UIViewController) {
        if let nav = parent as? UINavigationController {
            nav.pushViewController(viewController, animated: true)
        } else {
            parent.present(viewController, animated: true)
        }
    }
}

extension QuickLookPresenter: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        previewItemFile.url as QLPreviewItem
    }
}
