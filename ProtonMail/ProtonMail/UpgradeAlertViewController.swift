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
        self.okButton.setTitle(LocalString._got_it, for: UIControlState.normal)
        
        self.titleLabel.text = LocalString._premium_feature
        self.titleLabelTwo.text = LocalString._looking_to_secure_your_contacts_details
        self.messageLabel.text = LocalString._protonmail_plus_enables_you_to_add_and_edit_contact_details_beyond_
        self.messageLabelTwo.text = LocalString._upgrading_is_not_possible_in_the_app
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
