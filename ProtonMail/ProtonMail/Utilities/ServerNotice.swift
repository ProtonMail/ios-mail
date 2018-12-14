//
//  ServerNotice.swift
//  ProtonMail - Created on 11/18/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
        let message = string_show
        let alertController = UIAlertController(title: LocalString._protonmail,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: LocalString._remind_me_later, style: .default, handler: { action in
            self.setTime(10)
        }))
        alertController.addAction(UIAlertAction(title: LocalString._dont_show_again, style: .destructive, handler: { action in
            self.setTime(31536000)//1 year 1 * 365 * 24 * 60 * 60
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}
