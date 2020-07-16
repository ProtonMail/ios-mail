//
//  ErrorResponse.swift
//  PMAuthentication
//
//  Created by Anatoly Rosencrantz on 20/02/2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

enum AuthService {
    /*
     See BE discussion in internal ProtonTech docs: /proton/backend-communication/issues/12
    */
    
    static var trust: TrustChallenge?
//    static var scheme: String = "https"
//    static var host: String = "api.protonmail.ch"
//    static var apiPath: String = ""
    static var hostUrl : String = ""
    static var apiVersion: String = "3"
    static var clientVersion: String = ""
    static var redirectUri: String = "http://protonmail.ch" // Probably, we do not actually need this thing
    
//    static var baseComponents: URLComponents {
//        var urlComponents = URLComponents()
//        urlComponents.scheme = scheme
//        urlComponents.host = host
//        urlComponents.path = apiPath
//        return urlComponents
//    }
    
    static var baseHeaders: [String: String] {
        return [
            "x-pm-appversion": clientVersion,
            "x-pm-apiversion": apiVersion,
            "Accept": "application/vnd.protonmail.v1+json",
            "Content-Type": "application/json;charset=utf-8"
        ]
    }

    static func url(of path: String) -> URL {
        let serverurl = URL(string: self.hostUrl)
        guard let url = serverurl else {
            fatalError("Could not create URL from components")
        }
        return url.appendingPathComponent(path)
    }
}
