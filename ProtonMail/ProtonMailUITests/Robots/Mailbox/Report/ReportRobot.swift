//
//  ReportRobot.swift
//  ProtonMailUITests
//
//  Created by mirage chung on 2020/12/11.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let sendButtonIdentifier = LocalString._general_send_action
fileprivate let bugDescriptionStaticTextIdentifier = "ReportBugsViewController.topTitleLabel"
fileprivate let bugDescriptionTextViewIdentifier = "ReportBugsViewController.textView"
fileprivate let menuButtonIdentifier = LocalString._menu_button
fileprivate let okButtonIdentifier = LocalString._general_ok_action
fileprivate let titleStaticTextIdentifier = LocalString._menu_bugs_title

class ReportRobot {
    
    init() {
        let label = LocalString._menu_bugs_title
        Element.wait.forStaticTextFieldWithIdentifier(titleStaticTextIdentifier, file: #file, line: #line).assertWithLabel(label)
        Element.wait.forStaticTextFieldWithIdentifier(bugDescriptionStaticTextIdentifier, file: #file, line: #line)
        Element.wait.forButtonWithIdentifier(sendButtonIdentifier, file: #file, line: #line)
    }
    
    func menu() -> MenuRobot {
        Element.wait.forButtonWithIdentifier(menuButtonIdentifier, file: #file, line: #line).tap()
        return MenuRobot()
    }
    
    @discardableResult
    func sendBugReport(_ description: String) -> MailboxRobotInterface {
        fileBugDescription(description)
            .send()
            .clickOK()
    }
    
    func fileBugDescription(_ description: String) -> ReportRobot {
        Element.textView.typeTextByIdentifier(bugDescriptionTextViewIdentifier, description)
        return ReportRobot()
    }
    
    func send() -> ReportDialogRobot {
        Element.wait.forHittableButton(sendButtonIdentifier, file: #file, line: #line).tap()
        return ReportDialogRobot()
    }
    
    class ReportDialogRobot {

        func clickOK() -> MailboxRobotInterface {
            Element.button.tapByIdentifier(okButtonIdentifier)
            return MailboxRobotInterface()
        }
    }
}
