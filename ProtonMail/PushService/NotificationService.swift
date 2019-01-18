//
//  NotificationService.swift
//  PushService - Created on 11/14/17.
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
        bestAttemptContent.body = "You received a new message!"
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
            let plaintext = try sharedOpenPGP.decryptMessage(encrypted,
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
            
            if push.badge > 0 {
                bestAttemptContent.badge = NSNumber(value: push.badge)
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
