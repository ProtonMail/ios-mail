//
//  SelectionStateRobotProtocol.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 23.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

/**
 Parent class for selection state of Mailbox Robot classes like Inbox, Sent, Trash, etc.
*/
class SelectionStateRobotInterface {
    
    func exitMessageSelectionState() -> SelectionStateRobotInterface {
        //TODO:: add implementation
        return self
    }

    func openMoreOptions() -> SelectionStateRobotInterface {
        //TODO:: add implementation
        return self
    }

    func addLabel() -> SelectionStateRobotInterface {
        //TODO:: add implementation
        return self
    }

    func addFolder() -> SelectionStateRobotInterface {
        //TODO:: add implementation
        return self
    }

    func selectMessage(position: Int) -> SelectionStateRobotInterface {
        //TODO:: add implementation
        return self
    }
}
