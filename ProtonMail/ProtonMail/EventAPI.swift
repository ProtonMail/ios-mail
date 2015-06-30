//
//  EventAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/26/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


    
// MARK : Get messages part
public class EventCheckRequest<T : ApiResponse> : ApiRequest<T>{
    let eventID : String!
    
    init(eventID : String) {
        self.eventID = eventID
    }
    
    override public func getRequestPath() -> String {
        return EventAPI.Path.stringByAppendingPathComponent(self.eventID) + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return EventAPI.V_EventCheckRequest
    }
    
}

public class EventCheckResponse : ApiResponse {
    var eventID : String = ""
    var isRefresh : Bool = false
    
    var messages : [Dictionary<String,AnyObject>]?
    var contacts : [Dictionary<String,AnyObject>]?
    var unreads : Dictionary<String,AnyObject>?
    var usedSpace : String?
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        
        self.eventID = response["EventID"] as! String
        self.messages =  response["Messages"] as? [Dictionary<String,AnyObject>]
        
        self.isRefresh = response["Refresh"] as! Bool
        
        self.unreads = response["Unread"] as? Dictionary<String,AnyObject>

        self.usedSpace = response["UsedSpace"] as? String
        
        return true
    }
}


public class MessageEvent {
    
    var Action : Int!
    var ID : String!;
    var message : Dictionary<String,AnyObject>?
    
    init(event: Dictionary<String,AnyObject>!) {
        self.Action = event["Action"] as! Int
        self.message =  event["Message"] as? Dictionary<String,AnyObject>
        self.ID =  event["ID"] as! String
        self.message?["ID"] = self.ID
    }
}



