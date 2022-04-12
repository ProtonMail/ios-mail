//
//  LoginRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 03.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import ProtonCore_TestingToolkit

extension LoginRobot {

    @discardableResult
    func loginUser(_ user: User) -> InboxRobot {
        return fillUsername(username: user.name)
            .insertPassword(password: user.password)
            .signIn(robot: InboxRobot.self)
    }

    func loginUserWithTwoFA(_ user: User) -> InboxRobot {
        return fillUsername(username: user.name)
            .insertPassword(password: user.password)
            .signIn(robot: TwoFaRobot.self)
            .fillTwoFACode(code: user.getTwoFaCode())
            .confirm2FA(robot: InboxRobot.self)
    }

    func loginTwoPasswordUser(_ user: User) -> InboxRobot {
        return fillUsername(username: user.name)
            .insertPassword(password: user.password)
            .signIn(robot: MailboxPasswordRobot.self)
            .fillMailboxPassword(mailboxPassword: user.mailboxPassword)
            .unlock(robot: InboxRobot.self)
    }

    func loginTwoPasswordUserWithInvalid2Pass(_ user: User) -> MailboxPasswordRobot {
        return fillUsername(username: user.name)
            .insertPassword(password: user.password)
            .signIn(robot: MailboxPasswordRobot.self)
            .fillMailboxPassword(mailboxPassword: "wrong" + user.mailboxPassword)
            .unlock(robot: MailboxPasswordRobot.self)
    }

    func loginTwoPasswordUserWithTwoFA(_ user: User) -> InboxRobot {
        return fillUsername(username: user.name)
            .insertPassword(password: user.password)
            .signIn(robot: TwoFaRobot.self)
            .fillTwoFACode(code: user.getTwoFaCode())
            .confirm2FA(robot: MailboxPasswordRobot.self)
            .fillMailboxPassword(mailboxPassword: user.mailboxPassword)
            .unlock(robot: InboxRobot.self)
    }

    func loginWithInvalidUser(_ user: User) -> LoginRobot {
        let incorrectEmail = "invalid" + user.name
        return fillUsername(username: incorrectEmail)
            .insertPassword(password: user.password)
            .signIn(robot: LoginRobot.self)
    }

    func loginWithInvalidPassword(_ user: User) -> LoginRobot {
        let invalidPassword = "invalid" + user.password
        return fillUsername(username: user.name)
            .insertPassword(password: invalidPassword)
            .signIn(robot: LoginRobot.self)
    }

    func loginWithInvalidUserAndPassword(_ user: User) -> LoginRobot {
        let email = "invalid" + user.name
        let password = "invalid" + user.password
        return fillUsername(username: email)
            .insertPassword(password: password)
            .signIn(robot: LoginRobot.self)
    }
}
