//
//  APIServiceRequest.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation





public struct MessageAPI {
    /// base message api path
    static let Path :String       = "/messages"
    
    
    /// fetch message request version
    static let V_MessageFetchRequest : Int      = 1
    
    static let V_MessageDraftRequest : Int = 1
    
    static let V_MessageUpdateDraftRequest : Int = 1
    
    
    static let V_MessageActionRequest : Int = 1
    
    static let V_MessageSendRequest : Int = 1
    
}

public struct SettingsAPI {
    /// base message api path
    static let Path :String       = "/settings"
    
    
    /// fetch message request version
    static let V_SettingsUpdateDomainRequest : Int      = 1
    

    
}


public struct EventAPI {
    /// base message api path
    public static let Path :String       = "/events"
    
    
    
    /// current event api version
    public static let V_EventCheckRequest : Int      = 1
    public static let V_LatestEventRequest : Int      = 1

}