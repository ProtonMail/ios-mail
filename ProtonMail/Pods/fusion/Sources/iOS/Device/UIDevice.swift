//
//  UIDevice.swift
//
//  ProtonMail - Created on 02.07.21.
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
import UIKit
import XCTest

public enum ForegroundType {
    case activate
    case launch
}

@available(*, deprecated, message: "`UiDevice` has been renamed to `UIDevice`.")
typealias UiDevice = UIDevice

/**
 Contains functions related to the device or system actions.
 */
open class UIDevice {

    public func backgroundApp(app: XCUIApplication = XCUIApplication()) {
        XCUIDevice.shared.press(.home)
        app.wait(for: .runningBackground, timeout: 5.0)
    }

    public func foregroundApp(_ foregroundType: ForegroundType = ForegroundType.activate, app: XCUIApplication = XCUIApplication()) {
        switch foregroundType {
        case .activate:
            app.activate()
        case .launch:
            app.launch()
        }
        app.wait(for: .runningForeground, timeout: 5.0)
    }

    public func foregroundAppBySiri(_ text: String, app: XCUIApplication = XCUIApplication()) {
        XCUIDevice.shared.siriService.activate(voiceRecognitionText: text)
        app.wait(for: .runningForeground, timeout: 5.0)
    }

    public func saveTextToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }

    public func saveImageToClipboard(_ image: UIImage) {
        UIPasteboard.general.image = image
    }

    public func saveUrlToClipboard(_ url: URL) {
        UIPasteboard.general.url = url
    }
}
#endif
