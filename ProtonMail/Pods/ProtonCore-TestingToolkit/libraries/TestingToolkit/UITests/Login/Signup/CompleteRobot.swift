//
//  CompleteRobot.swift
//  SampleAppUITests
//
//  Created by Greg on 18.04.21.
//

import Foundation
import pmtest

private let titleId = "CompleteViewController.completeTitleLabel"
private let descriptionId = "CompleteViewController.completeDescriptionLabel"

public final class CompleteRobot: CoreElements {

    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func completeScreenIsShown<T: CoreElements>(robot _: T.Type) -> T {
            staticText(titleId).wait().checkExists()
            staticText(descriptionId).checkExists()
            return T()
        }
    }
}
