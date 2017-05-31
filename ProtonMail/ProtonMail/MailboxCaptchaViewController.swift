//
//  MailboxCaptchaViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/28/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation
protocol MailboxCaptchaVCDelegate {
    func cancel()
    func done()
}

class MailboxCaptchaViewController : UIViewController, UIWebViewDelegate {
    
    var viewModel : HumanCheckViewModel!
    
    @IBOutlet weak var webVIew: UIWebView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    
    var delegate : MailboxCaptchaVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;
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
        let cptcha = URL(string: "https://secure.protonmail.com/captcha/captcha.html?token=\(token)&client=ios&host=\(AppConstants.URL_HOST)")!
        let requestObj = URLRequest(url: cptcha)
        webVIew.loadRequest(requestObj)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    @IBAction func cancelAction(_ sender: AnyObject) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Human Check Warning"),
            message: NSLocalizedString("Warning: Before you pass the human check you can't sent email!!!"),
            preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Check Again"), style: .default, handler: { action in
            
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel Check"), style: .destructive, handler: { action in
            
            self.dismiss(animated: true, completion: nil)
            self.delegate?.cancel()
        }))
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
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
        }
        else if let _ = urlString?.range(of: "https://secure.protonmail.com/captcha/recaptcha_response://") {
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

