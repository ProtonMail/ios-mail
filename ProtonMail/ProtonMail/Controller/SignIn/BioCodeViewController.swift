//
//  BioCodeViewController.swift
//  ProtonMail - Created on 19/09/2019.
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

class BioCodeViewController: UIViewController, BioCodeViewDelegate, BioAuthenticating {
    weak var delegate : PinCodeViewControllerDelegate?
    
    func authenticateUser() {
        guard UIDevice.current.biometricType != .none else {
            let alert = UIAlertController.init(title: LocalString._unlock_required,
                                               message: LocalString._enable_faceid_in_settings,
                                               preferredStyle: .alert)
            let settings = UIAlertAction(title: LocalString._go_to_settings, style: .cancel) { _ in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            let logout = UIAlertAction(title: LocalString._go_to_login, style: .default) { _ in
                self.logout()
            }
            [settings, logout].forEach(alert.addAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        UnlockManager.shared.biometricAuthentication(afterBioAuthPassed: {
            self.delegate?.Next()
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
        self.decideOnBioAuthentication()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.configureNavigationBar()
        
        self.bioCodeView.delegate = self
        self.bioCodeView.setup()
        self.bioCodeView.loginCheck(.requireTouchID)
        
        self.subscribeToWillEnterForegroundMessage()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func logoutButtonTapped() {
        let alert = UIAlertController(title: nil, message: LocalString._logout_confirmation, preferredStyle: .alert)
        let logout = UIAlertAction(title: LocalString._sign_out, style: .destructive) { _ in
            self.logout()
        }
        let cancel = UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil)
        [logout, cancel].forEach(alert.addAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func logout() {
        self.delegate?.Cancel()
        self.navigationController?.popViewController(animated: true)
    }
}
