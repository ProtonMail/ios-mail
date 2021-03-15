//
//  ContactCollectionViewEntryCell.swift
//  ProtonMail - Created on 4/27/18.
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
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        self.contentView.addSubview(textField)
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[textField]|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["textField": textField]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[textField]-(40)-|",
                                                           options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["textField": textField]))
    
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
    
    var textFieldIdentifier: String {
        get {
            return self.contactEntryTextField?.accessibilityIdentifier ?? ""
        }
        set {
            if let textField = self.contactEntryTextField {
                textField.accessibilityIdentifier = newValue
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
        guard (self.contactEntryTextField?.font) != nil else {
            return 0.0
        }
        
        let s = CGSize(width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude)
        let size = NSString(string: text).boundingRect(with: s,
                                                       options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                       attributes: [NSAttributedString.Key.font : Fonts.h6.light],
                                                       context: nil).size
        return size.width.rounded(.up)
    }
    
}





