//
//  ServerNotice.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/18/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

let serverNotice = ServerNotice()

class ServerNotice {
    
    fileprivate func setTime(_ diff : Int) {
        var new_current_time : Int = Int(Date().timeIntervalSince1970)
        new_current_time = new_current_time + diff
        userCachedStatus.serverNoticesNextTime = String(new_current_time)
    }
    
    // MARK: - Public methods
    func check(_ messages : [String]) {
        guard messages.count > 0 else {
            return
        }
        let cachedMessgaes = userCachedStatus.serverNotices
        let nextTime = Int(userCachedStatus.serverNoticesNextTime) ?? 0
        let currentTime : Int = Int(Date().timeIntervalSince1970)
        
        var need_show = [String]()
        if cachedMessgaes.count <= 0 {
            need_show = messages
        } else {
            for new_msg in messages {
                var found = false
                for cache_msg in cachedMessgaes {
                    if cache_msg == new_msg {
                        found = true
                        break;
                    }
                }
                if !found {
                    need_show.append(new_msg)
                }
            }
        }
        guard need_show.count > 0 || (currentTime - nextTime) > 0 else {
            return
        }
        
        if need_show.count == 0 {
            need_show = messages
        }
        
        var string_show = ""
        for s in need_show {
            string_show += "\n\(s)"
        }
        
        userCachedStatus.serverNotices = messages
        self.setTime(1800)
        var message = ""
        message = NSLocalizedString("\(string_show)")
        let alertController = UIAlertController(
            title: NSLocalizedString("ProtonMail"),
            message: message,
            preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Remind Me Later"), style: .default, handler: { action in
            self.setTime(10)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Don't Show Again"), style: .destructive, handler: { action in
             self.setTime(31536000)//1 year 1 * 365 * 24 * 60 * 60
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}
