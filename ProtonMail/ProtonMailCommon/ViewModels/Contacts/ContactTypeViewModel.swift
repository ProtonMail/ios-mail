//
//  ContactTypeViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


class ContactTypeViewModel {
    
    public init() { }
    
    func getDefinedTypes() -> [ContactFieldType] {
        fatalError("This method must be overridden")
    }
    
    func getCustomType() -> ContactFieldType {
        fatalError("This method must be overridden")
    }
    
    func getPickedType() -> ContactFieldType {
        fatalError("This method must be overridden")
    }
    
    func getSectionType() -> ContactEditSectionType {
        fatalError("This method must be overridden")
    }
    
    func updateType(t : ContactFieldType) {
        fatalError("This method must be overridden")
    }
}
