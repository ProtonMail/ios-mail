//
//  TCRobot.swift
//  SampleAppUITests
//
//  Created by Greg on 21.04.21.
//

import Foundation
import pmtest

private let titleId = "TCViewController.titleLabel"
private let backtButtonId = "TCViewController.closeButton"
private let webViewId = "TCViewController.webView"

public final class TCRobot: CoreElements {
    
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func tcScreenIsShown() -> TCRobot {
            staticText(titleId).wait().checkExists()
            return TCRobot()
        }
    }
    
    public func swipeUpWebView() -> TCRobot {
        webView(webViewId).swipeUp()
        return self
    }
    
    public func backButton() -> RecoveryRobot {
        button(backtButtonId).tap()
        return RecoveryRobot()
    }
    
}
