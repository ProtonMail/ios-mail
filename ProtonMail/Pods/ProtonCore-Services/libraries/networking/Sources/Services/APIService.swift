//
//  APIService.swift
//  ProtonCore-Services - Created on 5/22/20.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

// swiftlint:disable identifier_name todo function_parameter_count

import Foundation
import ProtonCore_Doh
import ProtonCore_Log
import ProtonCore_Utilities
import ProtonCore_Networking

/// http headers key
public struct HTTPHeader {
    public static let apiVersion = "x-pm-apiversion"
}

extension Bundle {
    /// Returns the app version in a nice to read format
    var appVersion: String {
        return "\(majorVersion) (\(buildVersion))"
    }

    /// Returns the build version of the app.
    var buildVersion: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    /// Returns the major version of the app.
    public var majorVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}

///
public protocol APIServerConfig {
    
    // host name    xxx.xxxxxxx.com
    var host: String { get }
    
    // http https ws wss etc ...
    var `protocol`: String { get }
    
    // prefixed path after host example:  /api
    var path: String { get }
    
    // full host with protocol, without path
    var hostUrl: String { get }
}

extension APIServerConfig {
    
    public var hostUrl: String {
        return self.protocol + "://" + self.host
    }
}

public typealias CompletionBlock = (_ task: URLSessionDataTask?, _ response: [String: Any]?, _ error: NSError?) -> Void

public protocol API {

    func request(method: HTTPMethod, path: String,
                 parameters: Any?, headers: [String: Any]?,
                 authenticated: Bool, autoRetry: Bool,
                 customAuthCredential: AuthCredential?,
                 completion: CompletionBlock?)

    func download(byUrl url: String, destinationDirectoryURL: URL,
                  headers: [String: Any]?,
                  authenticated: Bool,
                  customAuthCredential: AuthCredential?,
                  downloadTask: ((URLSessionDownloadTask) -> Void)?,
                  completion: @escaping ((URLResponse?, URL?, NSError?) -> Void))

    func upload (byPath path: String,
                 parameters: [String: String],
                 keyPackets: Data,
                 dataPacket: Data,
                 signature: Data?,
                 headers: [String: Any]?,
                 authenticated: Bool,
                 customAuthCredential: AuthCredential?,
                 completion: @escaping CompletionBlock)

    func uploadFromFile (byPath path: String,
                         parameters: [String: String],
                         keyPackets: Data,
                         dataPacketSourceFileURL: URL,
                         signature: Data?,
                         headers: [String: Any]?,
                         authenticated: Bool,
                         customAuthCredential: AuthCredential?,
                         completion: @escaping CompletionBlock)
}

/// this is auth UI related
public protocol APIServiceDelegate: AnyObject {
    func onUpdate(serverTime: Int64)
    
    // check if server reachable or check if network avaliable
    func isReachable() -> Bool

    var appVersion: String { get }
    
    var locale: String { get }

    var userAgent: String? { get }

    func onDohTroubleshot()
}

public protocol HumanVerifyDelegate: AnyObject {
    typealias HumanVerifyHeader = [String: Any]
    typealias HumanVerifyIsClosed = Bool

    func onHumanVerify(methods: [VerifyMethod], startToken: String?, completion: (@escaping (HumanVerifyHeader, HumanVerifyIsClosed, SendVerificationCodeBlock?) -> Void))
    func getSupportURL() -> URL
}

public enum HumanVerifyEndResult {
    case success
    case cancel
}

public protocol HumanVerifyResponseDelegate: AnyObject {
    func onHumanVerifyStart()
    func onHumanVerifyEnd(result: HumanVerifyEndResult)
}

public enum PaymentTokenStatusResult {
    case success
    case fail
}

public protocol HumanVerifyPaymentDelegate: AnyObject {
    var paymentToken: String? { get }
    func paymentTokenStatusChanged(status: PaymentTokenStatusResult)
}

public typealias AuthRefreshComplete = (_ auth: Credential?, _ hasError: AuthErrors?) -> Void

/// this is auth related delegate in background
public protocol AuthDelegate: AnyObject {
    func getToken(bySessionUID uid: String) -> AuthCredential?
    func onLogout(sessionUID uid: String)
    func onUpdate(auth: Credential)
    func onRefresh(bySessionUID uid: String, complete:  @escaping AuthRefreshComplete)
    func onForceUpgrade()
}

public protocol APIService: API {
    // var network : NetworkLayer {get}
    // var vpn : VPNInterface {get}
    // var doh:  DoH  {get}//depends on NetworkLayer. {get}
    // var queue : [Request] {get}
    func setSessionUID(uid: String)

    var serviceDelegate: APIServiceDelegate? { get set }
    var authDelegate: AuthDelegate? { get set }
    var humanDelegate: HumanVerifyDelegate? { get set }
    var doh: DoH & ServerConfig { get set }
    var signUpDomain: String { get }
}

class TestResponse: Response {

}

typealias RequestComplete = (_ task: URLSessionDataTask?, _ response: Response) -> Void

public extension APIService {
    // init
    func exec<T>(route: Request) -> T? where T: Response {
        var ret_res: T?
        var ret_error: ResponseError?
        let sema = DispatchSemaphore(value: 0)
        // TODO :: 1 make a request, 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, responseDict, error in
            defer {
                sema.signal()
            }
            switch Response.parseNetworkCallResults(to: T.self, response: task?.response, responseDict: responseDict, error: error) {
            case (_, let networkingError?):
                ret_error = networkingError
            case (let response, nil):
                ret_res = response
            }
        }
        // TODO:: missing auth
        var header = route.header
        header[HTTPHeader.apiVersion] = route.version
        self.request(method: route.method, path: route.path,
                     parameters: route.parameters,
                     headers: header,
                     authenticated: route.isAuth,
                     autoRetry: route.autoRetry,
                     customAuthCredential: route.authCredential,
                     completion: completionWrapper)

        // wait operations
        _ = sema.wait(timeout: DispatchTime.distantFuture)
        if let e = ret_error {
            // TODO::fix me
            PMLog.debug(e.localizedDescription)
        }
        return ret_res
    }

    func exec<T>(route: Request,
                 complete: @escaping  (_ task: URLSessionDataTask?, _ response: T) -> Void) where T: Response {

        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, responseDict, error in
            switch T.parseNetworkCallResults(to: T.self, response: task?.response, responseDict: responseDict, error: error) {
            case (let response, _?):
                // TODO: this was a previous logic — to parse response even if there's an error
                if let resRaw = responseDict {
                    _ = response.ParseResponse(resRaw)
                }
                DispatchQueue.main.async {
                    complete(task, response)
                }
            case (let response, nil):
                DispatchQueue.main.async {
                    complete(task, response)
                }
            }
        }

        var header = route.header
        header[HTTPHeader.apiVersion] = route.version
        self.request(method: route.method, path: route.path,
                     parameters: route.parameters,
                     headers: header,
                     authenticated: route.isAuth,
                     autoRetry: route.autoRetry,
                     customAuthCredential: route.authCredential,
                     completion: completionWrapper)
    }

    func exec<T>(route: Request, complete: @escaping (_ response: T) -> Void) where T: Response {

        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, responseDict, error in
            switch T.parseNetworkCallResults(to: T.self, response: task?.response, responseDict: responseDict, error: error) {
            case (let response, _?):
                // TODO: this was a previous logic — to parse response even if there's an error. should we move it to parseNetworkCallResults?
                if let resRaw = responseDict {
                    _ = response.ParseResponse(resRaw)
                }
                DispatchQueue.main.async {
                    complete(response)
                }
            case (let response, nil):
                DispatchQueue.main.async {
                    complete(response)
                }
            }
        }

        var header = route.header
        header[HTTPHeader.apiVersion] = route.version
        self.request(method: route.method, path: route.path,
                     parameters: route.parameters,
                     headers: header,
                     authenticated: route.isAuth,
                     autoRetry: route.autoRetry,
                     customAuthCredential: route.authCredential,
                     completion: completionWrapper)
    }

    func exec<T>(route: Request, complete: @escaping (_ task: URLSessionDataTask?, _ result: Result<T, ResponseError>) -> Void) where T: Codable {

        // 1 make a request , 2 wait for the respons async 3. valid response 4. parse data into response 5. some data need save into database.
        let completionWrapper: CompletionBlock = { task, res, error in
            do {
                if let res = res {
                    // this is a workaround for afnetworking, will change it
                    let responseData = try JSONSerialization.data(withJSONObject: res, options: .prettyPrinted)
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .decapitaliseFirstLetter
                    // server error code
                    if let errorResponse = try? decoder.decode(ErrorResponse.self, from: responseData) {
                        let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                          responseCode: errorResponse.code,
                                                          userFacingMessage: errorResponse.error,
                                                          underlyingError: NSError(errorResponse))
                        DispatchQueue.main.async {
                            complete(task, .failure(responseError))
                        }
                        return
                    }
                    // server SRP
                    let decodedResponse = try decoder.decode(T.self, from: responseData)
                    DispatchQueue.main.async {
                        complete(task, .success(decodedResponse))
                    }
                } else if let error = error {
                    let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                      responseCode: nil,
                                                      userFacingMessage: nil,
                                                      underlyingError: error)
                    DispatchQueue.main.async {
                        complete(task, .failure(responseError))
                    }
                    return
                } else {
                    let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                      responseCode: nil,
                                                      userFacingMessage: nil,
                                                      underlyingError: nil)
                    DispatchQueue.main.async {
                        complete(task, .failure(responseError))
                    }
                }
            } catch let decodingError {
                let responseError = ResponseError(httpCode: (task?.response as? HTTPURLResponse)?.statusCode,
                                                  responseCode: nil, // unable to decode means no response
                                                  userFacingMessage: nil,
                                                  underlyingError: decodingError as NSError)
                DispatchQueue.main.async {
                    complete(task, .failure(responseError))
                }
            }
        }
        var header = route.header
        header[HTTPHeader.apiVersion] = route.version
        self.request(method: route.method, path: route.path,
                     parameters: route.parameters,
                     headers: header,
                     authenticated: route.isAuth,
                     autoRetry: route.autoRetry,
                     customAuthCredential: route.authCredential,
                     completion: completionWrapper)
    }

    func exec<T>(route: Request, complete: @escaping (_ result: Result<T, ResponseError>) -> Void) where T: Codable {
        exec(route: route) { (_: URLSessionDataTask?, result: Result<T, ResponseError>) in
            complete(result)
        }
    }
}
