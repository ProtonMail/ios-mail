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


func generateSrpProofs (_ bit : Int32, modulus: Data, serverEphemeral: Data, hashedPassword :Data) throws -> PMNSrpProofs? {
    var dec_out_att : PMNSrpProofs?
    try ObjC.catchException {
        dec_out_att = PMNSrpClient.generateProofs(bit, modulusRepr: modulus, serverEphemeralRepr: serverEphemeral, hashedPasswordRepr: hashedPassword)
    }
    
    return dec_out_att
}

func generateVerifier (_ bit : Int32, modulus: Data, hashedPassword :Data) throws -> Data? {
    var data_out : Data?
    try ObjC.catchException {
        data_out = PMNSrpClient.generateVerifier(bit, modulusRepr: modulus, hashedPasswordRepr: hashedPassword)
    }
    
    return data_out
}


extension PMNSrpProofs {
    func isValid() -> Bool {
        guard self.clientEphemeral.count > 0 && self.clientProof.count > 0 && self.expectedServerProof.count > 0  else {
            return false
        }
        return true
    }
}
