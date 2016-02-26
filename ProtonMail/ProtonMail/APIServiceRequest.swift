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
    func toDictionary() -> Dictionary<String, AnyObject>?
}




//abstract api request base class
public class ApiRequest<T : ApiResponse> : Package {
    
    public init () { }
    
    //add error response
    public typealias ResponseCompletionBlock = (task: NSURLSessionDataTask!, response: T?, hasError : Bool) -> Void
    
    func toDictionary() -> Dictionary<String, AnyObject>? {
        return nil
    }
    
    /**
    get current api request
    
    :returns: int version number
    */
    public func getVersion () -> Int {
        return 1
    }
    
    
    /**
    get is current function need auth check
    
    :returns: default is true
    */
    public func getIsAuthFunction () -> Bool {
        return true
    }
    
    /**
    get request path
    
    :returns: String value
    */
    public func getRequestPath () -> String {
        NSException(name:"Error", reason:"Not Implement, you need override the function", userInfo:nil).raise()
        return "";
    }
    
    /**
    base class for convert anyobject to a json string
    
    :param: value         AnyObject input value
    :param: prettyPrinted Bool is need pretty format
    
    :returns: String value
    */
    func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            }
        }
        return ""
    }
    
    
    func getAPIMethod() -> APIService.HTTPMethod  {
        return .GET
    }
    
    func call(complete: ResponseCompletionBlock?){
        //TODO :: 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper:  APIService.CompletionBlock = { task, res, error in
            let realType = T.self
            var apiRes = realType()
            
            if error != nil {
                //TODO check error
                apiRes.ParseHttpError(error!)
                complete?(task:task, response:apiRes, hasError: true)
                return
            }
            
            if res == nil {
                // TODO check res
                apiRes.error = NSError.badResponse()
                complete?(task:task, response:apiRes, hasError: true)
                return
            }
            
            var hasError = apiRes.ParseResponseError(res!)
            if !hasError {
                hasError = !apiRes.ParseResponse(res!)
            }
            
            complete?(task:task, response:apiRes, hasError: hasError)
        }
        
        sharedAPIService.setApiVesion(self.getVersion(), appVersion: 1) // TODO: here need get functions
        sharedAPIService.request(method: self.getAPIMethod(), path: self.getRequestPath(), parameters: self.toDictionary(), authenticated: self.getIsAuthFunction(), completion:completionWrapper)
    }
}









