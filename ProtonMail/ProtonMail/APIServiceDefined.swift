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
    static let path :String = AppConstants.API_PATH + "/attachments"

    
    /// get attachment by id
    static let v_get_att_by_id : Int = 3
    
    /// upload attachment
    static let v_upload_attach : Int = 3
    
    /// update draft attachment signature
    static let v_update_att_sign : Int = 3
    
    /// delete attachment from draft
    static let v_del_attachment : Int = 3
}

//Auth API
//Doc:https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_auth.md
struct AuthAPI {
    /// base message api path
    static let path :String = AppConstants.API_PATH + "/auth"
    
    /// user auth post
    static let v_auth : Int = 3
    
    /// refresh token post
    static let v_auth_refresh : Int = 3
    
    /// setup auth info post
    static let v_auth_info : Int = 3
    
    /// get random srp modulus
    static let v_get_auth_modulus : Int = 3
    
    /// delete auth
    static let v_delete_auth : Int = 3
    
    /// revoke other tokens
    static let v_revoke_others : Int = 3
}

//Contact API
//Doc:https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_contacts_v2.md
struct ContactsAPI {
    
    static let path : String = AppConstants.API_PATH + "/contacts"
    
    /// get contact list. no details. only name, email, labels for displaying
    static let v_get_contacts : Int = 3
    /// get contact email list. this is for auto complete. combine with contacts would be full information without encrypted data.
    static let v_get_contact_emails : Int = 3
    /// add & import contact post
    static let v_add_contacts : Int = 3
    /// get contact details full date clear&encrypt data
    static let v_get_details : Int = 3
    /// update contact put
    static let v_update_contact : Int = 3
    /// delete contact put
    static let v_delete_contacts : Int = 3
    
    /// group
    
    /// export
    
    /// clear contacts
}

//Device API
//Doc:https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_devices.md
struct DeviceAPI {
    
    static let path : String = AppConstants.API_PATH + "/devices"
    
    /// register a device POST
    static let v_register_device : Int = 3
    
    /// delete a registered device post
    static let v_delete_device : Int = 3
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

//Events API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_events_v3.md
struct EventAPI {
    /// base event api path
    static let path :String = AppConstants.API_PATH + "/events"
    
    /// get latest event id
    static let v_get_latest_event_id : Int = 3
    
    /// get updated events based on latest event id
    static let v_get_events : Int = 3
    
}

//Keys API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_keys.md
struct KeysAPI {
    static let path : String = AppConstants.API_PATH + "/keys"
    
    //Update private keys only, use for mailbox password/single password updates PUT
    static let v_update_private_key : Int = 3
    
    //Setup keys for new account, private user [POST]
    static let v_setup_key : Int = 3
    
    //Get key salts, locked route [GET]
    static let v_get_key_salts : Int = 3
}

//Labels API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_labels.md
struct LabelAPI {
    static let path :String = AppConstants.API_PATH + "/labels"
    
    /// Get user's labels [GET]
    static let v_get_user_labels : Int = 3
    
    /// Create new label [POST]
    static let v_create_label : Int = 3
    
    /// Update existing label [PUT]
    static let v_update_label : Int = 3
    
    /// Delete a label [DELETE]
    static let v_delete_label : Int = 3
    
    //TODO:: need move it into message when api to v3
    static let V_ApplyLabelToMessageRequest : Int = 1
    static let V_RemoveLabelFromMessageRequest : Int = 1
    
    //doesn't impl yet
    /// Change label priority [PUT]
    static let v_order_labels : Int = 3
}

//Message API
//Doc: V1 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_messages.md
//Doc: V3 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_messages_v3.md
struct MessageAPI {
    //TODO:: need to finish
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

//Organization API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_organizations.md
struct OrganizationsAPI {
    static let Path : String = AppConstants.API_PATH + "/organizations"
    
    /// Get organization keys [GET]
    static let v_get_org_keys : Int = 3
}


//Reports API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_reports.md
struct ReportsAPI {
    static let path :String = AppConstants.API_PATH + "/reports"
    
    /// Report a bug [POST]
    static let v_reports_bug : Int = 3
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

//Users API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_users.md
struct UsersAPI {
    //
    static let path : String = AppConstants.API_PATH + "/users"
    
    /// Check if username already taken [GET]
    static let v_check_is_user_exist : Int = 3
    
    /// Check if direct user signups are enabled [GET]
    static let v_get_user_direct : Int = 3
    
    /// Get user's info [GET]
    static let v_get_userinfo : Int = 3
    
    /// Get options for human verification [GET]
    static let v_get_human_verify_options : Int = 3
    
    /// Verify user is human [POST]
    static let v_verify_human : Int = 3
    
    /// Create user [POST]
    static let v_create_user : Int = 3
    
    /// Send a verification code [POST]
    static let v_send_verification_code : Int = 3
    
    static let V_GetUserPublicKeysRequest : Int = 2  //TODO:: need move to message
}
