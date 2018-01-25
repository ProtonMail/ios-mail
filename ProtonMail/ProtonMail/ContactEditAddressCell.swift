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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.street_two.delegate = self
        self.cityField.delegate = self
        self.stateField.delegate = self
        self.zipField.delegate = self
        self.countyField.delegate = self
        
        self.valueField.placeholder = NSLocalizedString("Street", comment: "contact placeholder")
        self.street_two.placeholder = NSLocalizedString("Street", comment: "contact placeholder")
        self.cityField.placeholder = NSLocalizedString("City", comment: "contact placeholder")
        self.stateField.placeholder = NSLocalizedString("State", comment: "contact placeholder")
        self.zipField.placeholder = NSLocalizedString("ZIP", comment: "contact placeholder")
        self.countyField.placeholder = NSLocalizedString("Country", comment: "contact placeholder")
        
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
        
        typeLabel.text = self.addr.newType.title
        valueField.text = self.addr.newStreet
        
        cityField.text = self.addr.newLocality
        stateField.text = self.addr.newRegion
        zipField.text = self.addr.newPostal
        countyField.text = self.addr.newCountry
        
        self.delegate = callback
        
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        if textField == valueField {
            addr.newStreet = valueField.text!
        }
        
        if textField == cityField {
            addr.newLocality = cityField.text!
        }
        
        if textField == street_two {
            addr.newStreet = cityField.text!
        }
        
        self.street_two.delegate = self
    
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
