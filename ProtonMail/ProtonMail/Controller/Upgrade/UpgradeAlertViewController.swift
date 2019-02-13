//
//  ContactImportViewController.swift
//  ProtonMail - Created on 2/7/18.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import Contacts

protocol UpgradeAlertVCDelegate {
    func cancel()
    func goPlans()
    func learnMore()
}

class UpgradeAlertViewController: UIViewController, ViewModelProtocol {
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
