//
//  FeedbackHeadCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/14/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


class FeedbackHeadCell: UITableViewCell {
    
    @IBOutlet weak var headerLabel: UILabel!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configCell(text : String) {
        headerLabel.text = text
    }
    
}