//
//  Header.swift
//  ProtonMail - Created on 12/08/2018.
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


import UIKit

class ServicePlanHeader: UIView {
    @IBOutlet private weak var icon: UIImageView!
    @IBOutlet private weak var subtitle: UILabel!
    @IBOutlet private weak var subicon: UILabel!
    
    convenience init(image: UIImage? = nil,
                     title: String? = nil,
                     subicon: (String, UIColor)? = nil)
    {
        self.init(frame: .zero)
        defer {
            self.setup(image: image, title: title, subicon: subicon)
        }
    }
    
    func setup(image: UIImage? = nil,
               title: String? = nil,
               subicon: (String, UIColor)? = nil)
    {
        self.icon.image = image
        self.subtitle.text = title
        self.icon.isAccessibilityElement = false
        self.subtitle.isAccessibilityElement = false
        self.subicon.isAccessibilityElement = false
        self.isAccessibilityElement = true
        
        if let subicon = subicon {
            self.subicon.text = subicon.0
            self.subicon.textColor = subicon.1
            self.accessibilityLabel = "ProtonMail " + subicon.0 + ": " + (title ?? "")
        } else {
            self.subicon.isHidden = true
            self.accessibilityLabel = title
        }
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadFromNib()
        self.setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadFromNib()
        self.setupSubviews()
    }
    
    private func setupSubviews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.icon.tintColor = UIColor.ProtonMail.ButtonBackground
    }
}
