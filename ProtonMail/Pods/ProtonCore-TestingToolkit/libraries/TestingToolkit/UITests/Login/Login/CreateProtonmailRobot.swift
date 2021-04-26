//
//  CreateProtonmailRobot.swift
//  SampleAppUITests
//
//  Created by Kristina Jureviciute on 2021-05-07.
//


import PMTestAutomation

private let createProtonmailTitleId = "ChooseUsernameViewController.titleLabel"
private let usernameFieldId = "ChooseUsernameViewController.addressTextField.textField"
private let buttonNextId = "ChooseUsernameViewController.nextButton"
private let buttonCreateAddressId = "CreateAddressViewController.createButton"


public final class CreateProtonmailRobot: CoreElements {
    
    public func fillPMUsername(username: String )  -> CreateProtonmailRobot {
        textField(usernameFieldId).wait().tap().typeText(username)
        return self
    }
    
    public func pressNextButton() -> CreateProtonmailRobot {
        button(buttonNextId).tap()
        return self
    }
    
    public func pressCreateAddress<Robot: CoreElements>(to: Robot.Type) -> Robot {
        button(buttonCreateAddressId).wait().tap()
        return Robot()
    }
}
