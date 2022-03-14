//
//  ServerNotice.swift
//  ProtonMail - Created on 11/18/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

let serverNotice = ServerNotice()

class ServerNotice {

    fileprivate func setTime(_ diff: Int) {
        var new_current_time: Int = Int(Date().timeIntervalSince1970)
        new_current_time = new_current_time + diff
        userCachedStatus.serverNoticesNextTime = String(new_current_time)
    }

    // MARK: - Public methods
    func check(_ messages: [String]) {
        guard messages.count > 0 else {
            return
        }
        let cachedMessgaes = userCachedStatus.serverNotices
        let nextTime = Int(userCachedStatus.serverNoticesNextTime) ?? 0
        let currentTime: Int = Int(Date().timeIntervalSince1970)

        var need_show = [String]()
        if cachedMessgaes.count <= 0 {
            need_show = messages
        } else {
            for new_msg in messages {
                var found = false
                for cache_msg in cachedMessgaes {
                    if cache_msg == new_msg {
                        found = true
                        break
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
            self.setTime(31536000)// 1 year 1 * 365 * 24 * 60 * 60
        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
}
