//
//  StorageLimit.swift
//  ProtonMail
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


import Foundation
import UIKit

protocol StorageLimit {}

extension StorageLimit {
    
    // MARK: - Public methods
    func checkSpace(_ usedSpace: Int64, maxSpace: Int64, user: UserManager) {
        let maxSpace : Double = Double(maxSpace)
        let usedSpace : Double = Double(usedSpace)
        let usedPercentage = usedSpace / maxSpace
        let threshold = Constants.App.SpaceWarningThresholdDouble / 100.0

        let isSpaceDisable = userCachedStatus.getIsCheckSpaceDisabledStatus(by: user.userInfo.userId) ?? false
        if isSpaceDisable {
            if usedSpace > maxSpace {
                self.showUpgradeAlert()
            }
            return
        }

        if maxSpace == 0 || usedPercentage < threshold {
            return
        }
        
        let formattedMaxSpace : String = ByteCountFormatter.string(fromByteCount: Int64(maxSpace), countStyle: ByteCountFormatter.CountStyle.binary)
        var message = ""
        
        if usedSpace >= maxSpace {
            let localized = LocalString._space_all_used_warning
            message = String(format: localized, formattedMaxSpace)
        } else {
            let percentageStr = Int(String(format: "%.0f", (usedPercentage * 100.0))) ?? 90
            message = String(format: LocalString._space_partial_used_warning, percentageStr, formattedMaxSpace);
        }
        
        let alertController = UIAlertController(title: LocalString._space_warning,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addOKAction()
        alertController.addAction(UIAlertAction(title: LocalString._hide, style: .destructive, handler: { action in
            userCachedStatus.setIsCheckSpaceDisabledStatus(uid: user.userInfo.userId, value: true)
        }))
        userCachedStatus.showStorageOverAlert()
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }

    private func showUpgradeAlert() {
        guard !userCachedStatus.hasShownStorageOverAlert else { return }
        userCachedStatus.showStorageOverAlert()
        let alert = UIAlertController(title: LocalString._storage_full,
                                      message: LocalString._upgrade_suggestion,
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: LocalString._general_ok_action, style: .default) { _ in
            let link = DeepLink(.toSubscriptionPage)
            NotificationCenter.default.post(name: .switchView, object: link)
        }
        let laterAction = UIAlertAction(title: LocalString._general_later_action, style: .default, handler: nil)
        [laterAction, okAction].forEach(alert.addAction)
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
