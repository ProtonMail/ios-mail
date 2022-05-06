//
//  AttachmentsRobot.swift
//  Proton MailUITests
//
//  Created by denys zelenchuk on 18.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import pmtest

fileprivate struct id {
    static let fromYourPhotoLibraryText = LocalString._from_your_photo_library
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
    
    func add() -> ImageGalleryRobot {
        cell(id.fromYourPhotoLibraryText).tap()
        return ImageGalleryRobot()
    }
    
    func done() -> ComposerRobot {
        button(id.doneButtonIdentifier).tap()
        return ComposerRobot()
    }
}
