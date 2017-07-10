//
//  APIServiceRequest.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

protocol Package {
    
    /**
     conver requset object to dictionary
     
     :returns: request dictionary
     */
    func toDictionary() -> Dictionary<String, Any>?
}


//abstract api request base class
class ApiRequest<T : ApiResponse> : Package {
    
    public init () { }
    
    //add error response
    public typealias ResponseCompletionBlock = (_ task: URLSessionDataTask?, _ response: T?, _ hasError : Bool) -> Void
    
    func toDictionary() -> Dictionary<String, Any>? {
        return nil
    }
    
    /**
     get current api request
     
     :returns: int version number
     */
    func getVersion () -> Int {
        return 1
    }
    
    
    /**
     get is current function need auth check
     
     :returns: default is true
     */
    func getIsAuthFunction () -> Bool {
        return true
    }
    
    /**
     get request path
     
     :returns: String value
     */
    func getRequestPath () -> String {
        NSException(name:NSExceptionName(rawValue: "Error"), reason:"Not Implement, you need override the function", userInfo:nil).raise()
        return "";
    }
    
    /**
     base class for convert anyobject to a json string
     
     :param: value         AnyObject input value
     :param: prettyPrinted Bool is need pretty format
     
     :returns: String value
     */
    func JSONStringify(_ value: Any, prettyPrinted: Bool = false) -> String {
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions()
        if JSONSerialization.isValidJSONObject(value) {
            do {
                let data = try JSONSerialization.data(withJSONObject: value, options: options)
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    return string as String
                }
            } catch let ex as NSError {
                PMLog.D("\(ex)")
            }
            
        }
        return ""
    }
    
    
    func getAPIMethod() -> APIService.HTTPMethod {
        return .get
    }
    
    public func call(_ complete: ResponseCompletionBlock?) {
        //TODO :: 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper:  APIService.CompletionBlock = { task, res, error in
            let realType = T.self
            let apiRes = realType.init()
            
            if error != nil {
                //TODO check error
                apiRes.ParseHttpError(error!)
                complete?(task, apiRes, true)
                return
            }
            
            if res == nil {
                // TODO check res
                apiRes.error = NSError.badResponse()
                complete?(task, apiRes, true)
                return
            }
            
            var hasError = apiRes.ParseResponseError(res!)
            if !hasError {
                hasError = !apiRes.ParseResponse(res!)
            }
            
            complete?(task, apiRes, hasError)
        }
        sharedAPIService.request(method: self.getAPIMethod(), path: self.getRequestPath(), parameters: self.toDictionary(), headers: ["x-pm-apiversion": self.getVersion()], authenticated: self.getIsAuthFunction(), completion: completionWrapper)
    }
    
    
    public func syncCall() throws -> T? {
        var ret_res : T? = nil
        var ret_error : NSError? = nil
        let sema = DispatchSemaphore(value: 0);
        //TODO :: 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper:  APIService.CompletionBlock = { task, res, error in
            defer {
                sema.signal();
            }
            let realType = T.self
            let apiRes = realType.init()
            if error != nil {
                //TODO check error
                apiRes.ParseHttpError(error!)
                ret_error = apiRes.error
                return
            }
            
            if res == nil {
                // TODO check res
                apiRes.error = NSError.badResponse()
                ret_error = apiRes.error
                return
            }
            
            var hasError = apiRes.ParseResponseError(res!)
            if !hasError {
                hasError = !apiRes.ParseResponse(res!)
            }
            if hasError {
                ret_error = apiRes.error
                return
            }
            ret_res = apiRes
        }
        sharedAPIService.request(method: self.getAPIMethod(), path: self.getRequestPath(), parameters: self.toDictionary(), headers: ["x-pm-apiversion": self.getVersion()], authenticated: self.getIsAuthFunction(), completion: completionWrapper)
        //wait operations
        let _ = sema.wait(timeout: DispatchTime.distantFuture)
        
        if let e = ret_error {
            throw e
        }
        return ret_res
    }
}









