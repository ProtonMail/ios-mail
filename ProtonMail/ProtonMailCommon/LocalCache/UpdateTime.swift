//
//  LastUpdatedStore.swift
//  ProtonMail
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


import Foundation

////TODO:: move this to core data => Labels
//final class UpdateTime : NSObject {
//    var start : Date
//    var end : Date
//    var update : Date
//    var total : Int32
//    var unread : Int32
//
//    required init (start: Date, end : Date, update : Date, total : Int32, unread: Int32) {
//        self.start = start
//        self.end = end
//        self.update = update
//        self.unread = unread
//        self.total = total
//    }
//
//    var isNew : Bool {
//        get{
//            return  self.start == self.end && self.start == self.update
//        }
//    }
//
//    static func distantPast() -> UpdateTime {
//        return UpdateTime(start: Date.distantPast , end: Date.distantPast , update: Date.distantPast , total: 0, unread: 0)
//    }
//}
//
//extension UpdateTime : NSCoding {
//
//    fileprivate struct CoderKey {
//        static let startCode = "start"
//        static let endCode = "end"
//        static let updateCode = "update"
//        static let unread = "unread"
//        static let total = "total"
//    }
//
//    // TODO:: fix the hard convert
//    convenience init(coder aDecoder: NSCoder) {
//        self.init(
//            start: aDecoder.decodeObject(forKey: CoderKey.startCode) as! Date,
//            end: aDecoder.decodeObject(forKey: CoderKey.endCode) as! Date,
//            update: aDecoder.decodeObject(forKey: CoderKey.updateCode) as! Date,
//            total: aDecoder.decodeInt32(forKey: CoderKey.total),
//            unread: aDecoder.decodeInt32(forKey: CoderKey.unread))
//    }
//
//    func encode(with aCoder: NSCoder) {
//        aCoder.encode(self.start, forKey: CoderKey.startCode)
//        aCoder.encode(self.end, forKey: CoderKey.endCode)
//        aCoder.encode(self.update, forKey: CoderKey.updateCode)
//        aCoder.encode(self.total, forKey: CoderKey.total)
//        aCoder.encode(self.unread, forKey: CoderKey.unread)
//    }
//}



