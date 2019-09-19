//
//  BioCodeViewController.swift
//  ProtonMail - Created on 19/09/2019.
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
    

import Foundation

class BioCodeViewController: UIViewController, BioCodeViewDelegate {
    weak var delegate : PinCodeViewControllerDelegate?
    
    func authenticateUser() {
        UnlockManager.shared.biometricAuthentication(afterBioAuthPassed: {
            self.delegate?.Next()
            //self.navigationController?.popViewController(animated: true)
        })
    }
    
    func touch_id_action(_ sender: Any) {
        self.authenticateUser()
    }
    
    func pin_unlock_action(_ sender: Any) {
        // nothing
    }
    
    @IBOutlet weak var bioCodeView: BioCodeView!
    
    func configureNavigationBar() {
        let original = UIImage(named: "menu_logout-active")!
        let flipped = UIImage(cgImage: original.cgImage!, scale: 0.7 * original.scale, orientation: .up) // scale coefficient is a magic number
        
        self.navigationItem.title = ""
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: flipped,
                                                style: .plain,
                                                target: self,
                                                action: #selector(self.logoutButtonTapped))
        
        if let bar = self.navigationController?.navigationBar {
            // this will make bar transparent
            navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController?.navigationBar.shadowImage = UIImage()
            navigationController?.navigationBar.isTranslucent = true
            
            // buttons
            navigationController?.navigationBar.tintColor = .white
            
            // text
            bar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: Fonts.h2.regular
            ]
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.authenticateUser()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.configureNavigationBar()
        
        self.bioCodeView.delegate = self
        self.bioCodeView.setup()
        self.bioCodeView.loginCheck(.requireTouchID)
    }

    
    @objc func logoutButtonTapped() {
        let alert = UIAlertController(title: nil, message: LocalString._logout_confirmation, preferredStyle: .alert)
        alert.addAction(.init(title: LocalString._sign_out, style: .destructive, handler: { _ in
            self.delegate?.Cancel()
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(.init(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
