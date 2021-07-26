//
//  ContactEditAddressCell.swift
//  ProtonMail - Created on 5/24/17.
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

import ProtonCore_UIFoundations

final class ContactEditAddressCell: UITableViewCell {
    
    fileprivate var addr : ContactEditAddress!
    fileprivate var delegate : ContactEditCellDelegate?
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var street_two: UITextField!
    @IBOutlet weak var cityField: UITextField!
    @IBOutlet weak var stateField: UITextField!
    @IBOutlet weak var zipField: UITextField!
    @IBOutlet weak var countyField: UITextField!
    
    @IBOutlet weak var vline1: UIView!
    @IBOutlet weak var vline2: UIView!
    @IBOutlet weak var vline3: UIView!
    @IBOutlet weak var vline4: UIView!
    @IBOutlet weak var vline5: UIView!
    @IBOutlet weak var vline6: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.street_two.delegate = self
        self.cityField.delegate = self
        self.stateField.delegate = self
        self.zipField.delegate = self
        self.countyField.delegate = self
        
        self.valueField.placeholder  = LocalString._contacts_street_field_placeholder
        self.valueField.tintColor = UIColorManager.TextHint
        self.street_two.placeholder  = LocalString._contacts_street_field_placeholder
        self.street_two.tintColor = UIColorManager.TextHint
        self.cityField.placeholder   = LocalString._contacts_city_field_placeholder
        self.cityField.tintColor = UIColorManager.TextHint
        self.stateField.placeholder  = LocalString._contacts_state_field_placeholder
        self.stateField.tintColor = UIColorManager.TextHint
        self.zipField.placeholder    = LocalString._contacts_zip_field_placeholder
        self.zipField.tintColor = UIColorManager.TextHint
        self.countyField.placeholder = LocalString._contacts_country_field_placeholder
        self.countyField.tintColor = UIColorManager.TextHint
        self.backgroundColor = UIColorManager.BackgroundNorm
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        vline1.gradient()
        vline2.gradient()
        vline3.gradient()
        vline4.gradient()
        vline5.gradient()
        vline6.gradient()
    }
    
    func configCell(obj : ContactEditAddress, callback : ContactEditCellDelegate?, becomeFirstResponder: Bool = false) {
        self.addr = obj
        self.delegate = callback
        
        typeLabel.attributedText = NSAttributedString(string: self.addr.newType.title,
                                                      attributes: FontManager.Default)
        valueField.attributedText = NSAttributedString(string: self.addr.newStreet,
                                                       attributes: FontManager.Default)
        street_two.attributedText = NSAttributedString(string: self.addr.newStreetTwo,
                                                       attributes: FontManager.Default)
        cityField.attributedText = NSAttributedString(string: self.addr.newLocality,
                                                      attributes: FontManager.Default)
        stateField.attributedText = NSAttributedString(string: self.addr.newRegion,
                                                       attributes: FontManager.Default)
        zipField.attributedText = NSAttributedString(string: self.addr.newPostal,
                                                     attributes: FontManager.Default)
        countyField.attributedText = NSAttributedString(string: self.addr.newCountry,
                                                        attributes: FontManager.Default)
            
        if becomeFirstResponder {
            delay(0.25, closure: {
                self.valueField.becomeFirstResponder()
            })
        }
    }
    
    @IBAction func typeAction(_ sender: UIButton) {
        delegate?.pick(typeInterface: addr, sender: self)
    }
}

extension ContactEditAddressCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        if textField == valueField {
            addr.newStreet = valueField.attributedText?.string ?? ""
        }
        
        if textField == cityField {
            addr.newLocality = cityField.attributedText?.string ?? ""
        }
        
        if textField == street_two {
            addr.newStreetTwo = street_two.attributedText?.string ?? ""
        }
    
        if textField == stateField {
            addr.newRegion = stateField.attributedText?.string ?? ""
        }
        
        if textField == zipField {
            addr.newPostal = zipField.attributedText?.string ?? ""
        }
        
        if textField == countyField {
            addr.newCountry = countyField.text!
        }
    }
}
