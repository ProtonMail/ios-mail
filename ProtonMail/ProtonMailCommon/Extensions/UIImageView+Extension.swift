//
//  UIImageView+Extension.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/2.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

extension UIImageView
{
    func setupImage(contentMode: UIView.ContentMode = .center,
                    renderingMode: UIImage.RenderingMode = .alwaysTemplate,
                    scale: CGFloat = 0.5,
                    makeCircleBorder: Bool = true,
                    tintColor: UIColor? = nil,
                    backgroundColor: String? = nil,
                    borderWidth: CGFloat = 0,
                    borderColor: CGColor? = nil) {
        self.contentMode = contentMode
        
        if let image = self.image {
            self.image = UIImage.resizeWithRespectTo(box: self.frame.size,
                                                     scale: scale,
                                                     image: image)
        }
        if makeCircleBorder {
            self.layer.cornerRadius = self.frame.size.width / 2
        }
        
        self.image = self.image?.withRenderingMode(renderingMode)
        self.highlightedImage = self.image?.withRenderingMode(renderingMode)
        
        self.tintColor = tintColor
        if let backgroundColor = backgroundColor {
            self.backgroundColor = UIColor(hexColorCode: backgroundColor)
        } else {
            self.backgroundColor = nil
        }
        
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor
    }
}
