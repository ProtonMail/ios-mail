//
//  ContactImportViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/7/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit
import Contacts

protocol UpgradeAlertVCDelegate {
    func cancel()
}

class UpgradeAlertViewController: UIViewController {
    
    var delegate : UpgradeAlertVCDelegate?

    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelTwo: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageLabelTwo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.viewContainer.layer.cornerRadius = 4.0
        self.okButton.layer.cornerRadius = 8.0
        
        //set text
        self.okButton.setTitle(NSLocalizedString("Got it", comment: "Action"), for: UIControlState.normal)
        
        self.titleLabel.text = NSLocalizedString("PREMIUM FEATURE", comment: "Upgrade warning title")
        self.titleLabelTwo.text = NSLocalizedString("Looking to secure your contact's details?", comment: "Upgrade warning title")
        self.messageLabel.text = NSLocalizedString("ProtonMail Plus/Professional/Visionary enables you to add and edit contact details beyond just your contact’s name and email. By using ProtonMail, this data will be as secure as your end-to-end encrypted email.", comment: "Upgrade warning message")
        self.messageLabelTwo.text = NSLocalizedString("Upgrading is not possible in the app.", comment: "Upgrade warning message")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss()
    }
    
    private func dismiss() {
        self.dismiss(animated: true, completion: {
            self.delegate?.cancel()
        })
    }
}
