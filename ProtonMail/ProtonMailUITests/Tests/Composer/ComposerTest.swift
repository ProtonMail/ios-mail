//
//  ComposerTest.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

class ComposerTests: BaseTestCase {
    
    func testSendMessageToInternalContact() {
        let user = testData.onePassUser
        let subject = ""
        
        LoginRobot().loginUser(user)
            .compose()
            .sendMessage(to: user.email, subjectText: subject)
            .menuDrawer()
            .sent()
            .verify.messageWithSubjectExists(subject)
    }
}
