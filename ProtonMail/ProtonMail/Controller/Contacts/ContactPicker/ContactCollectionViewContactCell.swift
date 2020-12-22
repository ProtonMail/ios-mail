//
//  ContactCollectionContactCell.swift
//  ProtonMail - Created on 5/3/18.
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


protocol ContactCollectionViewContactCellDelegate: class {
    func collectionContactCell(lockCheck model: ContactPickerModelProtocol, progress: () -> Void, complete: LockCheckComplete?)
    func checkMails(in contactGroup: ContactGroupVO, progress: () -> Void, complete: LockCheckComplete?)
}

class ContactCollectionViewContactCell: UICollectionViewCell {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var contactTitleLabel: UILabel!
    @IBOutlet weak var lockImage: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    @IBOutlet weak var leftConstant: NSLayoutConstraint!
    @IBOutlet weak var widthConstant: NSLayoutConstraint!
    
    weak var delegate : ContactCollectionViewContactCellDelegate?
    
    /// contact model
    var _model: ContactPickerModelProtocol!
    
    /// focused ?
    var _pickerFocused: Bool = false
    
    @objc dynamic var font: UIFont? {
        get { return self.contactTitleLabel.font }
        set {
            self.contactTitleLabel.font = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }
    
    override func prepareForReuse() {
        self.bgView.layer.borderColor = UIColor.clear.cgColor
    }
    
    func setup() {
        self.backgroundColor = UIColor(hexColorCode: "#FCFEFF")
        
        self.contactTitleLabel.textColor = UIColor.blue
        self.bgView.clipsToBounds = true
        self.bgView.layer.cornerRadius = 3.0
        self.bgView.translatesAutoresizingMaskIntoConstraints = false
        
        #if DEBUG_BORDERS
        self.contactTitleLabel.layer.borderColor = UIColor(hexColorCode: "0x6789AB").cgColor
        self.contactTitleLabel.layer.borderWidth = 1.0
        #endif
    }
    
    override func tintColorDidChange() {
        let p = self.pickerFocused
        self.pickerFocused = p
    }
    
    var pickerFocused: Bool {
        get {
            return _pickerFocused
        }
        set {
            _pickerFocused = newValue
            if self._pickerFocused {
                self.contactTitleLabel.textColor = UIColor.white
                //self.contactTitleLabel.backgroundColor = self.tintColor
                self.bgView.backgroundColor = self.tintColor
            }
            else {
                self.contactTitleLabel.textColor = self.tintColor
                //self.contactTitleLabel.backgroundColor = UIColor(red: 0.9214, green: 0.9215, blue: 0.9214, alpha: 1.0)
                self.bgView.backgroundColor = UIColor(red: 0.9214, green: 0.9215, blue: 0.9214, alpha: 1.0)
            }
        }
    }
    
    var model : ContactPickerModelProtocol {
        get {
            return _model
        }
        set {
            self._model = newValue
            
            if let _ = self._model as? ContactVO {
                self.contactTitleLabel.text = self._model.contactTitle;
                
                {
                    self.checkLock(caller: self.model)
                } ~> .main
            } else if let _ = self._model as? ContactGroupVO {
                prepareTitleForContactGroup()
            }
        }
    }
    
    func prepareTitleForContactGroup() {
        if let contactGroup = self._model as? ContactGroupVO {
            
            let (selectedCount, totalCount, color) = contactGroup.getGroupInformation()
            self.contactTitleLabel.text = "\(contactGroup.contactTitle) (\(selectedCount)/\(totalCount))"
            self.contactTitleLabel.textAlignment = .left
            self.lockImage.image = UIImage.init(named: "contact_groups_icon")
            self.lockImage.setupImage(scale: 0.8,
                                      tintColor: UIColor.white,
                                      backgroundColor: UIColor.init(hexString: color, alpha: 1))
            self.checkMails(in: contactGroup)
        }
    }
    
    private func checkLock(caller: ContactPickerModelProtocol) {
        self.delegate?.collectionContactCell(lockCheck: self.model, progress: {
            self.leftConstant.constant = 4
            self.widthConstant.constant = 14
            self.lockImage.isHidden = true
            self.activityView.startAnimating()
        }, complete: { image, type in
            guard caller.equals(self.model) else {
                return
            }
            
            self._model.setType(type: type)
            self.isEmailVerified(type: type)
            self.lockImage.backgroundColor = nil
            self.lockImage.tintColor = nil
            if let img = image {
                self.lockImage.image = img
                self.lockImage.isHidden = false
                self.leftConstant.constant = 4
                self.widthConstant.constant = 14
                
                self.contactTitleLabel.textAlignment = .left
            } else if let lock = self.model.lock {
                self.lockImage.image = lock
                self.lockImage.isHidden = false
                self.leftConstant.constant = 4
                self.widthConstant.constant = 14
                
                self.contactTitleLabel.textAlignment = .left
            } else {
                self.lockImage.image = nil
                self.lockImage.isHidden = true
                self.leftConstant.constant = 0
                self.widthConstant.constant = 0
                
                self.contactTitleLabel.textAlignment = .center
            }
            self.activityView.stopAnimating()
        })
    }
    
    private func checkMails(in group: ContactGroupVO) {
        self.delegate?.checkMails(in: group, progress: { [weak self] in
            self?.leftConstant.constant = 4
            self?.widthConstant.constant = 14
            self?.lockImage.isHidden = true
            self?.activityView.isHidden = false
            self?.activityView.startAnimating()
        }, complete: { [weak self](_, type) in
            let (_, _, color) = group.getGroupInformation()
            self?.isEmailVerified(type: type)
            self?.lockImage.image = UIImage.init(named: "contact_groups_icon")
            self?.lockImage.setupImage(scale: 0.8,
                                      tintColor: UIColor.white,
                                      backgroundColor: UIColor.init(hexString: color, alpha: 1))
            self?.lockImage.isHidden = false
            self?.activityView.isHidden = true
            self?.activityView.stopAnimating()
        })
    }
    
    func widthForCell() -> CGFloat {
        var size = self._model.contactTitle.size(withAttributes: [NSAttributedString.Key.font:  Fonts.h5.light])
        if let _ = self._model as? ContactGroupVO {
            if let estimation = self.contactTitleLabel.text?.size(withAttributes: [NSAttributedString.Key.font:  Fonts.h5.light]) {
                size = estimation
            }
        }
        let offset = self.widthConstant.constant == 0 ? 0 : 14
        return size.width.rounded(.up) + 20 + CGFloat(offset) //34 // 20 + self.contactTitleLabel.frame.height + 6
    }
    
    func widthForCellWithContact(model: ContactPickerModelProtocol) -> CGFloat {
        //TODO:: i feel it isn't good
        if let contactGroup = model as? ContactGroupVO {
            let (selectedCount, totalCount, _) = contactGroup.getGroupInformation()
            let title = "\(contactGroup.contactTitle) (\(selectedCount)/\(totalCount))"
            let size = title.size(withAttributes: [NSAttributedString.Key.font:  Fonts.h5.light])
            return size.width.rounded(.up) + 20 + 14 //
        }
        
        let size = model.contactTitle.size(withAttributes: [NSAttributedString.Key.font:  Fonts.h5.light])
        return size.width.rounded(.up) + 20 + 14 //34 //20 + self.contactTitleLabel.frame.height + 6
    }
    
    private func isEmailVerified(type: Int) {
        // Code=33101 "Email address failed validation"
        // Code=33102 "Recipient could not be found"
        let isBadMail = [33101, 33102].contains(type)
        let color = isBadMail ? UIColor.red.cgColor: UIColor.clear.cgColor
        self.bgView.layer.borderColor = color
        self.bgView.layer.borderWidth = 1
    }
}
