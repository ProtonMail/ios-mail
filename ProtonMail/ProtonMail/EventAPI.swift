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
        return EventAPI.Path + "/\(self.eventID)" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return EventAPI.V_EventCheckRequest
    }
}


public class EventLatestIDRequest<T : ApiResponse> : ApiRequest<T>{

    override public func getRequestPath() -> String {
        return EventAPI.Path + "/latest" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return EventAPI.V_LatestEventRequest
    }
}

public class EventLatestIDResponse : ApiResponse {
    var eventID : String = ""

    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        
        PMLog.D(response.JSONStringify(true))
        self.eventID = response["EventID"] as? String ?? ""

        return true
    }
}

public class EventCheckResponse : ApiResponse {
    var eventID : String = ""
    var isRefresh : Bool = false
    
    var messages : [Dictionary<String,AnyObject>]?
    var contacts : [Dictionary<String,AnyObject>]?
    var userinfo : Dictionary<String,AnyObject>?
    var unreads : Dictionary<String,AnyObject>?
    var total : Dictionary<String,AnyObject>?
    var labels : [Dictionary<String,AnyObject>]?
    var usedSpace : String?
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {

        //PMLog.D(response.JSONStringify(prettyPrinted: true))
        
        self.eventID = response["EventID"] as? String ?? ""
        self.messages =  response["Messages"] as? [Dictionary<String,AnyObject>]
        
        self.isRefresh = response["Refresh"] as! Bool
        
        self.userinfo = response["User"] as? Dictionary<String,AnyObject>
        
        self.unreads = response["Unread"] as? Dictionary<String,AnyObject>

        self.usedSpace = response["UsedSpace"] as? String
        
        self.total = response["Total"] as? Dictionary<String,AnyObject>
        
        self.labels =  response["Labels"] as? [Dictionary<String,AnyObject>]
        
        self.contacts = response["Contacts"] as? [Dictionary<String,AnyObject>]
        
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
        self.message?["needsUpdate"] = false
    }
}

public class ContactEvent {
    
    var Action : Int!
    var ID : String!;
    var contact : Dictionary<String,AnyObject>?
    
    init(event: Dictionary<String,AnyObject>!) {
        self.Action = event["Action"] as! Int
        self.contact =  event["Contact"] as? Dictionary<String,AnyObject>
        self.ID =  event["ID"] as! String
    }
}

public class LabelEvent {
    
    var Action : Int!
    var ID : String!;
    var label : Dictionary<String,AnyObject>?
    
    init(event: Dictionary<String,AnyObject>!) {
        self.Action = event["Action"] as! Int
        self.label =  event["Label"] as? Dictionary<String,AnyObject>
        self.ID =  event["ID"] as! String
    }
}



