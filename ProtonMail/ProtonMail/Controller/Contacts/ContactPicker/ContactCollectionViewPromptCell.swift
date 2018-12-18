//
//  ContactCollectionViewPromptCell.swift
//  ProtonMail - Created on 4/27/18.
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

class ContactCollectionViewPromptCell: UICollectionViewCell {
    
    var _prompt : String = ContactPickerDefined.kPrompt
    var promptLabel: UILabel!
    var insets: UIEdgeInsets!
    
    @objc dynamic var font: UIFont? {
        get { return self.promptLabel.font }
        set {
            self.promptLabel.font = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init(coder: aDecoder)
        self.setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    func setup() {
        self.insets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        
        #if DEBUG_BORDERS
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.purple.cgColor
        #endif
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(label)
    
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[label]|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["label": label]))

        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["label": label]))
        
        label.textAlignment = .left
        label.text = self.prompt
        label.textColor = UIColor.black

        self.promptLabel = label
}
    
    var prompt : String {
        get {
            return self._prompt
        }
        set {
            self._prompt = newValue
            self.promptLabel.text = self._prompt
        }
    }
    
    //TODO:: here need change to depends on real string size
    class func widthWithPrompt(prompt: String) -> CGFloat {
        return 5.0
    }
    


}
