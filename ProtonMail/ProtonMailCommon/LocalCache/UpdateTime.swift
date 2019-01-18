//
//  LastUpdatedStore.swift
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

//TODO:: move this to core data => Labels
final class UpdateTime : NSObject {
    var start : Date
    var end : Date
    var update : Date
    var total : Int32
    var unread : Int32
    
    required init (start: Date, end : Date, update : Date, total : Int32, unread: Int32) {
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
    
    // TODO:: fix the hard convert
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



