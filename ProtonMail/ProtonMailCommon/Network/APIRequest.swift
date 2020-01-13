//
//  APIRequest.swift
//  ProtonMail - Created on 7/23/19.
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


//import Foundation
//
//import PromiseKit
//import AwaitKit
//
//protocol Package {
//    /**
//     conver requset object to dictionary
//     
//     :returns: request dictionary
//     */
//    func toDictionary() -> [String: Any]?
//}
//
//
////abstract api request base class
//class ApiRequest<T : ApiResponse> : Package {
//    
//    init () { }
//    
//    //add error response
//    public typealias ResponseCompletionBlock = (_ task: URLSessionDataTask?, _ response: T?, _ hasError : Bool) -> Void
//    
//    func toDictionary() -> [String : Any]? {
//        return nil
//    }
//    
//    /**
//     get current api request
//     
//     :returns: int version number
//     */
//    func apiVersion() -> Int {
//        return 1
//    }
//    
//    
//    /**
//     get is current function need auth check
//     
//     :returns: default is true
//     */
//    func getIsAuthFunction() -> Bool {
//        return true
//    }
//    
//    var authCredential: AuthCredential?
//    
//    /**
//     get request path
//     
//     :returns: String value
//     */
//    func path() -> String {
//        fatalError("This method must be overridden")
//    }
//    
//    func method() -> APIService.HTTPMethod {
//        return .get
//    }
//    
//    func call(_ complete: ResponseCompletionBlock?) {
//        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
//        let completionWrapper:  APIService.CompletionBlock = { task, res, error in
//            let realType = T.self
//            let apiRes = realType.init()
//            
//            if error != nil {
//                //TODO check error
//                apiRes.ParseHttpError(error!, response: res)
//                complete?(task, apiRes, true)
//                return
//            }
//            
//            if res == nil {
//                // TODO check res
//                apiRes.error = NSError.badResponse()
//                complete?(task, apiRes, true)
//                return
//            }
//            
//            var hasError = apiRes.ParseResponseError(res!)
//            if !hasError {
//                hasError = !apiRes.ParseResponse(res!)
//            }
//            complete?(task, apiRes, hasError)
//        }
//        
//        sharedAPIService.request(method: self.method(),
//                                 path: self.path(),
//                                 parameters: self.toDictionary(),
//                                 headers: ["x-pm-apiversion": self.apiVersion()],
//                                 authenticated: self.getIsAuthFunction(),
//                                 customAuthCredential: self.authCredential,
//                                 completion: completionWrapper)
//    }
//    
//    
//    public func syncCall() throws -> T? {
//        var ret_res : T? = nil
//        var ret_error : NSError? = nil
//        let sema = DispatchSemaphore(value: 0);
//        //TODO :: 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
//        let completionWrapper:  APIService.CompletionBlock = { task, res, error in
//            defer {
//                sema.signal();
//            }
//            let realType = T.self
//            let apiRes = realType.init()
//            if error != nil {
//                //TODO check error
//                apiRes.ParseHttpError(error!)
//                ret_error = apiRes.error
//                return
//            }
//            
//            if res == nil {
//                // TODO check res
//                apiRes.error = NSError.badResponse()
//                ret_error = apiRes.error
//                return
//            }
//            
//            var hasError = apiRes.ParseResponseError(res!)
//            if !hasError {
//                hasError = !apiRes.ParseResponse(res!)
//            }
//            if hasError {
//                ret_error = apiRes.error
//                return
//            }
//            ret_res = apiRes
//        }
//        
//        sharedAPIService.request(method: self.method(),
//                                 path: self.path(),
//                                 parameters: self.toDictionary(),
//                                 headers: ["x-pm-apiversion": self.apiVersion()],
//                                 authenticated: self.getIsAuthFunction(),
//                                 customAuthCredential: self.authCredential,
//                                 completion: completionWrapper)
//        
//        //wait operations
//        let _ = sema.wait(timeout: DispatchTime.distantFuture)
//        if let e = ret_error {
//            throw e
//        }
//        return ret_res
//    }
//}
//
//
////abstract api request base class
//class ApiRequestNew<T : ApiResponse> : Package {
//    
//    init () { }
//    
//    //add error response
//    //public typealias ResponseCompletionBlock = (_ task: URLSessionDataTask?, _ response: T?, _ hasError : Bool) -> Void
//    
//    func toDictionary() -> [String : Any]? {
//        return nil
//    }
//    
//    /**
//     get current api request
//     
//     :returns: int version number
//     */
//    func apiVersion() -> Int {
//        return 1
//    }
//    
//    /**
//     get is current function need auth check
//     
//     :returns: default is true
//     */
//    func getIsAuthFunction() -> Bool {
//        return true
//    }
//    
//    var authCredential: AuthCredential?
//    
//    /**
//     get request path
//     
//     :returns: String value
//     */
//    func path() -> String {
//        fatalError("This method must be overridden")
//    }
//    
//    func method() -> APIService.HTTPMethod {
//        return .get
//    }
//    
//    func run() -> Promise<T> {
//        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
//        let deferred = Promise<T>.pending()
//        let completionWrapper:  APIService.CompletionBlock = { task, res, error in
//            let realType = T.self
//            let apiRes = realType.init()
//            
//            if error != nil {
//                #if DEBUG
//                if let res = res {
//                    PMLog.D(res.json(prettyPrinted: true))
//                }
//                #endif
//                //TODO check error
//                apiRes.ParseHttpError(error!)
//                deferred.resolver.reject(error!)
//            }
//            
//            if res == nil {
//                // TODO check res
//                deferred.resolver.reject(NSError.badResponse())
//                return
//            }
//            
//            var hasError = apiRes.ParseResponseError(res!)
//            if !hasError {
//                hasError = !apiRes.ParseResponse(res!)
//            }
//            if hasError {
//                deferred.resolver.reject(apiRes.error!)
//            } else {
//                deferred.resolver.fulfill(apiRes)
//            }
//        }
//        sharedAPIService.request(method: self.method(),
//                                 path: self.path(),
//                                 parameters: self.toDictionary(),
//                                 headers: ["x-pm-apiversion": self.apiVersion()],
//                                 authenticated: self.getIsAuthFunction(),
//                                 customAuthCredential: self.authCredential,
//                                 completion: completionWrapper)
//        
//        return deferred.promise
//        
//    }
//    
//    
//    func execute(in api: API) {
//        
//    }
//}
//
//
//
//
