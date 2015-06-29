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
    let eventID : String = ""
}

