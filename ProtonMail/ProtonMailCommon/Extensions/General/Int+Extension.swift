//
//  Int+Extension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/11/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

extension Int {
    //TODO:: the error code should be in same place, this extension could move to the error code class
    /// check if response code is 5003
    var forceUpgrade : Bool {
        get {
            return self == 5003
        }
    }
}
