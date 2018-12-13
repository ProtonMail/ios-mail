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
    func goPlans()
    func learnMore()
}

class UpgradeAlertViewController: UIViewController, ViewModelProtocolNew {
    typealias viewModelType = UpgradeAlertViewModel
    
    var viewModel : UpgradeAlertViewModel!
    
    func set(viewModel: UpgradeAlertViewModel) {
        self.viewModel = viewModel
    }
    func inactiveViewModel() { }
    
    
    var delegate : UpgradeAlertVCDelegate?

    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    @IBOutlet weak var notNowButton: UIButton!
    @IBOutlet weak var plansButton: UIButton!
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleLabelTwo: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewContainer.layer.cornerRadius = 4.0
        self.okButton.layer.cornerRadius = 6.0
        self.notNowButton.layer.cornerRadius = 6.0
        self.plansButton.layer.cornerRadius = 6.0
        
        //set text
        self.okButton.setTitle(self.viewModel.button1, for: UIControl.State.normal)
        self.notNowButton.setTitle(self.viewModel.button2, for: UIControl.State.normal)
        self.plansButton.setTitle(self.viewModel.button3, for: UIControl.State.normal)
        
        self.titleLabel.text = self.viewModel.title
        self.titleLabelTwo.text = self.viewModel.title2
        self.messageLabel.text = self.viewModel.message
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //TODO:: Rename to learnmore later
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.delegate?.learnMore()
        })
    }
    
    @IBAction func notNowAction(_ sender: Any) {
        self.dismiss()
    }
    
    @IBAction func plansAction(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.delegate?.goPlans()
        })
    }
    
    private func dismiss() {
        self.dismiss(animated: true, completion: {
            self.delegate?.cancel()
        })
    }
}
