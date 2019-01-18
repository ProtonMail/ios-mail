//
//  UIImageView+Extension.swift
//  ProtonMail - Created on 2018/10/2.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation

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
