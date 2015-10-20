//
//  AttachmentAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/19/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


// MARK : Get messages part
public class AttachmentDeleteRequest<T : ApiResponse> : ApiRequest<T> {
    let body : String!
    init(body : String) {
        self.body = body
    }
    
    override func toDictionary() -> Dictionary<String, AnyObject>? {
        var error:NSError?;
        let data : NSData! = body.dataUsingEncoding(NSUTF8StringEncoding)
        let decoded = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error:  &error) as? Dictionary<String, AnyObject>

        PMLog.D(self.JSONStringify(body, prettyPrinted: true))
        return decoded
    }
    
    override public func getRequestPath() -> String {
        return AttachmentAPI.Path + "/remove" + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return AttachmentAPI.V_AttachmentRemoveRequest
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .PUT
    }
}
