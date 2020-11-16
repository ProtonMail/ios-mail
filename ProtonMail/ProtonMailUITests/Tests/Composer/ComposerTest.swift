//
//  ComposerTest.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

class ComposerTests: BaseTestCase {
    
    func testSendMessageToInternalContact() {
        let user = TestUser.testUserOne
        let subject = ""
        
        LoginRobot().loginUser(user.email, user.password)
            .compose()
            .sendMessage(to: user.email, subject: subject)
            .menuDrawer()
            .sent()
            .verify.messageWithSubjectExists(subject)
    }
}
