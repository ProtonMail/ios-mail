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

protocol LocalNotificationHandler {
    func scheduleMessageSendingFailedNotification(_ details: LocalNotificationService.MessageSendingDetails)
    func unscheduleMessageSendingFailedNotification(_ details: LocalNotificationService.MessageSendingDetails)
    func rescheduleMessage(oldID: String,
                           details: LocalNotificationService.MessageSendingDetails,
                           completion: (() -> Void)?)
    func showSessionRevokeNotification(email: String)
}

protocol NotificationHandler {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void)
    func getDeliveredNotifications(completionHandler: @escaping ([UNNotification]) -> Void)
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: NotificationHandler {}

class LocalNotificationService: LocalNotificationHandler, Service {
    enum Categories: String {
        case failedToSend = "LocalNotificationService.Categories.failedToSend"
        case sessionRevoked = "LocalNotificationService.Categories.sessionRevoked"
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
    let notificationHandler: NotificationHandler

    init(userID: String, notificationHandler: NotificationHandler = UNUserNotificationCenter.current()) {
        self.userID = userID
        self.notificationHandler = notificationHandler
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

        notificationHandler.add(request, withCompletionHandler: nil)
    }

    func unscheduleMessageSendingFailedNotification(_ details: MessageSendingDetails) {
        notificationHandler.removePendingNotificationRequests(withIdentifiers: [details.messageID])
    }

    func rescheduleMessage(oldID: String, details: MessageSendingDetails, completion: (() -> Void)? = nil) {
        notificationHandler.getPendingNotificationRequests { [weak self] requests in
            guard requests.contains(where: { $0.identifier == oldID }) else { return }
            self?.unscheduleMessageSendingFailedNotification(.init(messageID: oldID))
            self?.scheduleMessageSendingFailedNotification(details)
            completion?()
        }
    }

    func showSessionRevokeNotification(email: String) {
        let content = UNMutableNotificationContent()
        content.title = String(format: LocalString._token_revoke_noti_title, email)
        content.body = LocalString._token_revoke_noti_body
        content.userInfo = ["category": Categories.sessionRevoked.rawValue]

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        notificationHandler.add(request, withCompletionHandler: nil)
    }

    func cleanUp(completion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        group.enter()
        notificationHandler.getPendingNotificationRequests { all in
            let belongToUser = all.filter { $0.content.userInfo["user_id"] as? String == self.userID }
                .map { $0.identifier }
            self.notificationHandler.removePendingNotificationRequests(withIdentifiers: belongToUser)
            group.leave()
        }
        group.enter()
        notificationHandler.getDeliveredNotifications { all in
            let belongToUser = all.filter { $0.request.content.userInfo["user_id"] as? String == self.userID }
                .map { $0.request.identifier }
            self.notificationHandler.removeDeliveredNotifications(withIdentifiers: belongToUser)
            group.leave()
        }
        group.notify(queue: .main) {
            completion?()
        }
    }

    static func cleanUpAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
