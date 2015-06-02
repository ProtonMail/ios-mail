//
//  QueueManager.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/1/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

let sharedQueue = QueueManager()

class QueueManager {

    
    //right not doing the sigal operation once, 
    // later doing the parallels requests
    
    // read queue not necessary
    var messageQueue : MessageQueue!
    var readQueue : [AnyObject]!
    var retryQueue : [AnyObject]!
    
    init() {
    }
    deinit{
    }
    
    
    func addQueue()
    {
        
    }
    
}