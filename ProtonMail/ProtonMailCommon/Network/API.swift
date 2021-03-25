//
//  API.swift
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
    

import Foundation
//
//
////http headers key
//struct HTTPHeader {
//    static let apiVersion = "x-pm-apiversion"
//}
//
//enum HTTPMethod {
//    case delete
//    case get
//    case post
//    case put
//
//    func toString() -> String {
//        switch self {
//        case .delete:
//            return "DELETE"
//        case .get:
//            return "GET"
//        case .post:
//            return "POST"
//        case .put:
//            return "PUT"
//        }
//    }
//}
//
//protocol APIServerConfig  {
//    //host name    xxx.xxxxxxx.com
//    var host : String { get }
//    // http https ws wss etc ...
//    var `protocol` : String {get}
//    // prefixed path after host example:  /api
//    var path : String {get}
//    // full host with protocol, without path
//    var hostUrl : String {get}
//}
//extension APIServerConfig {
//    var hostUrl : String {
//        get {
//            return self.protocol + "://" + self.host
//        }
//    }
//}
//
////Predefined servers, could also add the serverlist load from config env later
//enum Server : APIServerConfig {
//    case live //"api.protonmail.ch"
//    case testlive //"test-api.protonmail.ch"
//
//    case dev1 //"dev.protonmail.com"
//    case dev2 //"dev-api.protonmail.ch"
//
//    case blue //"protonmail.blue"
//    case midnight //"midnight.protonmail.blue"
//
//    //local test
//    //static let URL_HOST : String = "http://127.0.0.1"  //http
//
//    var host: String {
//        get {
//            switch self {
//            case .live:
//                return "api.protonmail.ch"
//            case .blue:
//                return "protonmail.blue"
//            case .midnight:
//                return "midnight.protonmail.blue"
//            case .testlive:
//                return "test-api.protonmail.ch"
//            case .dev1:
//                return "dev.protonmail.com"
//            case .dev2:
//                return "dev-api.protonmail.ch"
//            }
//        }
//    }
//
//    var path: String {
//        get {
//            switch self {
//            case .live, .testlive, .dev2:
//                return ""
//            case .blue, .midnight, .dev1:
//                return "/api"
//            }
//        }
//    }
//
//    var `protocol`: String {
//        get {
//            return "https"
//        }
//    }
//
//}



//enum <T> {
//    case failure(Error)
//    case success(T)
//}
//protocol API {
//    func request(method: HTTPMethod, path: String,
//                 parameters: Any?, headers: [String : Any]?,
//                 authenticated: Bool,
//                 customAuthCredential: AuthCredential?,
//                 completion: CompletionBlock?)
//}

