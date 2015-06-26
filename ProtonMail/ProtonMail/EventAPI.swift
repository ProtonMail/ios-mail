//
//  EventAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/26/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

/// Message api request class
public class EventAPI {
    
    /// current message api version
    private static let EventAPIVersion : Int      = 1
    /// base message api path
    private static let EventAPIPath :String       = "/events"
    
    // MARK : Get messages part
    public class EventCheckRequest : ApiRequest {
        let location : MessageLocation!
        let startTime : Int?
        let endTime : Int
        
        init(location:MessageLocation, endTime : Int = 0) {
            self.location = location
            self.endTime = endTime
            self.startTime = 0
            
        }
        
        public override func toDictionary() -> Dictionary<String,AnyObject> {
            var out : [String : AnyObject] = [
                "Location" : self.location.rawValue,
                "Sort" : "Time"]
            
            if(self.endTime != 0)
            {
                let newTime = self.endTime - 1
                out["End"] = newTime
            }
            
            PMLog.D(self.JSONStringify(out, prettyPrinted: true))
            return out
        }
        
        override public func getRequestPath() -> String {
            return EventAPI.EventAPIPath + AppConstants.getDebugOption
        }
        
        override public func getVersion() -> Int {
            return EventAPI.EventAPIVersion
        }
    }
}