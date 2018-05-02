//
//  ContactCollectionViewContactCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/27/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class ContactCollectionViewContactCell: UICollectionViewCell {
    
    var contactTitleLabel: UILabel!
    var _model: ContactPickerModelProtocol!
    var _pickerFocused: Bool = false
    
    @objc dynamic var font: UIFont? {
        get { return self.contactTitleLabel.font }
        set {
            self.contactTitleLabel.font = newValue
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

    func setup() {
        self.backgroundColor = UIColor(hexColorCode: "#FCFEFF")
        let contactLabel = UILabel(frame: self.bounds)
        self.addSubview(contactLabel)
        contactLabel.textColor = UIColor.blue
        contactLabel.textAlignment = .center
        contactLabel.clipsToBounds = true;
        contactLabel.layer.cornerRadius = 3.0

#if DEBUG_BORDERS
        contactLabel.layer.borderColor = UIColor(hexColorCode: "0x6789AB").cgColor
        contactLabel.layer.borderWidth = 1.0;
#endif
        
        contactLabel.translatesAutoresizingMaskIntoConstraints = false;
        self.contactTitleLabel = contactLabel
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(8)-[contactLabel]-(8)-|",
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["contactLabel": contactLabel]))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(8)-[contactLabel]-(8)-|",
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["contactLabel": contactLabel]))
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
                self.contactTitleLabel.backgroundColor = self.tintColor
            }
            else {
                self.contactTitleLabel.textColor = self.tintColor
                self.contactTitleLabel.backgroundColor = UIColor(red: 0.9214, green: 0.9215, blue: 0.9214, alpha: 1.0)
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
    
    func widthForCellWithContact(model: ContactPickerModelProtocol) -> CGFloat {
        let font = self.contactTitleLabel.font!
        let s = CGSize(width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude)
        let size = NSString(string: model.contactTitle).boundingRect(with: s,
                                                                     options: NSStringDrawingOptions(rawValue: 0),
                                                                     attributes: [NSAttributedStringKey.font : font],
                                                                     context: nil).size
        return size.width.rounded(.up) + 20.0
    }
}


