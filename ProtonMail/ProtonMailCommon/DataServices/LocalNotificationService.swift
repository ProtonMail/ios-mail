//
//  LocalNotificationService.swift
//  ProtonMail - Created on 02/08/2019.
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
import UserNotifications
import PromiseKit

class LocalNotificationService: Service, HasLocalStorage {
    enum Categories: String {
        case failedToSend = "LocalNotificationService.Categories.failedToSend"
    }
    struct MessageSendingDetails {
        var messageID: String
        var error: String = LocalString._message_not_sent_message
        var timeInterval: TimeInterval = 3 * 60
        var subtitle: String
        
        init(messageID: String, subtitle: String = "") {
            self.messageID = messageID
            self.subtitle = subtitle
        }
        init(messageID: String, error: String, timeInterval: TimeInterval, subtitle: String) {
            self.messageID = messageID
            self.error = error
            self.timeInterval = timeInterval
            self.subtitle = subtitle
        }
    }
    
    private var userID: String
    init(userID: String) {
        self.userID = userID
    }
    
    func scheduleMessageSendingFailedNotification(_ details: MessageSendingDetails) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ " + LocalString._message_not_sent_title
        content.subtitle = details.subtitle
        content.body = details.error
        content.categoryIdentifier = Categories.failedToSend.rawValue
        content.userInfo = ["message_id": details.messageID,
                            "category": Categories.failedToSend.rawValue]
        
        let timeout = UNTimeIntervalNotificationTrigger(timeInterval: details.timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: details.messageID, content: content, trigger: timeout)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func unscheduleMessageSendingFailedNotification(_ details: MessageSendingDetails) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [details.messageID])
    }
    
    func rescheduleMessage(oldID: String, details: MessageSendingDetails) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { [weak self](requests) in
            guard let _ = requests.first(where: {$0.identifier == oldID}) else {return}
            self?.unscheduleMessageSendingFailedNotification(.init(messageID: oldID))
            self?.scheduleMessageSendingFailedNotification(details)
        }
    }
    
    func cleanUp() -> Promise<Void> {
        return Promise { seal in
            let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests { all in
                let belongToUser = all.filter { $0.content.userInfo["user_id"] as? String == self.userID }.map { $0.identifier }
                center.removePendingNotificationRequests(withIdentifiers: belongToUser)
            }
            center.getDeliveredNotifications() { all in
                let belongToUser = all.filter { $0.request.content.userInfo["user_id"] as? String == self.userID }.map { $0.request.identifier }
                center.removeDeliveredNotifications(withIdentifiers: belongToUser)
            }
            seal.fulfill_()
        }
    }
    
    static func cleanUpAll() -> Promise<Void> {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        return Promise()
    }
}
