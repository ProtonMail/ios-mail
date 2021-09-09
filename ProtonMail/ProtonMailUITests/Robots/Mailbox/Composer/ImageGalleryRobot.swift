//
//  ImageGalleryRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 21.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let imageOtherIdentifier = "DKImageAssetAccessibilityIdentifier"
    static func selectButtonIdentifier(_ selectionAmount: Int) -> String { return "Select(\(String(selectionAmount)))" }
}

/**
 Represents Composer view.
*/
class ImageGalleryRobot: CoreElements {
    
    func pickImages(_ attachmentsAmount: Int) -> MessageAttachmentsRobot {
        app.tap() /// Workaround to trigger handleInterruption() on Photos permission alert
        return pickImageAtPositions(attachmentsAmount)
            .confirmSelection(attachmentsAmount)
    }
    
    private func pickImageAtPositions(_ positions: Int) -> ImageGalleryRobot {
        for i in 0...positions-1 {
            otherElement(id.imageOtherIdentifier).byIndex(i).tap()
        }
        return self
    }
    
    private func confirmSelection(_ attachmentsAmount: Int) -> MessageAttachmentsRobot {
        button(id.selectButtonIdentifier(attachmentsAmount)).tap()
        return MessageAttachmentsRobot()
    }
}
