//
//  API.swift
//  ProtonMail - Created on 7/23/19.
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

//http headers key
struct HTTPHeader {
    static let apiVersion = "x-pm-apiversion"
}

enum HTTPMethod {
    case delete
    case get
    case post
    case put
    
    func toString() -> String {
        switch self {
        case .delete:
            return "DELETE"
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .put:
            return "PUT"
        }
    }
}

protocol APIServerConfig  {
    //host name    xxx.xxxxxxx.com
    var host : String { get }
    // http https ws wss etc ...
    var `protocol` : String {get}
    // prefixed path after host example:  /api
    var path : String {get}
    // full host with protocol, without path
    var hostUrl : String {get}
}
extension APIServerConfig {
    var hostUrl : String {
        get {
            return self.protocol + "://" + self.host
        }
    }
}

//Predefined servers, could also add the serverlist load from config env later
enum Server : APIServerConfig {
    case live //"api.protonmail.ch"
    case testlive //"test-api.protonmail.ch"
    
    case dev1 //"dev.protonmail.com"
    case dev2 //"dev-api.protonmail.ch"
    
    case blue //"protonmail.blue"
    case midnight //"midnight.protonmail.blue"
    
    //local test
    //static let URL_HOST : String = "http://127.0.0.1"  //http
    
    var host: String {
        get {
            switch self {
            case .live:
                return "api.protonmail.ch"
            case .blue:
                return "protonmail.blue"
            case .midnight:
                return "midnight.protonmail.blue"
            case .testlive:
                return "test-api.protonmail.ch"
            case .dev1:
                return "dev.protonmail.com"
            case .dev2:
                return "dev-api.protonmail.ch"
            }
        }
    }
    
    var path: String {
        get {
            switch self {
            case .live, .testlive, .dev2:
                return ""
            case .blue, .midnight, .dev1:
                return "/api"
            }
        }
    }
    
    var `protocol`: String {
        get {
            return "https"
        }
    }

}



//enum <T> {
//    case failure(Error)
//    case success(T)
//}
typealias CompletionBlock = (_ task: URLSessionDataTask?, _ response: [String : Any]?, _ error: NSError?) -> Void
protocol API {
    func request(method: HTTPMethod, path: String,
                 parameters: Any?, headers: [String : Any]?,
                 authenticated: Bool,
                 customAuthCredential: AuthCredential?,
                 completion: CompletionBlock?)
}

