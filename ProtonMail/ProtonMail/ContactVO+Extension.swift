//
//  ContactVOExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


extension ContactVO {
    
    /**
    ContactVO extension for check is contactVO contained by a array of Address

    :param: addresses check addresses
    
    :returns: true | false
    */
    func isDuplicated(_ addresses : [Address]) -> Bool
    {
        if addresses.map({ $0.email }).index(of: self.email) != nil {
            return true
        }
        return false
    }
    
    func isDuplicatedWithContacts(_ addresses : [ContactVO]) -> Bool
    {
        if addresses.map({ $0.email }).index(of: self.email) != nil {
            return true
        }
        return false
    }
}
