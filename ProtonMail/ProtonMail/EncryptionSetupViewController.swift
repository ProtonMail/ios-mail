//
//  EncryptionViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/11/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

class EncryptionSetupViewController: UIViewController {
    
    fileprivate let kSegueToSignUpVerification = "encryption_to_verification_segue"
    
    @IBOutlet weak var highBitLevel: UIButton! //low
    @IBOutlet weak var normalBitLevel: UIButton! //high
    
    let hight : Int32 = 2048
    let low : Int32 = 4096
    
    
    var viewModel : SignupViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateButtonsStatus()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func updateButtonsStatus() {
        highBitLevel.isSelected = false
        normalBitLevel.isSelected = false
        let bit = self.viewModel.getCurrentBit()
        if bit == hight {
            highBitLevel.isSelected = true
        } else if bit == low {
            normalBitLevel.isSelected = true
        } else {
            highBitLevel.isSelected = true
            self.viewModel.setBit(hight)
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueToSignUpVerification {
            let viewController = segue.destination as! HumanCheckMenuViewController
            viewController.viewModel = self.viewModel
        }
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func continueAction(_ sender: UIButton) {
        MBProgressHUD.showAdded(to: view, animated: true)
        self.viewModel.generateKey { (isOk, msg, error) -> Void in
            if error == nil {
                self.viewModel.fetchDirect { (directs) -> Void in
                    MBProgressHUD.hide(for: self.view, animated: true)
                    if directs.count > 0 {
                        self.performSegue(withIdentifier: self.kSegueToSignUpVerification, sender: self)
                    } else {
                        let alert = NSLocalizedString("Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer.").alertController()
                        alert.addOKAction()
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
                let alert = error!.alertController(NSLocalizedString("Key generation failed"))
                alert.addOKAction()
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func switchAction(_ sender: UIButton) {
        if sender == normalBitLevel {
            self.viewModel.setBit(low)
        } else {
            self.viewModel.setBit(hight)
        }
        self.updateButtonsStatus()
    }
    
}
