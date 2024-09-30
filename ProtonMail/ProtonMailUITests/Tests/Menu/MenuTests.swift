//
//  MenuTests.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 18.11.20.
//  Copyright © 2020 Proton Mail. All rights reserved.
//

import ProtonCoreTestingToolkitUITestsLogin

class MenuTests: FixtureAuthenticatedTestCase {
    
    func testSaveSpecialCharacterDisplayName() {
        let emoji = "😀"
        let randomString = StringUtils().randomAlphanumericString()
        let newDisplayName = "\(emoji)\(testData.onePassUser.name)\(randomString)"

        runTestWithScenario(.qaMail001) {
            InboxRobot()
                .menuDrawer()
                .settings()
                .selectAccount(user.dynamicDomainEmail)
                .displayName()
                .setDisplayNameTextTo(newDisplayName)
                .save()
                .navigateBackToSettings()
                .close()
                .menuDrawer()
                .accountsList()
                .verify.accountShortNameIsCorrect(emoji)
        }
    }

    
    func testSaveTwoWordsDisplayName() {
        let randomString = StringUtils().randomAlphanumericString()
        let newDisplayName = "\(testData.onePassUser.name) \(randomString)"
        let shortName = "\(newDisplayName.prefix(1))\(randomString.prefix(1))".uppercased()

        runTestWithScenario(.qaMail001) {
            let menuAccountListRobot = InboxRobot()
                .menuDrawer()
                .settings()
                .selectAccount(user.email)
                .displayName()
                .setDisplayNameTextTo(newDisplayName)
                .save()
                .navigateBackToSettings()
                .close()
                .menuDrawer()
                .accountsList()

            menuAccountListRobot
                .verify.accountShortNameIsCorrect(shortName.uppercased())

            menuAccountListRobot
                .dismiss()
                .settings()
                .selectAccount(user.email)
                .displayName()
                .setDisplayNameTextTo(user.name)
                .save()
                .navigateBackToSettings()
                .close()
                .menuDrawer()
                .accountsList()
                .verify.accountShortNameIsCorrect(user.name)
        }
    }
}
