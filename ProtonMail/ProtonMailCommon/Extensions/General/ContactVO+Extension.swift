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
    
    /**
     Checks if the current ContactVO is in the address list
    */
    func isDuplicatedWithContacts(_ addresses : [ContactPickerModelProtocol]) -> Bool
    {
        if addresses.map({
            if let contact = $0 as? ContactVO {
                return contact.email
            } else {
                return nil
            }
        }).index(of: self.email) != nil {
            return true
        }
        return false
    }
}
