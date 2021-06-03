//
//  CountrySelectorRobot.swift
//  SampleAppUITests
//
//  Created by Greg on 22.04.21.
//

import Foundation
import PMTestAutomation

private let backtButtonName = "Back"
private let tableViewId = "CountryPickerViewController.tableView"
private let searchId = "CountryPickerViewController.searchBar"
private let cellId = "CountryCodeTableViewCell.Switzerland"

public final class CountrySelectorRobot: CoreElements {

    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func countrySelectorScreenIsShown() -> CountrySelectorRobot {
            otherElement(searchId).wait().checkExists()
            return CountrySelectorRobot()
        }
    }
    
    public func insertCountryName(name: String) -> CountrySelectorRobot {
        otherElement(searchId).tap().typeText(name)
        return self
    }
    
    public func selectTopCountry() -> RecoveryRobot {
        cell(cellId).tap()
        return RecoveryRobot()
    }
}
