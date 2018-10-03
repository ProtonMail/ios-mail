//
//  EmailAttachmentView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/29/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


class EmailAttachmentView: UITableView {
    
    required init() {
        super.init(frame: CGRect.zero, style: UITableView.Style.plain)
        self.backgroundColor = UIColor.white
        self.layoutIfNeeded()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
