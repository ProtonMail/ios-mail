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
    static let Path :String = AppConstants.BaseAPIPath + "/messages"
    
    
    /// fetch message request version
    static let V_MessageFetchRequest : Int = 1
    
    static let V_MessageDraftRequest : Int = 1
    
    static let V_MessageUpdateDraftRequest : Int = 1
    
    static let V_MessageActionRequest : Int = 1
    
    static let V_MessageEmptyRequest : Int = 1
    
    static let V_MessageSendRequest : Int = 1
    
}

public struct AttachmentAPI {
    /// base message api path
    static let Path :String = AppConstants.BaseAPIPath + "/attachments"
    
    
    /// fetch message request version
    static let V_AttachmentRemoveRequest : Int = 1

    
}

public struct LabelAPI {
    static let Path :String = AppConstants.BaseAPIPath + "/labels"
    
    //
    static let V_LabelFetchRequest : Int = 1
    static let V_ApplyLabelToMessageRequest : Int = 1
    static let V_RemoveLabelFromMessageRequest : Int = 1
}

public struct AuthAPI {
    /// base message api path
    static let Path :String = AppConstants.BaseAPIPath + "/auth"
    
    /// fetch message request version
    static let V_AuthRequest : Int = 1
}


public struct SettingsAPI {
    /// base message api path
    static let Path :String = AppConstants.BaseAPIPath + "/settings"
    
    /// fetch message request version
    static let V_SettingsUpdateDomainRequest : Int = 1
    static let V_SettingsUpdateNotifyRequest : Int = 1
    
    static let V_SettingsUpdateSwipeLeftRequest : Int = 1
    static let V_SettingsUpdateSwipeRightRequest : Int = 1
}


public struct EventAPI {
    /// base event api path
    public static let Path :String = AppConstants.BaseAPIPath + "/events"
    
    /// current event api version
    public static let V_EventCheckRequest : Int = 1
    public static let V_LatestEventRequest : Int = 1

}


public struct BugsAPI {
    static let Path :String = AppConstants.BaseAPIPath + "/bugs"
    
    static let V_BugsReportRequest : Int = 1
}
