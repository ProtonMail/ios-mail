//
//  ContactImportViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/7/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit
import Contacts

protocol ExpirationWarningVCDelegate {
    func send()
}

class ExpirationWarningViewController : UIViewController {

//    @IBOutlet weak var sendButton: UIButton!
//    
//    
//    
//    
    
    
    var delegate : ExpirationWarningVCDelegate?
//
//    @IBOutlet weak var backgroundView: UIImageView!
//    @IBOutlet weak var viewContainer: UIView!
//    @IBOutlet weak var closeButton: UIButton!
//    @IBOutlet weak var okButton: UIButton!
//    
//    @IBOutlet weak var titleLabel: UILabel!
//    @IBOutlet weak var titleLabelTwo: UILabel!
//    @IBOutlet weak var messageLabel: UILabel!
//    @IBOutlet weak var messageLabelTwo: UILabel!
//    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.viewContainer.layer.cornerRadius = 4.0
//        self.okButton.layer.cornerRadius = 8.0
//
        //set text
//        self.okButton.setTitle(self.viewModel.button, for: UIControlState.normal)
//
//        self.titleLabel.text = self.viewModel.title
//        self.titleLabelTwo.text = self.viewModel.title2
//        self.messageLabel.text = self.viewModel.message
//        self.messageLabelTwo.text = self.viewModel.message2
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss()
    }

    @IBAction func sendAction(_ sender: Any) {
    }
    private func dismiss() {
        self.dismiss(animated: true, completion: {
//            self.delegate?.cancel()
        })
    }
}
