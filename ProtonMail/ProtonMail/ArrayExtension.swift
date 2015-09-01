//
//  ArrayExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/17/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


extension Array {
    func contains<T where T : Equatable>(obj: T) -> Bool {
        return self.filter({$0 as? T == obj}).count > 0
    }
}



extension Array {
    func getAddressOrder <T: Address>() -> Array<String> {
        
        let ids = self.map { ($0 as! Address).address_id }
        
        return ids;
    }
    
    func getAddressNewOrder <T: Address>() -> Array<Int> {
        
        let ids = self.map { ($0 as! Address).send }
        
        return ids;
    }
    
    func updateOrder <T: Address>() -> Array<Int> {
        for var i = 0; i < self.count; ++i {
            var addr = (self[i] as! Address)
        }
        
        let ids = self.map { ($0 as! Address).send }
        
        return ids;
    }
    
}
