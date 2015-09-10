//
//  RecipientView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/10/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class RecipientView: PMView {
    override func getNibName() -> String {
        return "RecipientView"
    }
    var promptString : String!
    
    @IBOutlet weak var fromLabel: UILabel!
    
    var prompt : String? {
        get {
            return promptString
        }
        set (t) {
            if let t = t {
                promptString = t
            }
        }
    }
    
    var labelValue : String? {
        get {
            return fromLabel.text;
        }
        set (t) {
            if let t = t {
                fromLabel.text = t;
            }
        }
    }
}
