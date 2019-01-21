//
//  SrpClientExtension.swift
//  ProtonMail - Created on 10/18/16.
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
import Srp


func SrpAuth(_ hashVersion: Int, _ userName: String, _ password: String,
              _ salt: String, _ signedModulus: String, _ serverEphemeral: String) throws -> SrpAuth? {
    var error : NSError?
    let outAuth = SrpNewAuth(hashVersion, userName, password, salt, signedModulus, serverEphemeral, &error)
    if let err = error {
        throw err
    }
    return outAuth
}

func SrpAuthForVerifier(_ password: String, _ signedModulus: String, _ rawSalt: Data) throws -> SrpAuth? {
    var error : NSError?
    let outAuth = SrpNewAuthForVerifier(password, signedModulus, rawSalt, &error)
    if let err = error {
        throw err
    }
    return outAuth
}

extension PMNSrpProofs {
    func isValid() -> Bool {
        guard self.clientEphemeral.count > 0 && self.clientProof.count > 0 && self.expectedServerProof.count > 0  else {
            return false
        }
        return true
    }
}
