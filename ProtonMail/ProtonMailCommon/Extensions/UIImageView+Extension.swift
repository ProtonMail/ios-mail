//
//  UIImageView+Extension.swift
//  ProtonMail - Created on 2018/10/2.
//
//
//  Copyright (c) 2019 Proton AG
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

extension UIImageView {
    func setupImage(contentMode: UIView.ContentMode = .center,
                    renderingMode: UIImage.RenderingMode = .alwaysTemplate,
                    scale: CGFloat = 0.5,
                    makeCircleBorder: Bool = true,
                    tintColor: UIColor? = nil,
                    backgroundColor: UIColor? = nil,
                    borderWidth: CGFloat = 0,
                    borderColor: CGColor? = nil) {
        self.contentMode = contentMode

        if let image = self.image {
            self.image = UIImage.resizeWithRespectTo(box: self.frame.size,
                                                     scale: scale,
                                                     image: image)
        }
        if makeCircleBorder {
            self.layer.cornerRadius = self.frame.size.width / 2.0
        }

        self.image = self.image?.withRenderingMode(renderingMode)
        self.highlightedImage = self.image?.withRenderingMode(renderingMode)

        self.tintColor = tintColor
        if let backgroundColor = backgroundColor {
            self.backgroundColor = backgroundColor
        } else {
            self.backgroundColor = nil
        }

        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor
    }
}
