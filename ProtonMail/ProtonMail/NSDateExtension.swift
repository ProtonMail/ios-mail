//
//  NSDateExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/30/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


extension NSDate {
    
    // you can create a read-only computed property to return just the nanoseconds as Int
    var nanosecond: Int { return NSCalendar.currentCalendar().components(.Nanosecond,  fromDate: self).nanosecond   }
    
    // or an extension function to format your date
    func formattedWith(format:String)-> String {
        let formatter = NSDateFormatter()
        //formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)  // you can set GMT time
        formatter.timeZone = NSTimeZone.localTimeZone()        // or as local time
        formatter.dateFormat = format
        return formatter.stringFromDate(self)
    }
    
}//Wed, Apr 29, 2015 at 2:13 PM

//NSDate().formattedWith("EEEE d MMMM yyyy")
//NSDate().nanosecond

 // [dateFormatter setDateFormat:@"' ('EEEE d MMMM yyyy')'"];