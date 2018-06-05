//
//  NotificationService.swift
//  PushServiceDev
//
//  Created by Yanfeng Zhang on 11/14/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import UserNotifications

var sharedUserDataService : UserDataService!

@available(iOSApplicationExtension 10.0, *)
class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            sharedUserDataService = UserDataService(check: false)
            if sharedUserDataService.isUserCredentialStored {
                if let encrypted = bestAttemptContent.userInfo["encryptedMessage"] as? String {
                    bestAttemptContent.body = encrypted
                    if let userkey = sharedUserDataService.userInfo?.firstUserKey(), let password = sharedUserDataService.mailboxPassword {
                        do {
                            let plaintext = try sharedOpenPGP.decryptMessage(encrypted,
                                                                             privateKey: userkey.private_key,
                                                                             passphrase: password)
                            if let push = PushData.parse(with: plaintext) {
                                bestAttemptContent.title = push.title // "\(bestAttemptContent.title) [modified]"
                                if let _ = push.sound {
                                    //right now it is a integer should be sound name put default for now
                                }
                                bestAttemptContent.sound = UNNotificationSound.default()
                                if let sub = push.subTitle {
                                    bestAttemptContent.subtitle = sub
                                }
                                
                                if let body = push.body {
                                    bestAttemptContent.body = body
                                }
                                
                                if let badge = push.badge, badge.intValue > 0 {
                                    bestAttemptContent.badge = badge
                                }
                            }
                        } catch let error {
                            PMLog.D(error.localizedDescription)
                        }
                    }
                }
            }
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
