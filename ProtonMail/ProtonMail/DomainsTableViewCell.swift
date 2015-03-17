//
//  DomainsTableViewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class DomainsTableViewCell: UITableViewCell {

    @IBOutlet weak var domainText: UILabel!
    @IBOutlet weak var defaultMark: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
