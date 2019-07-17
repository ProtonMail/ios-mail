//
//  EncryptionViewController.swift
//  ProtonMail - Created on 2/11/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import MBProgressHUD

class EncryptionSetupViewController: UIViewController {
    
    fileprivate let kSegueToSignUpVerification = "encryption_to_verification_segue"
    
    //Notes: low means high(4096) high means normal(2048)
    let hight : Int = 2048
    let low : Int = 4096
    
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
        
        topLeftButton.setTitle(LocalString._general_back_action, for: .normal)
        topTitleLabel.text = LocalString._encryption_setup
        
        let font = Fonts.h4.bold
        let attrHigh = NSMutableAttributedString(
            string: " " + LocalString._high_security,
            attributes: [NSAttributedString.Key.font:font])
        let font1 = Fonts.h4.regular
        let attrHighSize = NSMutableAttributedString(
            string: " " +  LocalString._signup_key_2048_size,
            attributes: [NSAttributedString.Key.font:font1])
        attrHigh.append(attrHighSize)
        highBitLevel.setAttributedTitle(attrHigh, for: .normal)
        
        let attrExtreme = NSMutableAttributedString(
            string: LocalString._extreme_security,
            attributes: [NSAttributedString.Key.font:font])
        let attrExtremeSize = NSMutableAttributedString(
            string: " " + LocalString._signup_key_4096_size,
            attributes: [NSAttributedString.Key.font:font1])
        attrExtreme.append(attrExtremeSize)
        normalBitLevel.setAttributedTitle(attrExtreme, for: .normal)
        
        highSecurityLabel.text = LocalString._the_current_standard
        
        let notesfont = Fonts.s13.regular
        let attr1 = NSMutableAttributedString(
            string: LocalString._the_highest_level_of_encryption_available + " ",
            attributes: [NSAttributedString.Key.font:notesfont])
        let notesfont1 = Fonts.s13.bold
        let attr2 = NSMutableAttributedString(
            string: LocalString._can_take_several_minutes_to_setup,
            attributes: [NSAttributedString.Key.font:notesfont1])
        attr1.append(attr2)
        extremeSecurityNoteLabel.attributedText = attr1
        continueButton.setTitle(LocalString._genernal_continue, for: .normal)
        
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
                        let alert = LocalString._mobile_signups_are_disabled_pls_later_pm_com.alertController()
                        alert.addOKAction()
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
                let alert = error!.alertController(LocalString._key_generation_failed)
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
