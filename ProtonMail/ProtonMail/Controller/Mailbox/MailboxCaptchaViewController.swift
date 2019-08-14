//
//  MailboxCaptchaViewController.swift
//  ProtonMail - Created on 12/28/16.
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
        let cptcha = URL(string: "https://secure.protonmail.com/captcha/captcha.html?token=\(token)&client=ios&host=\(Constants.App.URL_HOST)")!
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

