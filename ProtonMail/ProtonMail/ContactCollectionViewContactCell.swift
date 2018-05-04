//
//  ContactCollectionContactCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/3/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit


class ContactCollectionViewContactCell: UICollectionViewCell {
    
//    var contactTitleLabel: UILabel!
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var contactTitleLabel: UILabel!
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
    
    func setup() {
        self.backgroundColor = UIColor(hexColorCode: "#FCFEFF")
        
        self.contactTitleLabel.textColor = UIColor.blue
//        self.contactTitleLabel.textAlignment = .center
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
            self.contactTitleLabel.text = self._model.contactTitle
        }
    }
    
    func widthForCell() -> CGFloat {
        let size = self._model.contactTitle.size(withAttributes: [NSAttributedStringKey.font:  Fonts.h6.light])
        return size.width.rounded(.up) + 34 // 20 + self.contactTitleLabel.frame.height + 6
    }
    
    func widthForCellWithContact(model: ContactPickerModelProtocol) -> CGFloat {
        //        let font = self.contactTitleLabel.font!
        //        let s = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        //        let size = NSString(string: model.contactTitle).boundingRect(with: s,
        //                                                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
        //                                                                     attributes: [NSAttributedStringKey.font : font],
        //                                                                     context: nil).size
        //        let size2 = NSString(string: model.contactTitle).size(withAttributes: [NSAttributedStringKey.font : font])
        //
        //        let size3 = model.contactTitle.size(withAttributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14.0)])
        //
        let size = model.contactTitle.size(withAttributes: [NSAttributedStringKey.font:  Fonts.h6.light])
        return size.width.rounded(.up) + 34 //20 + self.contactTitleLabel.frame.height + 6
    }
}
