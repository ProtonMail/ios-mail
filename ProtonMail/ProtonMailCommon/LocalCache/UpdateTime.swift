//
//  LastUpdatedStore.swift
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



import Foundation

//TODO:: move this to core data => Labels
final class UpdateTime : NSObject {
    var start : Date
    var end : Date
    var update : Date
    var total : Int32
    var unread : Int32
    
    required init (start: Date!, end : Date, update : Date, total : Int32, unread: Int32){
        self.start = start
        self.end = end
        self.update = update
        self.unread = unread
        self.total = total
    }
    
    var isNew : Bool {
        get{
            return  self.start == self.end && self.start == self.update
        }
    }
    
    static func distantPast() -> UpdateTime {
        return UpdateTime(start: Date.distantPast , end: Date.distantPast , update: Date.distantPast , total: 0, unread: 0)
    }
}

extension UpdateTime : NSCoding {
    
    fileprivate struct CoderKey {
        static let startCode = "start"
        static let endCode = "end"
        static let updateCode = "update"
        static let unread = "unread"
        static let total = "total"
    }
    
    convenience init(coder aDecoder: NSCoder) {
        self.init(
            start: aDecoder.decodeObject(forKey: CoderKey.startCode) as! Date,
            end: aDecoder.decodeObject(forKey: CoderKey.endCode) as! Date,
            update: aDecoder.decodeObject(forKey: CoderKey.updateCode) as! Date,
            total: aDecoder.decodeInt32(forKey: CoderKey.total),
            unread: aDecoder.decodeInt32(forKey: CoderKey.unread))
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.start, forKey: CoderKey.startCode)
        aCoder.encode(self.end, forKey: CoderKey.endCode)
        aCoder.encode(self.update, forKey: CoderKey.updateCode)
        aCoder.encode(self.total, forKey: CoderKey.total)
        aCoder.encode(self.unread, forKey: CoderKey.unread)
    }
}



