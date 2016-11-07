//
//  PMWebView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/20/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation


class  PMWebView: UIWebView {
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
}
