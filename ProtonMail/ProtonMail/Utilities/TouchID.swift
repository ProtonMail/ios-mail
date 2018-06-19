 //
//  TouchID.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/6/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

let sharedTouchID = TouchID ()

class TouchID {
    
    func showTouchIDOrPin() -> Bool {
        if userCachedStatus.isPinCodeEnabled || userCachedStatus.isTouchIDEnabled {
            if userCachedStatus.lockedApp {
                return true
            }
            
            var timeIndex : Int = -1
            if let t = Int(userCachedStatus.lockTime) {
                timeIndex = t
            }
            if timeIndex == 0 {
                return true
            } else if timeIndex > 0 {
                var exitTime : Int = 0
                if let t = Int(userCachedStatus.exitTime) {
                    exitTime = t
                }
                let timeInterval : Int = Int(Date().timeIntervalSince1970)
                let diff = timeInterval - exitTime
                if diff > (timeIndex*60) || diff <= 0 {
                    return true
                }
            }
        }
        return false
    }
}
