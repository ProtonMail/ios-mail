//
//  ImageGalleryRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 21.09.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import Foundation
import fusion

fileprivate struct id {
    static let addButtonIdentifier = "Add"
}

/**
 Represents Composer view.
*/
class ImageGalleryRobot: CoreElements {
    
    func pickImages(_ attachmentsAmount: Int) -> ComposerRobot {
        app.tap() /// Workaround to trigger handleInterruption() on Photos permission alert
        return pickImageAtPositions(attachmentsAmount)
            .confirmSelection()
    }

    private func pickImageAtPositions(_ positions: Int) -> ImageGalleryRobot {
        /// Start from image 1 as image on position 0 is 9MB and it takes longer time to upload.
        for i in 1...positions {
            image(NSPredicate(format: "label BEGINSWITH 'Photo'")).byIndex(i).tap()
        }
        return self
    }

    private func confirmSelection() -> ComposerRobot {
        navigationBar("Photos").onChild(button("Add")).tap()
        return ComposerRobot()
    }
}
