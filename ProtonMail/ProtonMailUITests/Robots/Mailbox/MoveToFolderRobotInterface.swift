//
//  MoveToFolderRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

/**
 Parent class for applying Label in all the Mailbox Robot classes like Inbox, Sent, Trash, etc.
*/
class MoveToFolderRobotInterface {
    
    func moveToExistingFolder(name: String) -> MoveToFolderRobotInterface {
        //TODO:: add implementation
        return self
    }

    func createFolder() {
        //TODO:: add implementation
    }
}
