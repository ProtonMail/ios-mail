//
//  MenuTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 18.11.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

class MenuTests : BaseTestCase {

    private let loginRobot = LoginRobot()
    
    func testSaveSpecialCharacterDisplayName() {
        let emoji = "😀"
        let randomString = StringUtils().randomAlphanumericString()
        let newDisplayName = "\(emoji)\(testData.onePassUser.name)\(randomString)"
        
        loginRobot
            .loginUser(testData.onePassUser)
            .menuDrawer()
            .settings()
            .selectAccount(testData.onePassUser.email)
            .displayName()
            .setDisplayNameTextTo(newDisplayName)
            .save()
            .navigateBackToSettings()
            .menuDrawer()
            .accountsList()
            .verify.accountShortNameIsCorrect(testData.onePassUser, emoji)
    }
    
    func testSaveTwoWordsDisplayName() {
        let randomString = StringUtils().randomAlphanumericString()
        let newDisplayName = "\(testData.onePassUser.name) \(randomString)"
        let shortName = "\(newDisplayName.prefix(1))\(randomString.prefix(1))".uppercased()
        
        loginRobot
            .loginUser(testData.onePassUser)
            .menuDrawer()
            .settings()
            .selectAccount(testData.onePassUser.email)
            .displayName()
            .setDisplayNameTextTo(newDisplayName)
            .save()
            .navigateBackToSettings()
            .menuDrawer()
            .accountsList()
            .verify.accountShortNameIsCorrect(testData.onePassUser, shortName.uppercased())
    }
}
