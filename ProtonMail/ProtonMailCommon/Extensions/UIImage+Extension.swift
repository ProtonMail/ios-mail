// Copyright (c) 2021 Proton AG
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

extension UIImage {

    class func resizeWithRespectTo(box size: CGSize, scale: CGFloat, image: UIImage) -> UIImage? {
        return UIImage.resize(image: image, targetSize: CGSize.init(width: size.width * scale,
                                                                    height: size.height * scale))
    }

    class func resize(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio  = targetSize.width / image.size.width
        let heightRatio = targetSize.height / image.size.height

        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    /// Only supports contentMode as `.scaleAspectFit`
    ///
    /// ### Reference
    /// https://stackoverflow.com/questions/31314412/how-to-resize-image-in-swift
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage

        let size = self.size
        let aspectRatio = size.width / size.height

        switch contentMode {
        case .scaleAspectFit:
            if aspectRatio > 1 {                            // Landscape image
                width = dimension
                height = dimension / aspectRatio
            } else {                                        // Portrait image
                height = dimension
                width = dimension * aspectRatio
            }

        default:
            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }

        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = opaque
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
            newImage = renderer.image {
                (context) in
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }

        return newImage
    }
}

extension UIImage {
    func toTemplateUIImage() -> UIImage {
        return self.withRenderingMode(.alwaysTemplate)
    }

    /// Create a BarButtonItem from IageAsset
    ///
    /// ### Support
    /// - change image's tintColor and image's size
    /// - add background color as round or square
    func toUIBarButtonItem( target: Any?,
                            action: Selector?,
                            style: UIBarButtonItem.Style = .plain,
                            tintColor: UIColor? = nil,
                            squareSize: CGFloat = 24.0,
                            backgroundColor: UIColor? = nil,
                            backgroundSquareSize: CGFloat? = nil,
                            isRound: Bool = false,
                            imageInsets: UIEdgeInsets? = nil) -> UIBarButtonItem {
        // Somehow alwaysTemplate should be add after resize
        let image = self.resizeImage(squareSize, opaque: false).withRenderingMode(.alwaysTemplate)

        if let backgroundColor = backgroundColor,
           let backgroundSquareSize = backgroundSquareSize {
            let profileButton = UIButton()
            profileButton.setImage(image, for: .normal)
            if let imageInsets = imageInsets {
                profileButton.imageEdgeInsets = imageInsets
            }
            profileButton.backgroundColor = backgroundColor

            profileButton.heightAnchor.constraint(equalToConstant: backgroundSquareSize).isActive = true
            profileButton.widthAnchor.constraint(equalToConstant: backgroundSquareSize).isActive = true

            if isRound {
                profileButton.layer.cornerRadius = backgroundSquareSize / 2.0
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
            if let imageInsets = imageInsets {
                barButtonItem.imageInsets = imageInsets
            }
            barButtonItem.tintColor = tintColor
            return barButtonItem
        }
        return UIBarButtonItem(image: image, style: .plain, target: target, action: action)
    }
}
