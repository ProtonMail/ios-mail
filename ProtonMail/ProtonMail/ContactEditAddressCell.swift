//
//  ContactEditAddressCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/24/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


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
    
    fileprivate var isPaid : Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.street_two.delegate = self
        self.cityField.delegate = self
        self.stateField.delegate = self
        self.zipField.delegate = self
        self.countyField.delegate = self
        
        self.valueField.placeholder  = LocalString._contacts_street_field_placeholder
        self.street_two.placeholder  = LocalString._contacts_street_field_placeholder
        self.cityField.placeholder   = LocalString._contacts_city_field_placeholder
        self.stateField.placeholder  = LocalString._contacts_state_field_placeholder
        self.zipField.placeholder    = LocalString._contacts_zip_field_placeholder
        self.countyField.placeholder = LocalString._contacts_country_field_placeholder
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
    
    func configCell(obj : ContactEditAddress, paid: Bool, callback : ContactEditCellDelegate?, becomeFirstResponder: Bool = false) {
        self.addr = obj
        self.isPaid = paid
        self.delegate = callback
        
        typeLabel.text = self.addr.newType.title
        valueField.text = self.addr.newStreet
        street_two.text = self.addr.newStreetTwo
        cityField.text = self.addr.newLocality
        stateField.text = self.addr.newRegion
        zipField.text = self.addr.newPostal
        countyField.text = self.addr.newCountry
            
        if self.isPaid {
            if becomeFirstResponder {
                delay(0.25, closure: {
                    self.valueField.becomeFirstResponder()
                })
            }
        }
    }
    
    @IBAction func typeAction(_ sender: UIButton) {
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return
        }
        delegate?.pick(typeInterface: addr, sender: self)
    }
}

extension ContactEditAddressCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return false
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        guard self.isPaid else {
            self.delegate?.featureBlocked()
            return
        }
        if textField == valueField {
            addr.newStreet = valueField.text!
        }
        
        if textField == cityField {
            addr.newLocality = cityField.text!
        }
        
        if textField == street_two {
            addr.newStreetTwo = street_two.text!
        }
    
        if textField == stateField {
            addr.newRegion = stateField.text!
        }
        
        if textField == zipField {
            addr.newPostal = zipField.text!
        }
        
        if textField == countyField {
            addr.newCountry = countyField.text!
        }
    }
}
