//
//  APIServiceResponse.swift
//  ProtonMail - Created on 6/18/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
    
    func ParseResponseError (_ response: [String : Any]) -> Bool {
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
    
    func ParseHttpError (_ error: NSError, response: [String : Any]? = nil) {//TODO::need refactor.
        self.code = 404
        if let detail = error.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
            self.code = detail.statusCode
        }
        else {
            internetCode = error.code
            self.code = internetCode
        }
        self.errorMessage = error.localizedDescription
        self.errorDetails = error.debugDescription
        self.error = error
    }
    
    func ParseResponse (_ response: [String : Any]) -> Bool {
        return true
    }
}
