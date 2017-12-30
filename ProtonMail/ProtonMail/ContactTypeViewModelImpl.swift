//
//  ContactTypeViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


class ContactTypeViewModelImpl : ContactTypeViewModel {
    var typeInterface : ContactEditTypeInterface
    init(t : ContactEditTypeInterface) {
        self.typeInterface = t
    }
    
    override func getPickedType() -> ContactFieldType {
        return typeInterface.getCurrentType()
    }

    override func getDefinedTypes() -> [ContactFieldType] {
        return typeInterface.types()
    }
    
    override func getCustomType() -> ContactFieldType {
        let type = typeInterface.getCurrentType()
        let types = getDefinedTypes()
        if let _ = types.index(of: type) {
            
        } else {
            return type
        }
        return .empty
    }
    
    override func getSectionType() -> ContactEditSectionType {
        return typeInterface.getSectionType()
    }
    
    override func updateType(t: ContactFieldType) {
        typeInterface.updateType(type: t)
    }
    
}
