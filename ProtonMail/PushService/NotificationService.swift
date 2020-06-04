//
//  NotificationService.swift
//  PushService - Created on 11/14/17.
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


import UserNotifications

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
        bestAttemptContent.body = "You received a new message!"
        bestAttemptContent.sound = UNNotificationSound.default
        #if Enterprise
        bestAttemptContent.title = "You received a new message!"
        #endif

        guard let UID = bestAttemptContent.userInfo["UID"] as? String else {
            #if Enterprise
            bestAttemptContent.body = "without UID"
            #endif
            contentHandler(bestAttemptContent)
            return
        }
        
        bestAttemptContent.threadIdentifier = UID
        
        userCachedStatus.hasMessageFromNotification = true
        
        guard let encryptionKit = PushNotificationDecryptor.encryptionKit(forSession: UID) else {
            PushNotificationDecryptor.markForUnsubscribing(uid: UID)
            #if Enterprise
            bestAttemptContent.body = "no encryption kit for UID"
            #endif
            contentHandler(bestAttemptContent)
            return
        }

        guard let encrypted = bestAttemptContent.userInfo["encryptedMessage"] as? String else {
            #if Enterprise
            bestAttemptContent.body = "no encrypted message in push"
            #endif
            contentHandler(bestAttemptContent)
            return
        }
        
        do {
            
            let plaintext = try Crypto().decrypt(encrytped: encrypted,
                                                 privateKey: encryptionKit.privateKey,
                                                 passphrase: encryptionKit.passphrase)
            
            guard let push = PushData.parse(with: plaintext) else {
                #if Enterprise
                bestAttemptContent.body = "failed to decrypt"
                #endif
                contentHandler(bestAttemptContent)
                return
            }
            
            bestAttemptContent.title = push.sender.name.isEmpty ? push.sender.address : push.sender.name
            bestAttemptContent.body = push.body
            
            if push.badge > 0 && userCachedStatus.primaryUserSessionId == UID {
                bestAttemptContent.badge = NSNumber(value: push.badge)
            } else {
                bestAttemptContent.badge = nil
            }
        } catch let error {
            #if Enterprise
            bestAttemptContent.body = "error: \(error.localizedDescription)"
            #endif
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

protocol CacheStatusInject {
    var isPinCodeEnabled : Bool { get }
    var isTouchIDEnabled : Bool { get }
    var pinFailedCount : Int { get set }
}
