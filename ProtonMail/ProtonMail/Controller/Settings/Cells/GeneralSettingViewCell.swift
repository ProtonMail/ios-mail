//
//  GeneralSettingViewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

@IBDesignable class GeneralSettingViewCell: UITableViewCell {
    @IBOutlet weak var LeftText: UILabel!
    @IBOutlet weak var RightText: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    
    func configCell(_ left:String, right:String) {
        LeftText.text = left
        RightText.text = right
    }
}

extension GeneralSettingViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
