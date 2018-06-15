//
//  SrpClientExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/18/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

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
