//
//  MailboxCaptchaViewController.swift
//  ProtonMail - Created on 12/28/16.
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

protocol MailboxCaptchaVCDelegate : AnyObject {
    func cancel()
    func done()
}

class MailboxCaptchaViewController : UIViewController, UIWebViewDelegate {
    
    var viewModel : HumanCheckViewModel!
    
    @IBOutlet weak var webVIew: UIWebView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    
    weak var delegate : MailboxCaptchaVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4
        self.webVIew.delegate = self
        // show loading
        MBProgressHUD.showAdded(to: view, animated: true)
        viewModel.getToken { (token, error) in
            if let t = token {
                self.loadWebView(t)
            } else {
                //show errors
            }
            MBProgressHUD.hide(for: self.view, animated: true)
        }
    }
    
    fileprivate func loadWebView(_ token : String) {
        let cptcha = URL(string: "https://secure.protonmail.com/captcha/captcha.html?token=\(token)&client=ios&host=\(Server.live.hostUrl)")!
        let requestObj = URLRequest(url: cptcha)
        webVIew.loadRequest(requestObj)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        let alertController = UIAlertController(
            title: LocalString._signup_human_check_warning_title,
            message: LocalString._signup_human_check_warning,
            preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: LocalString._signup_check_again_action, style: .default, handler: { action in
            
        }))
        alertController.addAction(UIAlertAction(title: LocalString._signup_cancel_check_action, style: .destructive, handler: { action in
            
            self.dismiss(animated: true, completion: nil)
            self.delegate?.cancel()
        }))
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        let urlString = request.url?.absoluteString
        if urlString?.contains("https://www.google.com/intl/en/policies/privacy") == true {
            return false
        }
        
        if urlString?.contains("how-to-solve-") == true {
            return false
        }
        
        if urlString?.contains("https://www.google.com/intl/en/policies/terms") == true {
            return false
        }

        if let _ = urlString?.range(of: "https://secure.protonmail.com/expired_recaptcha_response://") {
            webView.reload()
            return false
        } else if let _ = urlString?.range(of: "https://secure.protonmail.com/captcha/recaptcha_response://") {
            if let token = urlString?.replacingOccurrences(of: "https://secure.protonmail.com/captcha/recaptcha_response://", with: "", options: NSString.CompareOptions.widthInsensitive, range: nil) {
                MBProgressHUD.showAdded(to: view, animated: true)
                viewModel.humanCheck("captcha", token: token, complete: { (error: NSError?) in
                    MBProgressHUD.hide(for: self.view, animated: true)
                    if let err = error {
                        err.alertHumanCheckErrorToast()
                        self.webVIew.reload()
                    } else {
                        self.dismiss(animated: true, completion: nil)
                        self.delegate?.done()
                    }
                })   
            }
            return false
        }
        return true
    }
}

