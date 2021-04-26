//
//  File.swift
//  PMTestAutomation
//
//  Created by denys zelenchuk on 02.02.21.
//

import Foundation
import XCTest

private let app = XCUIApplication()

/**
 XCUIElement extensions that help to simplify the test syntax and keep it more compact.
 */
extension XCUIElement {

    /**
     Deletes text value from text field.
     */
    @discardableResult
    func clearText() -> XCUIElement {
        guard let stringValue = self.value as? String else {
            XCTFail("clear() text method was used on a field that is not textField.")
            return self
        }
        let delete: String = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(delete)
        return self
    }

    func child(_ childElement: UiElement) -> XCUIElement {
        return Wait().forElement(self.children(matching: childElement.getType()).element(matching: childElement.getType(), identifier: childElement.getIdentifier()))
    }

    func descendant(_ descendantElement: UiElement) -> XCUIElement {
        return Wait().forElement(self.descendants(matching: descendantElement.getType()).element(matching: descendantElement.getType(), identifier: descendantElement.getIdentifier()))
    }
}
