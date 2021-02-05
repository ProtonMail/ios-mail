//
//  APIServiceRequest.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation

//TODO:: remove me

//*******************************************************************************************
//ProtonMail API Doc : https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api.md
//ProtonMail API Doc : http://185.70.40.19:3001/#messages-send-message-post
//*******************************************************************************************


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
    static let path :String = "/\(Constants.App.API_PREFIXED)/attachments"

    
    /// get attachment by id
    static let v_get_att_by_id : Int = -1
    
    /// upload attachment
    static let v_upload_attach : Int = -1
    
    /// update draft attachment signature
    static let v_update_att_sign : Int = -1
    
    /// delete attachment from draft
    static let v_del_attachment : Int = -1
}



//Device API
//Doc:https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_devices.md
struct DeviceAPI {
    
    static let path : String = "/devices"
    
    /// register a device POST
    static let v_register_device : Int = 3
    
    /// delete a registered device post
    static let v_delete_device : Int = 3
}

//Domains API
//Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_domains.md
struct DomainsAPI {
    
    static let path : String = "/domains"
    
    //Get all domains for this user's organization and check their DNS's [GET]
    
    //Get a specific domains and its check DNS [GET]
    
    //Get Available Domains [GET /domains/available]
    //static let v_available_domains : Int = 3
    
    //Get Premium Domains [GET /domains/premium]
    
    //Create Domain [POST /domains]
    
    //Delete Domain [DELETE /domains/{domainid}]
}



