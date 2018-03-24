//
//  APIServiceRequest.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

//*******************************************************************************************
//ProtonMail API Doc : https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api.md
//*******************************************************************************************


//Addresses API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_addresses.md
struct AddressesAPI {
    /// base message api path
    static let path :String = AppConstants.API_PATH + "/addresses"
    
    //Create new address [POST /addresses] locked
    
    //Order Addresses [/addresses/order]
    static let v_update_order : Int = 3
    
    //Setup new non-subuser address [POST /addresses/setup]
    static let v_setup : Int = 3
    
    //Get Addresses [GET /addresses]
    static let v_get_addresses : Int = 3
    //Get Address [GET /addresses/{address_id}]
    
    //Update address [PUT]
    static let v_update_address : Int = 3
    
    
}


//Not impl yet, maybe use in the future
struct AdminAPI {
    //Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_admin.md
}

//Not impl yet, maybe use in the future
struct AdminVPNAPI {
    //Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_admin_vpn.md
}


//Attachment API
//Doc:https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_attachments.md
struct AttachmentAPI {
    /// base message api path
    static let Path :String = AppConstants.API_PATH + "/attachments"
    
    /// fetch message request version
    static let V_AttachmentRemoveRequest : Int = 1
    
}




//Message API
//Doc: V1 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_messages.md
//Doc: V3 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_messages_v3.md
struct MessageAPI {
    /// base message api path
    static let path :String = AppConstants.API_PATH + "/messages"
    
    /// fetch message request version
    static let V_MessageFetchRequest : Int = 1
    
    static let v_create_draft : Int = 3
    
    static let v_update_draft : Int = 3
    
    static let V_MessageActionRequest : Int = 1
    
    static let V_MessageEmptyRequest : Int = 1
    
    static let V_MessageSendRequest : Int = 1
}


struct LabelAPI {
    static let path :String = AppConstants.API_PATH + "/labels"
    
    //
    static let V_LabelFetchRequest : Int = 1
    static let V_ApplyLabelToMessageRequest : Int = 1
    static let V_RemoveLabelFromMessageRequest : Int = 1
    static let V_CreateLabelRequest : Int = 1
    static let V_UpdateLabelRequest : Int = 1
    static let V_DeleteLabelRequest : Int = 1
    
    //doesn't impl yet
    static let v_order_labels : Int = 3
}

struct AuthAPI {
    /// base message api path
    static let Path :String = AppConstants.API_PATH + "/auth"
    
    /// fetch message request version
    static let V_AuthRequest : Int = 1
    
    
    static let V_AuthModulusRequest : Int = 1
}


struct SettingsAPI {
    /// base settings api path
    static let path :String = AppConstants.API_PATH + "/settings"
    
    static let v_get_settings : Int = 3
    
    //static let V_SettingsUpdateDomainRequest : Int = 1 departured
    
    static let V_SettingsUpdateNotifyRequest : Int = 1
    
    static let V_SettingsUpdateSwipeLeftRequest : Int = 1
    static let V_SettingsUpdateSwipeRightRequest : Int = 1
    
    static let V_SettingsUpdateNewsRequest : Int = 1
    static let V_SettingsUpdateDisplayNameRequest : Int = 1
    
    static let V_SettingsUpdateShowImagesRequest : Int = 1
    
    static let V_SettingsUpdateLoginPasswordRequest : Int = 1
}


struct EventAPI {
    /// base event api path
    static let Path :String = AppConstants.API_PATH + "/events"
    
    /// current event api version
    static let V_EventCheckRequest : Int = 3
    static let V_LatestEventRequest : Int = 1

}


struct ReportsAPI {
    static let path :String = AppConstants.API_PATH + "/reports"

    static let v_reports_bug : Int = 3
}


struct UsersAPI {
    
    static let path : String = AppConstants.API_PATH + "/users"
    
    static let v_get_userinfo : Int = 3
    
    static let V_CreateUsersRequest : Int = 1
    static let V_GetHumanRequest : Int = 1
    static let V_HumanCheckRequest : Int = 1
    static let V_CheckUserExistRequest : Int = 1
    static let V_SendVerificationCodeRequest : Int = 1
    static let V_DirectRequest : Int = 1
    static let V_GetUserPublicKeysRequest : Int = 2
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

//Domains API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_domains.md
struct DomainsAPI {
    
    static let path : String = AppConstants.API_PATH + "/domains"
    
    //Get all domains for this user's organization and check their DNS's [GET]
    
    //Get a specific domains and its check DNS [GET]
    
    //Get Available Domains [GET /domains/available]
    static let v_available_domains : Int = 3
    
    //Get Premium Domains [GET /domains/premium]
    
    //Create Domain [POST /domains]
    
    //Delete Domain [DELETE /domains/{domainid}]
}

struct DeviceAPI {
    
    static let Path : String = AppConstants.API_PATH + "/device"
    
    static let V_RegisterDeviceRequest : Int = 1
    static let V_UnRegisterDeviceRequest : Int = 1
}

struct ContactsAPI {
    
    static let Path : String = AppConstants.API_PATH + "/contacts"
    
    static let V_ContactsRequest : Int = 2
    static let V_ContactEmailsRequest : Int = 2
    static let V_ContactAddRequest : Int = 2
    static let V_ContactDetailRequest : Int = 2
    static let V_ContactDeleteRequest : Int = 2
    static let V_ContactUpdateRequest : Int = 2
}

