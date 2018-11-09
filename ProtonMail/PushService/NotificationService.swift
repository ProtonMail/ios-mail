//
//  NotificationService.swift
//  PushServiceDev
//
//  Created by Yanfeng Zhang on 11/14/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import UserNotifications
import Crypto

@available(iOSApplicationExtension 10.0, *)
class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        guard let bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) else {
            contentHandler(request.content)
            return
        }
        
        bestAttemptContent.title = "You received a new message!"
        
        guard let UID = bestAttemptContent.userInfo["UID"] as? String else {
            bestAttemptContent.body = "without UID"
            contentHandler(bestAttemptContent)
            return
        }
        
        guard let encryptionKit = PushNotificationDecryptor.encryptionKit(forSession: UID) else {
            PushNotificationDecryptor.markForUnsubscribing(uid: UID)
            bestAttemptContent.body = "no encryption kit for UID"
            contentHandler(bestAttemptContent)
            return
        }

        guard let encrypted = bestAttemptContent.userInfo["encryptedMessage"] as? String else {
            bestAttemptContent.body = "no encrypted message in push"
            contentHandler(bestAttemptContent)
            return
        }
        
        do {
            let plaintext = try sharedOpenPGP.decryptMessage(encrypted,
                                                             privateKey: encryptionKit.privateKey,
                                                             passphrase: encryptionKit.passphrase)
            
            guard let push = PushData.parse(with: plaintext) else {
                bestAttemptContent.body = "failed to decrypt"
                contentHandler(bestAttemptContent)
                return
            }
            
            if let body = push.body {
                bestAttemptContent.title = ""
                bestAttemptContent.body = body
            }
            
            if let badge = push.badge, badge.intValue > 0 {
                bestAttemptContent.badge = badge
            }
        } catch let error {
            bestAttemptContent.body = "error: \(error.localizedDescription)"
        }
        
        contentHandler(bestAttemptContent)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}
