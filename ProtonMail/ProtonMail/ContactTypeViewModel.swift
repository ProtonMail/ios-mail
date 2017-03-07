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
    
    func getDefinedTypes() -> [String] {
        fatalError("This method must be overridden")
    }
    
    func getCustomType() -> String {
        fatalError("This method must be overridden")
    }
    
    func getPickedType() -> String {
        fatalError("This method must be overridden")
    }
    
    func getSectionType() -> ContactEditSectionType {
        fatalError("This method must be overridden")
    }
    
    func updateType(t : String) {
        fatalError("This method must be overridden")
    }
}
