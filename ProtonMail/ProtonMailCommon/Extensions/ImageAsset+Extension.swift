//
//  ImageAsset+Extension.swift
//  ProtonMail
//
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

extension UIImage {
    
    func toTemplateUIImage() -> UIImage {
        return self.withRenderingMode(.alwaysTemplate)
    }
    
    /// Only returns with templateImage when given tintColor
    func toUIImageView( tintColor: UIColor? = nil ) -> UIImageView {
        if let tintColor = tintColor {
            let imageView = UIImageView(image: toTemplateUIImage())
            imageView.tintColor = tintColor
            return imageView
        }
        return UIImageView(image: self)
    }
    
    /// Create a BarButtonItem from IageAsset
    ///
    /// ### Support
    /// - change image's tintColor and image's size
    /// - add background color as round or square
    func toUIBarButtonItem( target: Any?, action: Selector?,
                            style: UIBarButtonItem.Style = .plain, tintColor: UIColor? = nil, squareSize: CGFloat = 24.0,
                            backgroundColor: UIColor? = nil, backgroundSquareSize: CGFloat? = nil, isRound: Bool? = nil ) -> UIBarButtonItem {
        // Somehow alwaysTemplate should be add after resize
        let image = self.resizeImage(squareSize, opaque: false).withRenderingMode(.alwaysTemplate)
        
        if let backgroundColor = backgroundColor,
           let backgroundSquareSize = backgroundSquareSize,
           let isRound = isRound {
            let profileButton = UIButton()
            profileButton.setImage(image, for: .normal)
            profileButton.backgroundColor = backgroundColor
            
            profileButton.heightAnchor.constraint(equalToConstant: backgroundSquareSize).isActive = true
            profileButton.widthAnchor.constraint(equalToConstant: backgroundSquareSize).isActive = true
            
            if isRound {
                profileButton.layer.cornerRadius = backgroundSquareSize/2
                profileButton.layer.masksToBounds = true
            }
            if let tintColor = tintColor {
                profileButton.tintColor = tintColor
            }
            if let action = action {
                profileButton.addTarget(target, action: action, for: .touchDown)
            }
            return UIBarButtonItem(customView: profileButton)
        }
        if let tintColor = tintColor {
            let barButtonItem = UIBarButtonItem(image: image, style: style, target: target, action: action)
            barButtonItem.tintColor = tintColor
            return barButtonItem
        }
        return UIBarButtonItem(image: image, style: .plain, target: target, action: action)
    }
    
}
