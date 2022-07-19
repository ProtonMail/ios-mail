// Copyright (c) 2022 Proton AG
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

class CustomViewPrintRenderer: UIPrintPageRenderer {
    private(set) var view: UIView
    private(set) var contentSize: CGSize
    private var image: UIImage?

    func updateImage(in rect: CGRect) {
        self.contentSize = rect.size

        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            self.image = nil
            return
        }
        self.view.layer.render(in: context)
        self.image = UIGraphicsGetImageFromCurrentImageContext()
    }

    init(_ view: UIView) {
        self.view = view
        self.contentSize = view.bounds.size
    }

    override func drawHeaderForPage(at pageIndex: Int, in headerRect: CGRect) {
        super.drawHeaderForPage(at: pageIndex, in: headerRect)
        guard pageIndex == 0 else { return }
        if UIGraphicsGetCurrentContext() != nil {
            self.image?.draw(in: headerRect)
        }
    }
}
