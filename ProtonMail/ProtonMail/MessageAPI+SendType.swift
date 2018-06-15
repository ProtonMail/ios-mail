//
//  MessageAPI+SendType.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


struct SendType : OptionSet {
    let rawValue: Int
    
    //address package one
    
    //internal email
    static let intl    = SendType(rawValue: 1 << 0)
    //encrypt outside
    static let eo      = SendType(rawValue: 1 << 1)
    //cleartext inline
    static let cinln   = SendType(rawValue: 1 << 2)
    //inline pgp
    static let inlnpgp = SendType(rawValue: 1 << 3)
    
    //address package two MIME
    
    //pgp mime
    static let pgpmime = SendType(rawValue: 1 << 4)
    //clear text mime
    static let cmime   = SendType(rawValue: 1 << 5)
    
}
