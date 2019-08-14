//
//  ContactCollectionViewEntryCell.swift
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


@objc protocol UITextFieldDelegateImproved: UITextFieldDelegate {
    
    @objc func textFieldDidChange(textField: UITextField)
}

class ContactCollectionViewEntryCell: UICollectionViewCell {

    weak var _delegate: UITextFieldDelegateImproved?
    
    private var contactEntryTextField: UITextField?
    
    @objc dynamic var font: UIFont? {
        get {
            return self.contactEntryTextField?.font
            
        }
        set {
            self.contactEntryTextField?.font = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setup() {
        let textField = UITextField(frame: self.bounds)
        textField.delegate = self._delegate
        textField.text = " "
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.keyboardType = .emailAddress
        
#if DEBUG_BORDERS
        self.layer.borderColor = UIColor.orange.cgColor
        self.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.green.cgColor
        textField.layer.borderWidth = 2.0
#endif

        self.addSubview(textField)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[textField]|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["textField": textField]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[textField]|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["textField": textField]))
        
        textField.translatesAutoresizingMaskIntoConstraints = false
    
        self.contactEntryTextField = textField
        
    }
    
    var delegate : UITextFieldDelegateImproved? {
        get {
            return _delegate
        }
        set {
            guard let textField = self.contactEntryTextField else {
                return
            }
            
            if _delegate != nil {
                textField.removeTarget(_delegate,
                                       action: #selector(UITextFieldDelegateImproved.textFieldDidChange(textField:)),
                                       for: .editingChanged)
            }
            
            _delegate = newValue
            textField.addTarget(_delegate,
                                action: #selector(UITextFieldDelegateImproved.textFieldDidChange(textField:)),
                                for: .editingChanged)
            textField.delegate = _delegate
        }
    }

    var text: String {
        get {
            return self.contactEntryTextField?.text ?? ""
        }
        set {
            if let textFeild = self.contactEntryTextField {
                textFeild.text = newValue
            }
        }
    }
    
    var enabled: Bool {
        get {
            return self.contactEntryTextField?.isEnabled ?? false
        }
        set {
            if let textFeild = self.contactEntryTextField {
                textFeild.isEnabled = newValue
            }
        }
    }
    
    func reset() {
         if let textfield = self.contactEntryTextField {
            textfield.text = " "
            self.delegate?.textFieldDidChange(textField: textfield)
        }
    }
    
    func setFocus() {
        if let textfield = self.contactEntryTextField {
            textfield.becomeFirstResponder()
        }
    }
    
    func removeFocus() {
        if let textfield = self.contactEntryTextField {
            textfield.resignFirstResponder()
        }
    }
    
    func widthForText(text: String) -> CGFloat {
        //        guard let font = self.contactEntryTextField?.font else {
        //            return 0.0
        //        }
        //
        //        let font = Fonts.h6.light
        //
        //        let s = CGSize(width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude)
        //        let size = NSString(string: text).boundingRect(with: s,
        //                                                       options: NSStringDrawingOptions.usesLineFragmentOrigin,
        //                                                       attributes: [NSAttributedStringKey.font : font],
        //                                                       context: nil).size
        //        return size.width.rounded(.up)
        
        return 40  //this will avoid the text input disapeared
    }
    
}





