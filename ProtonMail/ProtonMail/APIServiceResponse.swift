//
//  APIServiceResponse.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class ApiResponse {
    required public init() {}
    
    var code : Int! = 1000
    var errorMessage : String?
    var errorDetails : String?
    var internetCode : Int? //only use when error happend.
    
    var error : NSError?
    
    func CheckHttpStatus() -> Bool {
        return code == 200 || code == 1000
    }
    
    func CheckBodyStatus () -> Bool {
        return code == 1000
    }
    
    func ParseResponseError (_ response: [String : Any]!) -> Bool {
        code = response["Code"] as? Int
        errorMessage = response["Error"] as? String
        errorDetails = response["ErrorDescription"] as? String
        
        if code == nil {
            return false
        }

        if code != 1000 && code != 1001 {
            self.error = NSError.protonMailError(code ?? 1000,
                                                 localizedDescription: errorMessage ?? "",
                                                 localizedFailureReason: errorDetails,
                                                 localizedRecoverySuggestion: nil)
        }
        return code != 1000 && code != 1001
    }
    
    func ParseHttpError (_ error: NSError) {
        self.code = 404
        if let detail = error.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
            self.code = detail.statusCode
        }
        else {
            internetCode = error.code
        }
        self.errorMessage = error.localizedDescription
        self.errorDetails = error.debugDescription
        self.error = error
    }
    
    func ParseResponse (_ response: [String : Any]!) -> Bool {
        return true
    }
}
