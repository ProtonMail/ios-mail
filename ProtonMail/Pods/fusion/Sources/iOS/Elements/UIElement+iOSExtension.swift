//
//  UIElement+iOSExtension.swift
//  fusion
//
//  Created by Robert Patchett on 11.10.22.
//
//  The MIT License
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
