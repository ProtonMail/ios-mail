//
//  AttachmentAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/19/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

// MARK : delete attachment from a draft
final class DeleteAttachment : ApiRequest<ApiResponse> {
    let attachmentID : String!
    init(attID : String) {
        self.attachmentID = attID
    }
    
    override func path() -> String {
        //return AttachmentAPI.path + "/remove" + AppConstants.DEBUG_OPTION
        return AttachmentAPI.path + "/" + self.attachmentID + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AttachmentAPI.v_del_attachment
    }
    
    override func method() -> APIService.HTTPMethod {
        return .delete
    }
}


