//
//  NSDateExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/30/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


extension Date {
    
    // you can create a read-only computed property to return just the nanoseconds as Int
    public var nanosecond: Int { return (Calendar.current as NSCalendar).components(.nanosecond,  from: self).nanosecond!   }
    
    // or an extension function to format your date
    public func formattedWith(_ format:String)-> String {
        let formatter = DateFormatter()
        //formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)  // you can set GMT time
        formatter.timeZone = TimeZone.autoupdatingCurrent        // or as local time
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    public func string(format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
}
