//
//  LabelAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


// MARK : Get messages part
public class GetLabelsRequest<T : ApiResponse> : ApiRequest<T> {
    
    override init() {
    }
    
    override func getAPIMethod() -> APIService.HTTPMethod {
        return .GET
    }
    
    override public func getRequestPath() -> String {
        return LabelAPI.Path + AppConstants.getDebugOption
    }
    
    override public func getVersion() -> Int {
        return LabelAPI.V_LabelFetchRequest
    }
}

public class GetLabelsResponse : ApiResponse {
    var labels : [Dictionary<String,AnyObject>]?
    
    override func ParseResponse(response: Dictionary<String, AnyObject>!) -> Bool {
        
        PMLog.D(response.JSONStringify(prettyPrinted: true))
        self.labels =  response["Labels"] as? [Dictionary<String,AnyObject>]
        
        return true
    }
}