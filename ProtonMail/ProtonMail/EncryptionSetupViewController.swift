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
    
    //Notes: low means high(4096) high means normal(2048)
    let hight : Int32 = 2048
    let low : Int32 = 4096
    
    var viewModel : SignupViewModel!
    
    @IBOutlet weak var topLeftButton: UIButton!
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var highBitLevel: UIButton! //low
    @IBOutlet weak var normalBitLevel: UIButton! //high

    @IBOutlet weak var highSecurityLabel: UILabel!
    @IBOutlet weak var extremeSecurityNoteLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topLeftButton.setTitle(NSLocalizedString("Back", comment: "top left back button"), for: .normal)
        topTitleLabel.text = NSLocalizedString("Encryption Setup", comment: "key setup top title")
        
        let font = UIFont.boldSystemFont(ofSize: 16)
        let attrHigh = NSMutableAttributedString(
            string: " " + NSLocalizedString("High Security", comment: "Key size checkbox"),
            attributes: [NSFontAttributeName:font])
        let font1 = UIFont.systemFont(ofSize: 16)
        let attrHighSize = NSMutableAttributedString(
            string: " " + NSLocalizedString("(2048 bit)", comment: "Key size text"),
            attributes: [NSFontAttributeName:font1])
        attrHigh.append(attrHighSize)
        highBitLevel.setAttributedTitle(attrHigh, for: .normal)
        
        let attrExtreme = NSMutableAttributedString(
            string: NSLocalizedString("Extreme Security", comment: "Key size checkbox"),
            attributes: [NSFontAttributeName:font])
        let attrExtremeSize = NSMutableAttributedString(
            string: " " + NSLocalizedString("(4096 bit)", comment: "Key size text"),
            attributes: [NSFontAttributeName:font1])
        attrExtreme.append(attrExtremeSize)
        normalBitLevel.setAttributedTitle(attrExtreme, for: .normal)
        
        highSecurityLabel.text = NSLocalizedString("The current standard", comment: "key size notes")
        
        let notesfont = UIFont.systemFont(ofSize: 13)
        let attr1 = NSMutableAttributedString(
            string: NSLocalizedString("The highest level of encryption available.", comment: "key size note part 1") + " ",
            attributes: [NSFontAttributeName:notesfont])
        let notesfont1 = UIFont.boldSystemFont(ofSize: 13)
        let attr2 = NSMutableAttributedString(
            string: NSLocalizedString("Can take several minutes to setup.", comment: "key size note part 2"),
            attributes: [NSFontAttributeName:notesfont1])
        attr1.append(attr2)
        extremeSecurityNoteLabel.attributedText = attr1
        continueButton.setTitle(NSLocalizedString("Continue", comment: "key setup continue button"), for: .normal)
        
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
                        let alert = NSLocalizedString("Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer.", comment: "Description").alertController()
                        alert.addOKAction()
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
                let alert = error!.alertController(NSLocalizedString("Key generation failed", comment: "Error"))
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
