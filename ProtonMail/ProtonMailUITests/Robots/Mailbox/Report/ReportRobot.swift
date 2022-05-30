//
//  ReportRobot.swift
//  Proton MailUITests
//
//  Created by mirage chung on 2020/12/11.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import pmtest

fileprivate struct id {
    static let sendButtonIdentifier = LocalString._general_send_action
    static let bugDescriptionStaticTextIdentifier = "ReportBugsViewController.topTitleLabel"
    static let bugDescriptionTextViewIdentifier = "ReportBugsViewController.textView"
    static let menuButtonIdentifier = LocalString._menu_button
    static let okButtonIdentifier = LocalString._general_ok_action
    static let titleStaticTextIdentifier = LocalString._menu_bugs_title
}

class ReportRobot: CoreElements {
    
    required init() {
        super.init()
        //let label = LocalString._menu_bugs_title
        navigationBar(id.titleStaticTextIdentifier).onChild(staticText(id.titleStaticTextIdentifier)).byIndex(0).wait().checkExists()
        textView(id.bugDescriptionTextViewIdentifier).wait().checkExists()
        button(id.sendButtonIdentifier).wait().checkExists()
    }
    
    func menu() -> MenuRobot {
        button(id.menuButtonIdentifier).tap()
        return MenuRobot()
    }
    
    @discardableResult
    func sendBugReport(_ description: String) -> MailboxRobotInterface {
        fileBugDescription(description)
            .send()
            .clickOK()
    }
    
    func fileBugDescription(_ description: String) -> ReportRobot {
        textView(id.bugDescriptionTextViewIdentifier).typeText(description)
        return ReportRobot()
    }
    
    @discardableResult
    func send() -> ReportDialogRobot {
        button(id.sendButtonIdentifier).waitForHittable().tap()
        return ReportDialogRobot()
    }
    
    class ReportDialogRobot: CoreElements {

        func clickOK() -> MailboxRobotInterface {
            button(id.okButtonIdentifier).tap()
            return MailboxRobotInterface()
        }
    }
}
