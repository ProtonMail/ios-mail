//
//  PersistentQueue.swift
//  ProtonMail
//
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

import Foundation

class PersistentQueue {
    
    struct Key {
        static let elementID = "elementID"
        static let object = "object"
    }
    
    private var queue: [AnyObject] {
        didSet {
            PMLog.D(" Queue: \(queueName) count: \(queue.count)")
            dispatch_sync(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) { () -> Void in
                let data = NSKeyedArchiver.archivedDataWithRootObject(self.queue)
                if !data.writeToURL(self.queueURL, atomically: true) {
                    PMLog.D("Unable to save queue: \(self.queue as NSArray)\n to \(self.queueURL.absoluteString)")
                } else {
                    self.queueURL.excludeFromBackup()
                }
            }
        }
    }
    private let queueURL: NSURL
    let queueName: String
    
    /// Number of objects in the Queue
    var count: Int {
        return self.queue.count
    }
    
    func getQueue() -> [AnyObject]
    {
        return self.queue
    }
    
    init(queueName: String) {
        self.queueName = "\(QueueConstant.queueIdentifer).\(queueName)"
        //PMLog.D(self.queueName)
        self.queueURL = NSFileManager.defaultManager().applicationSupportDirectoryURL.URLByAppendingPathComponent(self.queueName)
        //PMLog.D(self.queueURL)
        if let data = NSData(contentsOfURL: queueURL) {
            self.queue = (NSKeyedUnarchiver.unarchiveObjectWithData(data) ?? []) as! [AnyObject]
        }
        else {
            self.queue = []
        }
        //PMLog.D(self.queue)
    }
    
    func add (uuid: NSUUID, object: NSCoding) -> NSUUID {
        let element = [Key.elementID : uuid, Key.object : object]
        PMLog.D(element)
        self.queue.append(element)
        return uuid
    }
    
    /// Adds an object to the persistent queue.
    func add(object: NSCoding) -> NSUUID {
        let uuid = NSUUID()
        return self.add(uuid, object: object)
    }
    
    /// Clears the persistent queue.
    func clear() {
        queue.removeAll()
    }
    
    /// Returns the next item in the persistent queue or nil, if the queue is empty.
    func next() -> (elementID: NSUUID, object: AnyObject)? {
        if let element = queue.first as? [String : AnyObject] {
            return (element[Key.elementID] as! NSUUID, element[Key.object]!)
        }
        return nil
    }
    
    /// Removes an element from the persistent queue
    func remove(elementID elementID: NSUUID) -> Bool {
        PMLog.D(elementID)
        for (index, element) in queue.enumerate() {
            PMLog.D(element)
            if let elementDict = element as? [String : AnyObject], kID = elementDict[Key.elementID] as? NSUUID{
                if kID == elementID {
                    queue.removeAtIndex(index)
                    return true
                }
            }
        }
        return false
    }
}
