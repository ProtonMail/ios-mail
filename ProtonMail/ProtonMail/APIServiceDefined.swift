//
//  APIServiceRequest.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


struct MessageAPI {
    
    /// base message api path
    static let Path :String = AppConstants.API_PATH + "/messages"
    
    
    /// fetch message request version
    static let V_MessageFetchRequest : Int = 1
    
    static let V_MessageDraftRequest : Int = 1
    
    static let V_MessageUpdateDraftRequest : Int = 1
    
    static let V_MessageActionRequest : Int = 1
    
    static let V_MessageEmptyRequest : Int = 1
    
    static let V_MessageSendRequest : Int = 1
    
}

struct AttachmentAPI {
    /// base message api path
    static let Path :String = AppConstants.API_PATH + "/attachments"
    
    
    /// fetch message request version
    static let V_AttachmentRemoveRequest : Int = 1

    
}

struct LabelAPI {
    static let Path :String = AppConstants.API_PATH + "/labels"
    
    //
    static let V_LabelFetchRequest : Int = 1
    static let V_ApplyLabelToMessageRequest : Int = 1
    static let V_RemoveLabelFromMessageRequest : Int = 1
    static let V_CreateLabelRequest : Int = 1
    static let V_UpdateLabelRequest : Int = 1
    static let V_DeleteLabelRequest : Int = 1
}

struct AuthAPI {
    /// base message api path
    static let Path :String = AppConstants.API_PATH + "/auth"
    
    /// fetch message request version
    static let V_AuthRequest : Int = 1
    
    
    static let V_AuthModulusRequest : Int = 1
}


struct SettingsAPI {
    /// base message api path
    static let Path :String = AppConstants.API_PATH + "/settings"
    
    /// fetch message request version
    static let V_SettingsUpdateDomainRequest : Int = 1
    static let V_SettingsUpdateNotifyRequest : Int = 1
    
    static let V_SettingsUpdateSwipeLeftRequest : Int = 1
    static let V_SettingsUpdateSwipeRightRequest : Int = 1
    
    static let V_SettingsUpdateNewsRequest : Int = 1
    static let V_SettingsUpdateDisplayNameRequest : Int = 1
    
    static let V_SettingsUpdateShowImagesRequest : Int = 1
    
    static let V_SettingsUpdateLoginPasswordRequest : Int = 1
}

struct AddressesAPI {
    /// base message api path
    static let Path :String = AppConstants.API_PATH + "/addresses"
    
    /// fetch message request version
    static let V_AddressesUpdateRequest : Int = 1
    
    static let V_AddressesSetupRequest : Int = 1
}

struct EventAPI {
    /// base event api path
    static let Path :String = AppConstants.API_PATH + "/events"
    
    /// current event api version
    static let V_EventCheckRequest : Int = 1
    static let V_LatestEventRequest : Int = 1

}


struct BugsAPI {
    static let Path :String = AppConstants.API_PATH + "/bugs"
    
    static let V_BugsReportRequest : Int = 1
}


struct UsersAPI {
    
    static let Path : String = AppConstants.API_PATH + "/users"
    
    static let V_CreateUsersRequest : Int = 1
    static let V_GetUserInfoRequest : Int = 1
    static let V_GetHumanRequest : Int = 1
    static let V_HumanCheckRequest : Int = 1
    static let V_CheckUserExistRequest : Int = 1
    static let V_SendVerificationCodeRequest : Int = 1
    static let V_DirectRequest : Int = 1
}

struct KeysAPI {
    static let Path : String = AppConstants.API_PATH + "/keys"
    
    //Update private keys only, use for mailbox password/single password updatesPUT
    static let V_UpdatePrivateKeyRequest : Int = 1
    static let V_KeysSeuptRequest : Int = 1
    static let V_GetKeysSaltsRequest : Int = 1
}

struct OrganizationsAPI {
    static let Path : String = AppConstants.API_PATH + "/organizations"
    
    static let V_GetOrgKeysRequest : Int = 1
}

struct DomainsAPI {
    
    static let Path : String = AppConstants.API_PATH + "/domains"
    
    static let V_AvailableDomainsRequest : Int = 1
}

struct DeviceAPI {
    
    static let Path : String = AppConstants.API_PATH + "/device"
    
    static let V_RegisterDeviceRequest : Int = 1
    static let V_UnRegisterDeviceRequest : Int = 1
}


