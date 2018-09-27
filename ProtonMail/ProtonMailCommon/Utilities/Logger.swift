//
//  NSLogExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class PMLog {
    
    static func D(nstring message: NSString, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column) {
        #if DEBUG
            print("\(function) : \(line) : \(column) ↓ \r\n \(file) : \r\n\(message)")
        #endif
    }
    
    static func D(_ message: String, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column) {
        #if DEBUG
            print("\(function) : \(line) : \(column) ↓ \r\n \(file) : \r\n\(message)")
        #endif
    }
    
    static func D(any message: Any, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column ) {
        #if DEBUG
            print("\(function) : \(line) : \(column) ↓ \r\n \(file) : \r\n\(message)")
        #endif
    }
    
    static func D(api error: NSError, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column ) {
        #if DEBUG
            print("\(function) : \(line) : \(column) ↓ \r\n \(file) :")
            print("Domain = " + error.domain)
            print("LocalizedDesc = " + error.localizedDescription)
            if let detail = error.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
                print(detail)
            }
            if let data = error.userInfo["com.alamofire.serialization.response.error.data"] as? Data,
                let resObj = String(data: data, encoding: .utf8) {
                print("ErrorDetails = " + resObj)
            }
        #endif
    }
}
