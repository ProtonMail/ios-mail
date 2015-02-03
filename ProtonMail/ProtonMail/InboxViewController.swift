//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import CoreData
import UIKit

class InboxViewController: MailBoxViewController {
 
    override func loadView() {
        self.title = NSLocalizedString("INBOX")
        super.loadView()
    }
    
    override func retrieveMessagesFromServer() -> [EmailThread] {
        println("Retrieving Inbox")
//        sharedMessageDataService.fetchMessagesForLocation(.inbox) { error in
//            if let error = error {
//                NSLog("error: \(error)")
//            }
//            self.refreshControl.endRefreshing()
//        }
        return EmailService.retrieveInboxMessages()
    }
}