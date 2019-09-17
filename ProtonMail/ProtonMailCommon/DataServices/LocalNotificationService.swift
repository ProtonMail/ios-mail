//
//  LocalNotificationService.swift
//  ProtonMail - Created on 02/08/2019.
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
import UserNotifications

class LocalNotificationService: Service {
    enum Categories: String {
        case failedToSend = "LocalNotificationService.Categories.failedToSend"
    }
    struct MessageSendingDetails {
        var messageID: String
        var error: String = "⚠️" + LocalString._message_not_sent_message
        var timeInterval: TimeInterval = 3 * 60
        
        init(messageID: String) {
            self.messageID = messageID
        }
        init(messageID: String, error: String, timeInterval: TimeInterval) {
            self.messageID = messageID
            self.error = error
            self.timeInterval = timeInterval
        }
    }
    
    func scheduleMessageSendingFailedNotification(_ details: MessageSendingDetails) {
        let content = UNMutableNotificationContent()
        content.title = LocalString._message_not_sent_title
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
    
    func unscheduleAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
