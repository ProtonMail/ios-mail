//
//  BCrypt+Extension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/5/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


func PMNBCrypt (password: String, salt: String) -> String {
    var hash_out : String = ""
    do {
        try ObjC.catchException {
            hash_out = PMNBCryptHash.hashString(password, salt: salt)
        }
    } catch {
        //TODO:: log error
    }
    return hash_out
}
