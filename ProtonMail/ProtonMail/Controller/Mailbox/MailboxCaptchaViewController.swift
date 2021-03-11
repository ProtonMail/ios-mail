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
import PMCommon

protocol MailboxCaptchaVCDelegate : AnyObject {
    func cancel()
    func done()
}

class MailboxCaptchaViewController : UIViewController, AccessibleView {
    
    var viewModel : HumanCheckViewModel!
    
    private var wkWebView: WKWebView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet var humanVerificationLabel: UILabel!
    @IBOutlet var cancelView: UIView!
    
    weak var delegate : MailboxCaptchaVCDelegate?
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4
        self.setupWkWebView()
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
        generateAccessibilityIdentifiers()
    }
    
    @IBAction private func cancelAction(_ sender: AnyObject) {
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
}

// MARK: Private function
extension MailboxCaptchaViewController {
    private func setupWkWebView() {
        let webConfiguration = WKWebViewConfiguration()
        self.wkWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.wkWebView.navigationDelegate = self
        self.wkWebView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.wkWebView)
        
        self.wkWebView.topAnchor.constraint(equalTo: self.humanVerificationLabel.bottomAnchor, constant: 18).isActive = true
        self.wkWebView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        self.wkWebView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        self.wkWebView.bottomAnchor.constraint(equalTo: self.cancelView.topAnchor, constant: -8).isActive = true
    }
    
    private func loadWebView(_ token : String) {
        let cptcha = URL(string: "https://secure.protonmail.com/captcha/captcha.html?token=\(token)&client=ios&host=\(Server.live.hostUrl)")!
        let requestObj = URLRequest(url: cptcha)
        self.wkWebView.load(requestObj)
    }
}

extension MailboxCaptchaViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        PMLog.D("\(navigationAction.request)")
        guard let urlString = navigationAction.request.url?.absoluteString else {
            decisionHandler(.allow)
            return
        }
     
        let forbiden = [
            "https://www.google.com/intl/en/policies/privacy",
            "how-to-solve-",
            "https://www.google.com/intl/en/policies/terms"
        ]
        if forbiden.contains(urlString) {
            decisionHandler(.cancel)
            return
        }
        
        if urlString.contains("https://secure.protonmail.com/expired_recaptcha_response://") {
            webView.reload()
            decisionHandler(.cancel)
            return
        } else if urlString.contains("https://secure.protonmail.com/captcha/recaptcha_response://") {
            let token = urlString.replacingOccurrences(of: "https://secure.protonmail.com/captcha/recaptcha_response://", with: "", options: NSString.CompareOptions.widthInsensitive, range: nil)
            MBProgressHUD.showAdded(to: view, animated: true)
            viewModel.humanCheck("captcha", token: token, complete: { (error: NSError?) in
                MBProgressHUD.hide(for: self.view, animated: true)
                if let err = error {
                    err.alertHumanCheckErrorToast()
                    self.wkWebView.reload()
                } else {
                    self.dismiss(animated: true, completion: nil)
                    self.delegate?.done()
                }
            })
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}
