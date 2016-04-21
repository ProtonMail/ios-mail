//
//  TouchIDCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/6/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation
import LocalAuthentication

class TouchIDCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    typealias ActionBlock = (cell: TouchIDCell!, newStatus: Bool) -> Void
    
    @IBOutlet weak var switchView: UISwitch!
    @IBAction func switchAction(sender: UISwitch) {
        if !userCachedStatus.isTouchIDEnabled {
            
            // try to enable touch id
            let context = LAContext()
            // Declare a NSError variable.
            var error: NSError?
            // Check if the device can evaluate the policy.
            if context.canEvaluatePolicy(LAPolicy.DeviceOwnerAuthenticationWithBiometrics, error: &error) {
                userCachedStatus.isTouchIDEnabled = true
                userCachedStatus.touchIDEmail = sharedUserDataService.username ?? ""
            }
            else{
                var alertString : String = "";
                // If the security policy cannot be evaluated then show a short message depending on the error.
                switch error!.code{
                case LAError.TouchIDNotEnrolled.rawValue:
                    alertString = NSLocalizedString("TouchID is not enrolled, enable it in the system Settings")
                case LAError.PasscodeNotSet.rawValue:
                    alertString = NSLocalizedString("A passcode has not been set, enable it in the system Settings")
                default:
                    // The LAError.TouchIDNotAvailable case.
                    alertString = NSLocalizedString("TouchID not available")
                }
                println(alertString)
                println(error?.localizedDescription)
                alertString.alertToast()
                switchView.on = false;
            }
        } else {
            userCachedStatus.isTouchIDEnabled = false
            userCachedStatus.touchIDEmail = ""
        }
    }
    
    func setUpSwitch(enabled : Bool, complete : ActionBlock) {
        switchView.enabled = true

        switchView.on = enabled;
        self.updateStatus()
    }
    
    func updateStatus() {

    }
}