//
//  GeneralSettingViewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class GeneralSettingViewCell: UITableViewCell {

    @IBOutlet weak var LeftText: UILabel!
    @IBOutlet weak var RightText: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    
    func configCell(left:String, right:String) {
        LeftText.text = left
        RightText.text = right
    }
    
}
