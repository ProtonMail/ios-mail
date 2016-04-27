//
//  FeedbackTableCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/14/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation



class FeedbackTableViewCell: UITableViewCell {

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var labelView: UILabel!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    func configCell(item : FeedbackItem?) {
        if let item = item {
            iconView.image = UIImage(named: item.image)
            labelView.text = item.title
        }
        
    }
}