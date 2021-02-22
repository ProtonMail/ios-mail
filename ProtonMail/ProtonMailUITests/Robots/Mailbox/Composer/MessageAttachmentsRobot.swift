//
//  AttachmentsRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 18.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest

fileprivate let addButtonIdentifier = "AttachmentsTableViewController.addButton"
fileprivate let doneButtonIdentifier = "AttachmentsTableViewController.doneButton"
fileprivate let photoLibraryButtonIdentifier = LocalString._photo_library

/**
 Represents Composer view.
*/
class MessageAttachmentsRobot {
    
    var verify: Verify! = nil
    init() { verify = Verify(parent: self) }
    
    func photoLibrary() -> ImageGalleryRobot {
        Element.button.tapByIdentifier(photoLibraryButtonIdentifier)
        return ImageGalleryRobot()
    }
    
    func add() -> MessageAttachmentsRobot {
        Element.wait.forHittableButton(addButtonIdentifier, file: #file, line: #line).tap()
        return self
    }
    
    func done() -> ComposerRobot {
        Element.wait.forButtonWithIdentifier(doneButtonIdentifier).tap()
        return ComposerRobot()
    }
    
    /**
     Contains all the validations that can be performed by ComposerRobot.
    */
    class Verify {
        unowned let attachmentsRobot: MessageAttachmentsRobot
        init(parent: MessageAttachmentsRobot) { attachmentsRobot = parent }
    }
}


