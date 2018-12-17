//
//  MessageDataService+Error.swift
//  ProtonMail - Created on 4/12/18.
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


extension MessageDataService {
    enum RuntimeError : String, Error, CustomErrorVar {
        case cant_decrypt = "can't decrypt message body"
        case bad_draft
        var code: Int {
            get {
                return -1002000
            }
        }
        var desc: String {
            get {
                switch self {
                case .bad_draft:
                    return LocalString.unable_to_send_the_email
                default:
                    break
                }
                return self.rawValue
            }
        }
        var reason: String {
            get {
                switch self {
                case .bad_draft:
                    return LocalString._the_draft_incorrectly_sending_failed
                default:
                    break
                }
                return self.rawValue
            }
        }
    }
}
