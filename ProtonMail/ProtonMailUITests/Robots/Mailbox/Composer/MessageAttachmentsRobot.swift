//
//  AttachmentsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 18.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import pmtest

fileprivate struct id {
    static let addButtonIdentifier = "AttachmentsTableViewController.addButton"
    static let doneButtonIdentifier = "AttachmentsTableViewController.doneButton"
    static let photoLibraryButtonIdentifier = LocalString._photo_library
}

/**
 Represents Composer view.
*/
class MessageAttachmentsRobot: CoreElements {
    
    func photoLibrary() -> ImageGalleryRobot {
        button(id.photoLibraryButtonIdentifier).tap()
        return ImageGalleryRobot()
    }
    
    func add() -> MessageAttachmentsRobot {
        button(id.addButtonIdentifier).waitForHittable().tap()
        return self
    }
    
    func done() -> ComposerRobot {
        button(id.doneButtonIdentifier).tap()
        return ComposerRobot()
    }
}
