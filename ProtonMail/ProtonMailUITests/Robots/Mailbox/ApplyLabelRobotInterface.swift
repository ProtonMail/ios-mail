//
//  ApplyLabelRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

/**
 Parent class for applying Label in all the Mailbox Robot classes like Inbox, Sent, Trash, etc.
*/
class ApplyLabelRobotInterface {
    
    func labelName(name: String) -> ApplyLabelRobotInterface {
        //TODO:: add implementation
        return self
    }

    func selectExistingByName(name: String) -> ApplyLabelRobotInterface {
       //TODO:: add implementation
       return self
   }

    func selectAlsoArchive() -> ApplyLabelRobotInterface {
       //TODO:: add implementation
       return self
   }

    func apply() -> ApplyLabelRobotInterface {
       //TODO:: add implementation
       return self
   }
}
