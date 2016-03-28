//
//  GeneralSettingViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/19/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

protocol SettingDetailsViewModel {
    
    func getNavigationTitle() -> String
    func getTopHelpText() ->String
    func getSectionTitle() -> String
    func isDisplaySwitch() -> Bool
    func getSwitchText() -> String
    func getSwitchStatus() -> Bool
    func isShowTextView() -> Bool
    func getPlaceholdText() -> String
    
    func getCurrentValue() -> String
    func updateValue(new_value: String, complete:(Bool, NSError?) -> Void)
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void)
    
    func isSwitchEnabled() -> Bool
    func isTextEnabled() -> Bool
}


class SettingDetailsViewModelTest : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return "Navigation Title - Test"
    }
    
    func getTopHelpText() -> String {
        return "this is description - Test"
    }
    
    func getSectionTitle() -> String {
        return "Section Title - Test"
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return "Enable - Test"
    }
    
    func getSwitchStatus() -> Bool {
        return true
    }
    
    func isShowTextView() -> Bool {
        return true
    }
    
    func getPlaceholdText() -> String {
        return "Please input ... - Test"
    }
    
    func getCurrentValue() -> String {
        return "test value"
    }
    
    func updateValue(new_value: String, complete: (Bool, NSError?) -> Void) {
        complete(true, nil)
    }
    
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void) {
        complete(true, nil)
    }
    
    func isSwitchEnabled() -> Bool {
        return true
    }
    func isTextEnabled() -> Bool{
        return true
    }
}



class ChangeDisplayNameViewModel : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return "DisplayName"
    }
    
    func getTopHelpText() -> String {
        return "What people see in the \"From\" field."
    }
    
    func getSectionTitle() -> String {
        return "DISPLAY NAME"
    }
    
    func isDisplaySwitch() -> Bool {
        return false
    }
    
    func getSwitchText() -> String {
        return ""
    }
    
    func getSwitchStatus() -> Bool {
        return true
    }

    func isShowTextView() -> Bool {
        return false
    }
    
    func getPlaceholdText() -> String {
        return "Input Display Name ..."
    }
    
    func getCurrentValue() -> String {
        return sharedUserDataService.displayName
    }
    
    func updateValue(new_value: String, complete: (Bool, NSError?) -> Void) {
        sharedUserDataService.updateDisplayName(new_value) { _, error in
            if let error = error {
                 complete(false, error)
            } else {
                complete(true, nil)
            }
        }
    }
    
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void) {
        complete(true, nil)
    }
    func isSwitchEnabled() -> Bool {
        return true
    }
    func isTextEnabled() -> Bool {
        return true
    }
}


class ChangeSignatureViewModel : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return "Signature"
    }
    
    func getTopHelpText() -> String {
        return "Email default signature"
    }
    
    func getSectionTitle() -> String {
        return "SIGNATURE"
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return "Enable Default Signature"
    }
    
    func getSwitchStatus() -> Bool {
        return sharedUserDataService.showDefaultSignature
    }

    func isShowTextView() -> Bool {
        return true
    }
    
    func getPlaceholdText() -> String {
        return ""
    }
    
    func getCurrentValue() -> String {
        return sharedUserDataService.signature
    }
    
    func updateValue(new_value: String, complete: (Bool, NSError?) -> Void) {
        sharedUserDataService.updateSignature(new_value) { _, error in
            if let error = error {
                complete(false, error)
            } else {
                complete(true, nil)
            }
        }
    }
    
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void) {
        sharedUserDataService.showDefaultSignature = isOn
        complete(true, nil)
    }
    
    func isSwitchEnabled() -> Bool {
        return true
    }
    func isTextEnabled() -> Bool {
        return true
    }
}

class ChangeMobileSignatureViewModel : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return "Mobile Signature"
    }
    
    func getTopHelpText() -> String {
        return "Only plus user could modify default mobile signature or turn it off!"
    }
    
    func getSectionTitle() -> String {
        return "Mobile Signature"
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return "Enable Mobile Signature"
    }
    
    func getSwitchStatus() -> Bool {
        return sharedUserDataService.showMobileSignature
    }
    
    func isShowTextView() -> Bool {
        return true
    }
    
    func getPlaceholdText() -> String {
        return ""
    }
    
    func getCurrentValue() -> String {
        return sharedUserDataService.mobileSignature
    }
    
    func updateValue(new_value: String, complete: (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
            complete(true, nil)
        } else {
            sharedUserDataService.mobileSignature = new_value
            complete(true, nil)
        }
    }
    
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void) {
        if isOn == getSwitchStatus() {
            complete(true, nil)
        } else {
            sharedUserDataService.showMobileSignature = isOn
            complete(true, nil)
        }
    }
    func isSwitchEnabled() -> Bool {
        return sharedUserDataService.userInfo?.role > 0
    }
    func isTextEnabled() -> Bool {
        return sharedUserDataService.userInfo?.role > 0
    }
}


class ChangeNotificationEmailViewModel : SettingDetailsViewModel{
    func getNavigationTitle() -> String {
        return "Notification Email"
    }
    
    func getTopHelpText() -> String {
        return "Also used to reset a forgotten password."
    }
    
    func getSectionTitle() -> String {
        return "Notification / Recovery Email"
    }
    
    func isDisplaySwitch() -> Bool {
        return true
    }
    
    func getSwitchText() -> String {
        return "Enable Notification Email"
    }
    
    func getSwitchStatus() -> Bool {
        return sharedUserDataService.notify
    }
  
    func isShowTextView() -> Bool {
        return false
    }
    
    func getPlaceholdText() -> String {
        return "Input Notification Email ..."
    }

    func getCurrentValue() -> String {
        return sharedUserDataService.notificationEmail
    }
    
    func updateValue(new_value: String, complete: (Bool, NSError?) -> Void) {
        if new_value == getCurrentValue() {
             complete(true, nil)
        } else {
            sharedUserDataService.updateNotificationEmail(new_value) { _, _, error in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            }
        }
    }
    
    func updateNotification(isOn : Bool, complete:(Bool, NSError?) -> Void) {
        if isOn == getSwitchStatus() {
            complete(true, nil)
        } else {
            sharedUserDataService.updateNotify(isOn, completion: { (task, response, error) -> Void in
                if let error = error {
                    complete(false, error)
                } else {
                    complete(true, nil)
                }
            })
        }
    }
    
    func isSwitchEnabled() -> Bool {
        return true
    }
    func isTextEnabled() -> Bool {
        return true
    }
}