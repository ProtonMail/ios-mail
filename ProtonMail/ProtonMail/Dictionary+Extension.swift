//
//  DictionaryExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 7/2/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

extension Dictionary where Key: ExpressibleByStringLiteral, Value: ExpressibleByStringLiteral { //email name
    public func getDisplayName() -> String {    //this function only for the To CC BCC list parsing
        if let key = "Name" as? Key {
            let name = self[key] as? String ?? ""
            if !name.isEmpty {
                return name
            }
        }
        if let key = "Address" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }
    
    public func getAddress() -> String {    //this function only for the To CC BCC list parsing
        if let key = "Address" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }
    
    public func getName() -> String {    //this function only for the To CC BCC list parsing
        if let key = "Name" as? Key {
            return self[key] as? String ?? ""
        }
        return ""
    }
}

