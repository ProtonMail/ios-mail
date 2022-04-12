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
    
    func calculateSpaceUsedPercentage(usedSpace: Int64,
                                      maxSpace: Int64) -> Double {
        let maxSpace: Double = Double(maxSpace)
        let usedSpace: Double = Double(usedSpace)
        return usedSpace / maxSpace
    }
    
    func calculateIsUsedSpaceExceedThreshold(usedPercentage: Double,
                                             threshold: Double) -> Bool {
        let thresholdInPercent = threshold / 100.0
        return usedPercentage > thresholdInPercent
    }
    
    func calculateFormattedMaxSpace(maxSpace: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: maxSpace, countStyle: ByteCountFormatter.CountStyle.binary)
    }
    
    func calculateSpaceMessage(usedSpace: Double,
                               maxSpace: Double,
                               formattedMaxSpace: String,
                               usedSpacePercentage: Double) -> String {
        if usedSpace >= maxSpace {
            let localized = LocalString._space_all_used_warning
            return String(format: localized, formattedMaxSpace)
        } else {
            let percentageStr = Int(String(format: "%.0f", (usedSpacePercentage * 100.0))) ?? 90
            return String(format: LocalString._space_partial_used_warning, percentageStr, formattedMaxSpace);
        }
    }
    
    func checkSpace(_ usedSpace: Int64, maxSpace: Int64, userID: String) {
        let usedPercentage = calculateSpaceUsedPercentage(usedSpace: usedSpace,
                                                          maxSpace: maxSpace)
        let isExceed = calculateIsUsedSpaceExceedThreshold(usedPercentage: usedPercentage,
                                                           threshold: Constants.App.SpaceWarningThresholdDouble)

        let isSpaceDisable = userCachedStatus.getIsCheckSpaceDisabledStatus(by: userID) ?? false
        if isSpaceDisable {
            if usedSpace > maxSpace {
                self.showUpgradeAlert()
            }
            return
        }

        if maxSpace == 0 || !isExceed {
            return
        }
        
        let formattedMaxSpace = calculateFormattedMaxSpace(maxSpace: maxSpace)
        let message = calculateSpaceMessage(usedSpace: Double(usedSpace),
                                            maxSpace: Double(maxSpace),
                                            formattedMaxSpace: formattedMaxSpace,
                                            usedSpacePercentage: usedPercentage)
        
        let alertController = UIAlertController(title: LocalString._space_warning,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addOKAction()
        alertController.addAction(UIAlertAction(title: LocalString._hide, style: .destructive, handler: { action in
            userCachedStatus.setIsCheckSpaceDisabledStatus(uid: userID, value: true)
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
