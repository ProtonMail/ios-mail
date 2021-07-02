//
//  TCRobot.swift
//  SampleAppUITests
//
//  Created by Greg on 21.04.21.
//

import Foundation
import pmtest
import ProtonCore_CoreTranslation

private let titleId = CoreString._su_terms_conditions_view_title
private let backtButtonId = "UINavigationItem.leftBarButtonItem"
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
        button(backtButtonId).hasLabel("Close").tap()
        return RecoveryRobot()
    }
    
}
