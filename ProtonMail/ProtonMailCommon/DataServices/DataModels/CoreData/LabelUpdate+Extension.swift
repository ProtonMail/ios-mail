//
//  Contact.swift
//  ProtonMail
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
import CoreData

extension LabelUpdate {
    struct Attributes {
        static let entityName = "LabelUpdate"
        static let userID = "userID"
        static let labelID = "labelID"
    }
    
    class func lastUpdate(by labelID: String, userID: String,  inManagedObjectContext context: NSManagedObjectContext) -> LabelUpdate? {
        return context.managedObjectWithEntityName(Attributes.entityName, matching: [Attributes.labelID : labelID, Attributes.userID : userID]) as? LabelUpdate
    }
    
    
    class func newLabelUpdate(by labelID: String, userID: String, inManagedObjectContext context: NSManagedObjectContext) -> LabelUpdate {
        let update = LabelUpdate(context: context)
        update.start = Date.distantPast
        update.end = Date.distantPast
        update.update = Date.distantPast
        
        update.labelID = labelID
        update.userID = userID
        
        update.total = 0
        update.unread = 0
        
        if let error = update.managedObjectContext?.saveUpstreamIfNeeded() {
             PMLog.D("error: \(error)")
         }
         return update
    }
    
    class func remove(by userID: String, inManagedObjectContext context: NSManagedObjectContext) -> Bool {
        if let toDeletes = context.managedObjectsWithEntityName(Attributes.entityName,
                                                                matching: [Attributes.userID : userID]) as? [LabelUpdate] {
            for update in toDeletes {
                context.delete(update)
            }
            if let error = context.saveUpstreamIfNeeded() {
                PMLog.D(" error: \(error)")
            } else {
                return true
            }
        }
        return false
    }
    
}
