//
//  AttachmentAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/19/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

// MARK : Get messages part
final class AttachmentDeleteRequest<T : ApiResponse> : ApiRequest<T> {
    let body : String!
    init(body : String) {
        self.body = body
    }
    
    override func toDictionary() -> Dictionary<String, Any>? {
        let data : Data! = body.data(using: String.Encoding.utf8)
        do {
            let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? Dictionary<String, Any>
            //PMLog.D(self.JSONStringify(body, prettyPrinted: true))
            return decoded
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return nil
    }
    
    override func path() -> String {
        return AttachmentAPI.Path + "/remove" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AttachmentAPI.V_AttachmentRemoveRequest
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
}
