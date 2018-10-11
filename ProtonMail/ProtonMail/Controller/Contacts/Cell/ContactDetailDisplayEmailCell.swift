//
//  ContactDetailDisplayEmailCell.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/10.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactDetailDisplayEmailCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UILabel!
    @IBOutlet weak var iconStackView: UIStackView!
    @IBOutlet weak var iconStackViewWidthConstraint: NSLayoutConstraint!
    
    
    func configCell(title: String, value: String, contactGroupColors: [String]) {        
        self.title.text = title
        self.value.text = value
        
        // clear iconStackView
        iconStackView.clearAllViews()
        iconStackView.alignment = .center
        iconStackView.distribution = .fillProportionally
        iconStackView.spacing = 4.0
        let height: CGFloat = iconStackView.frame.size.height // limiting factor is this
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
                    imageView.setupImage(scale: 0.5,
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
            self.layoutIfNeeded()
        }
    }
    
}
