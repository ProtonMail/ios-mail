//
//  ServerNotice.swift
//  Proton Mail - Created on 11/18/16.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

final class ServerNotice {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    private func setTime(_ diff: Int) {
        var newCurrentTime = Int(Date().timeIntervalSince1970)
        newCurrentTime += diff
        userDefaults[.showServerNoticesNextTime] = String(newCurrentTime)
    }

    // MARK: - Public methods

    func check(_ messages: [String]) {
        guard !messages.isEmpty else {
            return
        }
        let cachedMessages = userDefaults[.cachedServerNotices]
        let nextTime = Int(userDefaults[.showServerNoticesNextTime]) ?? 0
        let currentTime = Int(Date().timeIntervalSince1970)

        var messagesToBeShown = [String]()
        if cachedMessages.isEmpty {
            messagesToBeShown = messages
        } else {
            for newMsg in messages {
                var found = false
                for cachedMsg in cachedMessages where cachedMsg == newMsg {
                    found = true
                }
                if !found {
                    messagesToBeShown.append(newMsg)
                }
            }
        }
        guard !messagesToBeShown.isEmpty || (currentTime - nextTime) > 0 else {
            return
        }

        if messagesToBeShown.isEmpty {
            messagesToBeShown = messages
        }

        var result = ""
        for message in messagesToBeShown {
            result += "\n\(message)"
        }

        userDefaults[.cachedServerNotices] = messages
        self.setTime(1_800)
        showAlert(message: result)
    }

    private func showAlert(message: String) {
        let alertController = UIAlertController(
            title: LocalString._protonmail,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(title: LocalString._remind_me_later, style: .default, handler: { _ in
                self.setTime(10)
            })
        )
        alertController.addAction(
            UIAlertAction(title: LocalString._dont_show_again, style: .destructive, handler: { _ in
                self.setTime(31_536_000) // 1 year 1 * 365 * 24 * 60 * 60
            })
        )
#if !APP_EXTENSION
        UIApplication.shared.topMostWindow?.rootViewController?.present(
            alertController,
            animated: true,
            completion: nil
        )
#endif
    }
}
