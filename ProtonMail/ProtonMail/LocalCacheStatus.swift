//
//  MessageStatus.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



let localCacheStatus = CacheStatus()
class CacheStatus {
    
    struct Key {
        static let lastFetchMessageID = "last_fetch_message_id"
        static let lastFetchMessageTime = "last_fetch_message_time"
        static let lastUpdateTime = "last_update_time"
        static let historyTimeStamp = "history_timestamp"
    }
    
    private var getLastFetchMessageID: String {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey(Key.lastFetchMessageID) ?? "0"
        }
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: Key.lastFetchMessageID)
        }
    }
    
    private var getLastFetchMessageTime: Float {
        get {
            return NSUserDefaults.standardUserDefaults().floatForKey(Key.lastFetchMessageTime)
        }
        set {
            NSUserDefaults.standardUserDefaults().setFloat(newValue, forKey: Key.lastFetchMessageTime)
        }
    }
    
    private var getLastUpdateTime: Float {
        get {
            return NSUserDefaults.standardUserDefaults().floatForKey(Key.lastUpdateTime)
        }
        set {
            NSUserDefaults.standardUserDefaults().setFloat(newValue, forKey: Key.lastUpdateTime)
        }
    }

    
    func signOut()
    {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastFetchMessageID);
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastFetchMessageTime);
        NSUserDefaults.standardUserDefaults().removeObjectForKey(Key.lastUpdateTime);
    }
    
    
    
    
    // MARK: - Public methods
    
//    func checkSpace(#usedSpace: Int, maxSpace: Int) {
//        if isCheckSpaceDisabled {
//            return
//        }
//        
//        let maxSpace = Double(maxSpace)
//        let usedSpace = Double(usedSpace)
//        let threshold = spaceWarningThreshold/100.0 * maxSpace
//        
//        if maxSpace == 0 || usedSpace < threshold {
//            return
//        }
//        
//        let formattedMaxSpace = NSByteCountFormatter.stringFromByteCount(Int64(maxSpace), countStyle: NSByteCountFormatterCountStyle.File)
//        var message = ""
//        
//        if usedSpace >= maxSpace {
//            message = NSLocalizedString("You have used up all of your storage space (\(formattedMaxSpace)).")
//        } else {
//            message = NSLocalizedString("You have used \(spaceWarningThreshold)% of your storage space (\(formattedMaxSpace)).")
//        }
//        
//        let alertController = UIAlertController(
//            title: NSLocalizedString("Space Warning"),
//            message: message,
//            preferredStyle: .Alert)
//        alertController.addOKAction()
//        alertController.addAction(UIAlertAction(title: NSLocalizedString("Hide"), style: .Destructive, handler: { action in
//            self.isCheckSpaceDisabled = true
//        }))
//        
//        UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
//    }
}