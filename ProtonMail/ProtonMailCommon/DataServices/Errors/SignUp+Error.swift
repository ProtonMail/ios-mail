//
//  SignUp+Error.swift
//  ProtonMail - Created on 12/22/16.
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


// code start at 0x110200
enum SignUpCreateUserError : Int, Error, CustomErrorVar {
    case invalidModulsID = 0x110201
    case invalidModuls = 0x110202
    case cantHashPassword = 0x110203
    case cantGenerateVerifier = 0x110204
    
    case `default` = 0x110200
    
    var code : Int {
        return self.rawValue
    }
    
    var desc : String {
        return LocalString._update_notification_email
    }
    
    var reason : String {
        switch self {
        case .invalidModulsID:
            return LocalString._cant_get_a_moduls_id
        case .invalidModuls:
            return LocalString._cant_get_a_moduls
        case .cantHashPassword:
            return LocalString._invalid_hashed_password
        case .cantGenerateVerifier:
            return LocalString._cant_create_a_srp_verifier
        case .default:
            return LocalString._create_user_failed
        }
    }
}
