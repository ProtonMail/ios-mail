//
//  ContactImportViewController.swift
//  ProtonMail - Created on 2/7/18.
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


import UIKit
import Contacts

protocol UpgradeAlertVCDelegate {
    func cancel()
    func goPlans()
    func learnMore()
}

class UpgradeAlertViewController: UIViewController, ViewModelProtocol, AccessibleView {
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
        generateAccessibilityIdentifiers()
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
        self.dismiss()
    }
    @IBAction func learnMore(_ sender: Any) {
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
