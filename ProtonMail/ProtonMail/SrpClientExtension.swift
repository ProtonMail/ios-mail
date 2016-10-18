//
//  SrpClientExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/18/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



func generateSrpProofs (bit : Int32, modulus: NSData, serverEphemeral: NSData, hashedPassword :NSData) throws -> PMNSrpProofs? {
    
    var error : NSError?
    var dec_out_att : PMNSrpProofs?
    SwiftTryCatch.tryBlock({ () -> Void in
        dec_out_att = PMNSrpClient.generateProofs(bit, modulusRepr: modulus, serverEphemeralRepr: serverEphemeral, hashedPasswordRepr: hashedPassword)
        }, catchBlock: { (exc) -> Void in
            error = exc.toError()
    }) { () -> Void in
    }
    if error == nil {
        return dec_out_att
    } else {
        throw error!
    }
}


extension PMNSrpProofs {
    func isValid() -> Bool {
        guard self.clientEphemeral.length > 0 && self.clientProof.length > 0 && self.expectedServerProof.length > 0  else {
            return false
        }
        return true
    }
}