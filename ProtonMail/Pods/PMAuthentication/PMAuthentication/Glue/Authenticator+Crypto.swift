//
//  Authenticator+Crypto.swift
//  PMAuthentication
//
//  Created by Anatoly Rosencrantz on 11/03/2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation
import Crypto

/* IMPORTANT: this file adds explicit dependency on Crypto framework, do not add this file to SPM sources */

public typealias Authenticator = GenericAuthenticator<Crypto.SrpAuth, Crypto.SrpProofs>

extension SrpProofs: SrpProofsProtocol {}

extension SrpAuth: SrpAuthProtocol {
    public func generateProofs(of length: Int) throws -> AnyObject {
        return try self.generateProofs(length)
    }
}
