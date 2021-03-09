//
//  ImageGalleryRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 21.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let imageOtherIdentifier = "DKImageAssetAccessibilityIdentifier"
private func selectButtonIdentifier(_ selectionAmount: Int) -> String { return "Select(\(String(selectionAmount)))" }
/**
 Represents Composer view.
*/
class ImageGalleryRobot {
    
    func pickImages(_ attachmentsAmount: Int) -> MessageAttachmentsRobot {
        app.tap() /// Workaround to trigger handleInterruption() on Photos permission alert
        return pickImageAtPositions(attachmentsAmount)
            .confirmSelection(attachmentsAmount)
    }
    
    private func pickImageAtPositions(_ positions: Int) -> ImageGalleryRobot {
        for i in 0...positions-1 {
            Element.other.tapByIdentifier(imageOtherIdentifier, i)
        }
        return self
    }
    
    private func confirmSelection(_ attachmentsAmount: Int) -> MessageAttachmentsRobot {
        Element.button.tapByIdentifier(selectButtonIdentifier(attachmentsAmount))
        return MessageAttachmentsRobot()
    }
}
