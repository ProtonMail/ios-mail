//
//  ContactEditOrgCell.swift
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

final class ContactEditInformationCell: UITableViewCell {
    
    fileprivate var information : ContactEditInformation!
    fileprivate var delegate : ContactEditCellDelegate?
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeButton: UIButton!
    @IBOutlet weak var valueField: UITextField!
    @IBOutlet weak var sepratorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
        self.typeButton.isHidden = true
        self.typeButton.isEnabled = false
        valueField.tintColor = ColorProvider.TextHint
        backgroundColor = ColorProvider.BackgroundNorm
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sepratorView.gradient()
    }
    
    func configCell(obj : ContactEditInformation, callback : ContactEditCellDelegate?, becomeFirstResponder: Bool = false) {
        self.information = obj
        self.delegate = callback
        
        typeLabel.attributedText = NSAttributedString(string: self.information.infoType.title,
                                                      attributes: FontManager.Default)
        valueField.placeholder = self.information.infoType.title
        valueField.attributedText = NSAttributedString(string: self.information.newValue,
                                                       attributes: FontManager.Default)

        if becomeFirstResponder {
            delay(0.25, closure: {
                self.valueField.becomeFirstResponder()
            })
        }
    }
    
    @IBAction func typeAction(_ sender: UIButton) {
        //delegate?.pick(typeInterface: org, sender: self)
    }
}

extension ContactEditInformationCell: UITextFieldDelegate {
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
        information.newValue = valueField.attributedText?.string ?? ""
    }
}
