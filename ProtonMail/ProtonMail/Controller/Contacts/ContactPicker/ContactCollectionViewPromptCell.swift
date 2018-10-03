//
//  ContactCollectionViewPromptCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/27/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

//    - (instancetype)initWithPrompt:(NSString*)prompt
//    {
//    self = [super init]
//    if (self)
//    {
//    self.prompt = prompt
//    [self setup]
//    }
//    return self
//    }
//

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
