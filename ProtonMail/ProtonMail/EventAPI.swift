//
//  EventAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/26/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


    
// MARK : Get messages part
final class EventCheckRequest<T : ApiResponse> : ApiRequest<T>{
    let eventID : String
    
    init(eventID : String) {
        self.eventID = eventID
    }
    
    override open func getRequestPath() -> String {
        return EventAPI.Path + "/\(self.eventID)" + AppConstants.getDebugOption
    }
    
    override open func getVersion() -> Int {
        return EventAPI.V_EventCheckRequest
    }
}


final class EventLatestIDRequest<T : ApiResponse> : ApiRequest<T>{

    override open func getRequestPath() -> String {
        return EventAPI.Path + "/latest" + AppConstants.getDebugOption
    }
    
    override open func getVersion() -> Int {
        return EventAPI.V_LatestEventRequest
    }
}

final class EventLatestIDResponse : ApiResponse {
    var eventID : String = ""

    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {
        
        PMLog.D(response.JSONStringify(true))
        self.eventID = response["EventID"] as? String ?? ""

        return true
    }
}

final class EventCheckResponse : ApiResponse {
    var eventID : String = ""
    var isRefresh : Bool = false
    
    var messages : [Dictionary<String, Any>]?
    var contacts : [Dictionary<String, Any>]?
    var userinfo : Dictionary<String, Any>?
    var unreads : Dictionary<String, Any>?
    var total : Dictionary<String, Any>?
    var labels : [Dictionary<String, Any>]?
    var usedSpace : String?
    var notices : [String]?
    var messageCounts: [Dictionary<String, Any>]?
    
    override func ParseResponse(_ response: Dictionary<String, Any>!) -> Bool {

        //PMLog.D(response.JSONStringify(prettyPrinted: true))
        
        self.eventID = response["EventID"] as? String ?? ""
        self.messages =  response["Messages"] as? [Dictionary<String, Any>]
        
        self.isRefresh = response["Refresh"] as? Bool ?? false
        
        self.userinfo = response["User"] as? Dictionary<String, Any>
        
        self.unreads = response["Unread"] as? Dictionary<String, Any>

        self.usedSpace = response["UsedSpace"] as? String
        
        self.total = response["Total"] as? Dictionary<String, Any>
        
        self.labels =  response["Labels"] as? [Dictionary<String, Any>]
        
        self.contacts = response["Contacts"] as? [Dictionary<String, Any>]
        
        self.notices = response["Notices"] as? [String]
        
        self.messageCounts = response["MessageCounts"] as? [Dictionary<String, Any>]
        
        return true
    }
}

open class MessageEvent {
    
    var Action : Int!
    var ID : String!;
    var message : Dictionary<String, Any>?
    
    init(event: Dictionary<String, Any>!) {
        self.Action = event["Action"] as! Int
        self.message =  event["Message"] as? Dictionary<String, Any>
        self.ID =  event["ID"] as! String
        self.message?["ID"] = self.ID
        self.message?["needsUpdate"] = false
    }
}

open class ContactEvent {
    
    var Action : Int!
    var ID : String!;
    var contact : Dictionary<String, Any>?
    
    init(event: Dictionary<String, Any>!) {
        self.Action = event["Action"] as! Int
        self.contact =  event["Contact"] as? Dictionary<String, Any>
        self.ID =  event["ID"] as! String
    }
}

open class LabelEvent {
    
    var Action : Int!
    var ID : String!;
    var label : Dictionary<String, Any>?
    
    init(event: Dictionary<String, Any>!) {
        self.Action = event["Action"] as! Int
        self.label =  event["Label"] as? Dictionary<String, Any>
        self.ID =  event["ID"] as! String
    }
}



