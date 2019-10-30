//
//  Logger.swift
//  ProtonMail
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


public class PMLog {
    
    static func D(nstring message: NSString, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column) {
        #if DEBUG
        print("\(function) : \(line) : \(column) ↓ \n\(file) : \n\(message)\n")
        #endif
    }
    
    static func D(_ message: String, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column) {
        #if DEBUG
        print("\(function) : \(line) : \(column) ↓ \n\(file) : \n\(message)\n")
        #endif
    }
    
    static func D(any message: Any, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column ) {
        #if DEBUG
        print("\(function) : \(line) : \(column) ↓ \n\(file) : \n\(message)\n")
        #endif
    }
    
    static func D(api error: NSError, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column ) {
        #if DEBUG
        print("\(function) : \(line) : \(column) ↓ \n\(file) :")
        print("Domain = " + error.domain)
        print("LocalizedDesc = " + error.localizedDescription)
        if let detail = error.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
            print(detail)
        }
        if let data = error.userInfo["com.alamofire.serialization.response.error.data"] as? Data,
            let resObj = String(data: data, encoding: .utf8) {
            print("ErrorDetails = " + resObj)
        }
        print("")
        #endif
    }
}
