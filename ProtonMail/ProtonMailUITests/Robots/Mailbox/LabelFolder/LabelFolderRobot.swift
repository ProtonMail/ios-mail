//
//  LabelFolderRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 13.11.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

fileprivate let labelNavBarButtonIdentifier = "UINavigationItem.topLabelButton"
fileprivate let folderNavBarButtonIdentifier = "UINavigationItem.topFolderButton"
fileprivate let trashNavBarButtonIdentifier = "UINavigationItem.topTrashButton"
fileprivate let moreNavBarButtonIdentifier = "UINavigationItem.topMoreButton"

/*
 LabelFolderRobot class implements MailboxRobotInterface, contains actions and verifications for Labels or Folders mailbox functionality.
 */
class LabelFolderRobot : MailboxRobotInterface {

    var verify: Verify! = nil
    
    override init() {
        super.init()
        verify = Verify()
    }
    
    /**
     * Contains all the validations that can be performed by [LabelFolderRobot].
     */
    class Verify: MailboxRobotVerifyInterface {}
}
