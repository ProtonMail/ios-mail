//
//  UIElement+iOSExtension.swift
//  fusion
//
//  Created by Robert Patchett on 11.10.22.
//

#if os(iOS)
import XCTest

extension UIElement {

    public func focused() -> Bool {
        guard let element = uiElement() else {
            return false
        }
        return element.hasFocus
    }

    public func adjust(to value: String) -> UIElement {
        uiElement()!.adjust(toPickerWheelValue: "\(value)")
        return self
    }

    @discardableResult
    public func pinch(scale: CGFloat, velocity: CGFloat) -> UIElement {
        uiElement()!.pinch(withScale: scale, velocity: velocity)
        return self
    }

    @discardableResult
    public func twoFingerTap(scale: CGFloat, velocity: CGFloat) -> UIElement {
        uiElement()!.twoFingerTap()
        return self
    }

    @discardableResult
    public func typeText(_ text: String) -> UIElement {
        uiElement()!.typeText(text)
        return self
    }

    @discardableResult
    public func tap(withNumberOfTaps numberOfTaps: Int, numberOfTouches: Int) -> UIElement {
        uiElement()!.tap(withNumberOfTaps: numberOfTaps, numberOfTouches: numberOfTouches)
        return self
    }
}
#endif
