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
    
    override func getPickedType() -> String {
        return typeInterface.getCurrentType()
    }

    override func getDefinedTypes() -> [String] {
        return typeInterface.types()
    }
    
    override func getCustomType() -> String {
        let type = typeInterface.getCurrentType()
        if type != "" {
            let types = getDefinedTypes()
            if let _ = types.index(of: type) {

            } else {
                return type
            }
        }
        return ""
    }
    
    override func getSectionType() -> ContactEditSectionType {
        return typeInterface.getSectionType()
    }
    
    override func updateType(t: String) {
        typeInterface.updateType(type: t)
    }
    
}
