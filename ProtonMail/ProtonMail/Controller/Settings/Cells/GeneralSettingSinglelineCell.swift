//
//  GeneralSettingViewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class GeneralSettingSinglelineCell: UITableViewCell {
    @IBOutlet weak var LeftText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configCell(_ left:String) {
        LeftText.text = left
    }
}
