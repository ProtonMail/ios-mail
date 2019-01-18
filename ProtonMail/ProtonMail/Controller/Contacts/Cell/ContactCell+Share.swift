//
//  ContactCell+Share.swift
//  ProtonMail - Created on 2018/10/11.
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

protocol ContactCellShare: class
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
                let label = UILabel.init(font: UIFont.systemFont(ofSize: 17),
                                         text: LocalString._contact_group_no_contact_group_associated_with_contact_email,
                                         textColor: UIColor.gray)
                iconStackView.addArrangedSubview(label)
            }
        }
        
        cell.layoutIfNeeded()
    }
}
