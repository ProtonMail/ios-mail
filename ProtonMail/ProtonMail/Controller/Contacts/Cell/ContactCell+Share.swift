//
//  ContactCell+Share.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/11.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

protocol ContactCellShare: class
{
    func prepareContactGroupIcons(cell: UITableViewCell,
                                  contactGroupColors: [String],
                                  iconStackView: UIStackView,
                                  iconStackViewWidthConstraint: NSLayoutConstraint)
}

extension ContactCellShare
{
    func prepareContactGroupIcons(cell: UITableViewCell,
                                  contactGroupColors: [String],
                                  iconStackView: UIStackView,
                                  iconStackViewWidthConstraint: NSLayoutConstraint) {
        // clear and set stackView
        iconStackView.clearAllViews()
        iconStackView.alignment = .center
        iconStackView.distribution = .fillProportionally
        
        iconStackView.spacing = 4.0
        let height: CGFloat = min(20.0, iconStackView.frame.size.height) // limiting factor is this
        let width: CGFloat = height
        
        if contactGroupColors.count > 0 {
            let imageName = "contact_groups_icon"
            
            for contactGroupColor in contactGroupColors {
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
                                         backgroundColor: contactGroupColor)
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
            }
            
            iconStackViewWidthConstraint.constant = height * CGFloat.init(contactGroupColors.count) + iconStackView.spacing * CGFloat.init(contactGroupColors.count - 1)
            cell.layoutIfNeeded()
        }
    }
}
