//
//  ContactCell+Share.swift
//  ProtonMail - Created on 2018/10/11.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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


import UIKit

protocol ContactCellShare: AnyObject
{
    func prepareContactGroupIcons(cell: UITableViewCell,
                                  contactGroupColors: [String],
                                  iconStackView: UIStackView,
                                  showNoneLabel: Bool)
}

extension ContactCellShare
{
    func prepareContactGroupIcons(cell: UITableViewCell,
                                  contactGroupColors: [String],
                                  iconStackView: UIStackView,
                                  showNoneLabel: Bool = true) {
        // clear and set stackView
        iconStackView.clearAllViews()
        iconStackView.alignment = .center
        iconStackView.distribution = .fillProportionally
        
        iconStackView.spacing = 4.0
        let height: CGFloat = min(20.0, iconStackView.frame.size.height) // limiting factor is this
        let width: CGFloat = height
        
        if contactGroupColors.count > 0 {
            let imageName = "contact_groups_icon"
            
            let limit = 3 // we only show 3 of the groups
            for (i, contactGroupColor) in contactGroupColors.enumerated() {
                if i < limit {
                    // setup image
                    var image = UIImage.init(named: imageName)
                    if var imageUnwrapped = image {
                        imageUnwrapped = imageUnwrapped.withRenderingMode(.alwaysTemplate)
                        if let imageUnwrapped = UIImage.resize(image: imageUnwrapped,
                                                               targetSize: CGSize.init(width: width,
                                                                                       height: height)) {
                            image = imageUnwrapped
                        }
                    }
                    
                    // setup imageView
                    if let image = image {
                        let imageView = UIImageView.init(image: image)
                        imageView.setupImage(scale: 0.7,
                                             makeCircleBorder: true,
                                             tintColor: UIColor.white,
                                             backgroundColor: UIColor.init(hexString: contactGroupColor,
                                                                           alpha: 1))
                        imageView.translatesAutoresizingMaskIntoConstraints = false
                        let heightConstraint = NSLayoutConstraint.init(item: imageView,
                                                                       attribute: .height,
                                                                       relatedBy: .equal,
                                                                       toItem: nil,
                                                                       attribute: .notAnAttribute,
                                                                       multiplier: 1.0,
                                                                       constant: height)
                        let widthConstraint = NSLayoutConstraint.init(item: imageView,
                                                                      attribute: .width,
                                                                      relatedBy: .equal,
                                                                      toItem: nil,
                                                                      attribute: .notAnAttribute,
                                                                      multiplier: 1.0,
                                                                      constant: width)
                        
                        // add to stack view
                        iconStackView.addArrangedSubview(imageView)
                        iconStackView.addConstraints([heightConstraint, widthConstraint])
                    }
                } else {
                    break
                }
            }
        } else {
            if showNoneLabel {
                let label = UILabel.init(attributedString: LocalString._contact_group_no_contact_group_associated_with_contact_email.apply(style: .Default))
                iconStackView.addArrangedSubview(label)
            }
        }
        
        cell.layoutIfNeeded()
    }
}
