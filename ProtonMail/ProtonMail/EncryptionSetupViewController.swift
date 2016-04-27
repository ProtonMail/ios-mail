//
//  EncryptionViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/11/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

class EncryptionSetupViewController: UIViewController {
    
    private let kSegueToSignUpVerification = "encryption_to_verification_segue"
    
    @IBOutlet weak var highBitLevel: UIButton! //low
    @IBOutlet weak var normalBitLevel: UIButton! //high
    
    let hight : Int32 = 2048
    let low : Int32 = 4096
    
    
    var viewModel : SignupViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateButtonsStatus()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func updateButtonsStatus() {
        highBitLevel.selected = false
        normalBitLevel.selected = false
        let bit = self.viewModel.getCurrentBit()
        if bit == hight {
            highBitLevel.selected = true
        } else if bit == low {
            normalBitLevel.selected = true
        } else {
            highBitLevel.selected = true
            self.viewModel.setBit(hight)
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSegueToSignUpVerification {
            let viewController = segue.destinationViewController as! HumanCheckMenuViewController
            viewController.viewModel = self.viewModel
        }
    }
    
    @IBAction func backAction(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func continueAction(sender: UIButton) {
        MBProgressHUD.showHUDAddedTo(view, animated: true)
        self.viewModel.generateKey { (isOk, msg, error) -> Void in
            if error == nil {
                self.viewModel.fetchDirect { (directs) -> Void in
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    if directs.count > 0 {
                        self.performSegueWithIdentifier(self.kSegueToSignUpVerification, sender: self)
                    } else {
                        let alert = NSLocalizedString("Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer.").alertController()
                        alert.addOKAction()
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }
            } else {
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                let alert = error!.alertController(NSLocalizedString("Key generation failed"))
                alert.addOKAction()
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func switchAction(sender: UIButton) {
        if sender == normalBitLevel {
            self.viewModel.setBit(low)
        } else {
            self.viewModel.setBit(hight)
        }
        self.updateButtonsStatus()
    }
    
}
