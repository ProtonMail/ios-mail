//
//  ServicePlanCapability.swift
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


class ServicePlanCapability: UIView {
    internal private(set) var context: Any?
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var serviceIcon: UIImageView!
    
    convenience init(image: UIImage? = nil,
                     title: NSAttributedString? = nil,
                     serviceIconVisible: Bool = false,
                     context: Any? = nil)
    {
        self.init(frame: .zero)
        defer {
            self.setup(image: image, title: title, serviceIconVisible: serviceIconVisible, context: context)
        }
    }
    
    func setup(image: UIImage? = nil,
               title: NSAttributedString? = nil,
               serviceIconVisible: Bool = false,
               context: Any? = nil)
    {
        if image != nil {
            self.icon.image = image?.withRenderingMode(.alwaysTemplate)
        } else {
            self.icon.isHidden = true
        }
        self.title.attributedText = title
        self.serviceIcon.isHidden = !serviceIconVisible
        self.context = context
        
        self.isAccessibilityElement = true
        self.title.isAccessibilityElement = false
        self.icon.isAccessibilityElement = false
        self.serviceIcon.isAccessibilityElement = false
        
        self.accessibilityLabel = title?.string
        self.accessibilityTraits = serviceIconVisible ? UIAccessibilityTraits.button : UIAccessibilityTraits.staticText
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
        self.serviceIcon.tintColor = .gray
        self.serviceIcon.image = UIImage(named: "pin_code_confirm")?.withRenderingMode(.alwaysTemplate)
        self.icon.tintColor = UIColor.ProtonMail.ButtonBackground
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let xInset: CGFloat = 40 /* leading+trailing insets*/ + 17 /* icon constraint */ + 8 /* stack view spacing */ + (self.serviceIcon.isHidden ? 0 : (40 /* serviceIcon constraint */ + 8 /* stack view spacing */))
        
        var textSpace = CGRect(origin: .zero, size: size)
        textSpace = textSpace.insetBy(dx: xInset/2, dy: 0)
        var textSize = self.title.textRect(forBounds: textSpace, limitedToNumberOfLines: 0)
        
        textSize.size.width = size.width
        if textSize.height < 56 { /* good readible height */
            textSize = textSize.insetBy(dx: 0, dy: (textSize.height - 56)/2)
        } else {
            textSize = textSize.insetBy(dx: 0, dy: -8)
        }
        return textSize.size
    }
}
