//
//  NotificationService.swift
//  PushServiceDev
//
//  Created by Yanfeng Zhang on 11/14/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import UserNotifications

@available(iOSApplicationExtension 10.0, *)
class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"
            
            bestAttemptContent.badge = 100
            bestAttemptContent.sound = UNNotificationSound.default()
            bestAttemptContent.subtitle = "Subtitle test! " + " [modified]"
            bestAttemptContent.body = "Give it back if you finished you tests! [modified]"
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
