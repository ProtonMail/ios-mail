//
//  APIServiceResponse.swift
//  ProtonMail - Created on 6/18/15.
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
//
//public class ApiResponse {
//    required public init() {}
//    
//    var code : Int! = 1000
//    var errorMessage : String?
//    var internetCode : Int? //only use when error happend.
//    
//    var error : NSError?
//    
//    func CheckHttpStatus() -> Bool {
//        return code == 200 || code == 1000
//    }
//    
//    func CheckBodyStatus () -> Bool {
//        return code == 1000
//    }
//    
//    func ParseResponseError (_ response: [String : Any]) -> Bool {
//        code = response["Code"] as? Int
//        errorMessage = response["Error"] as? String
//        
//        if code == nil {
//            return false
//        }
//        
//        if code != 1000 && code != 1001 {
//            self.error = NSError.protonMailError(code ?? 1000,
//                                                 localizedDescription: errorMessage ?? "",
//                                                 localizedFailureReason: nil,
//                                                 localizedRecoverySuggestion: nil)
//        }
//        return code != 1000 && code != 1001
//    }
//    
//    func ParseHttpError (_ error: NSError, response: [String : Any]? = nil) {//TODO::need refactor.
//        self.code = 404
//        if let detail = error.userInfo["com.alamofire.serialization.response.error.response"] as? HTTPURLResponse {
//            self.code = detail.statusCode
//        }
//        else {
//            internetCode = error.code
//            self.code = internetCode
//        }
//        self.errorMessage = error.localizedDescription
//        self.error = error
//    }
//    
//    func ParseResponse (_ response: [String : Any]) -> Bool {
//        return true
//    }
//}
