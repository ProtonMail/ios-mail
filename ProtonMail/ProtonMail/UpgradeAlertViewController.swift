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
    
    private static var randomNum : Int = 0
    @IBOutlet weak var viewOne: UIView!
    @IBOutlet weak var viewTwo: UIView!
    
    @IBOutlet weak var buttonOne: UIButton!
    @IBOutlet weak var buttonTwo: UIButton!
    
    var delegate : UpgradeAlertVCDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    private var cancelled : Bool = false
    private var showedCancel : Bool = false
    private var finished : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewOne.layer.cornerRadius = 4.0
        viewTwo.layer.cornerRadius = 4.0
        
        buttonOne.layer.cornerRadius = 20.0
        buttonTwo.layer.cornerRadius = 20.0
        
        if UpgradeAlertViewController.randomNum == 0 {
            viewOne.isHidden = true
            UpgradeAlertViewController.randomNum = 1
        } else {
            viewTwo.isHidden = true
            UpgradeAlertViewController.randomNum = 0
        }
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
