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
        MBProgressHUD.showHUDAddedTo(view, animated: true)
        viewModel.getToken { (token, error) in
            if let t = token {
                self.loadWebView(t)
            } else {
                //show errors
            }
            MBProgressHUD.hideHUDForView(self.view, animated: true)
        }
    }
    
    private func loadWebView(token : String) {
        let cptcha = NSURL(string: "https://secure.protonmail.com/captcha/captcha.html?token=\(token)&client=ios&host=\(AppConstants.URL_HOST)")!
        let requestObj = NSURLRequest(URL: cptcha)
        webVIew.loadRequest(requestObj)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Human Check Warning"),
            message: NSLocalizedString("Warning: Before you pass the human check you can't sent email!!!"),
            preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Check Again"), style: .Default, handler: { action in
            
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel Check"), style: .Destructive, handler: { action in
            
            self.dismissViewControllerAnimated(true, completion: nil)
            self.delegate?.cancel()
        }))
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let urlString = request.URL?.absoluteString
        
        if urlString?.contains("https://www.google.com/intl/en/policies/privacy") == true {
            return false
        }
        
        if urlString?.contains("how-to-solve-") == true {
            return false
        }
        if urlString?.contains("https://www.google.com/intl/en/policies/terms") == true {
            return false
        }

        
        if let _ = urlString?.rangeOfString("https://secure.protonmail.com/expired_recaptcha_response://") {
            webView.reload()
            return false
        }
        else if let _ = urlString?.rangeOfString("https://secure.protonmail.com/captcha/recaptcha_response://") {
            if let token = urlString?.stringByReplacingOccurrencesOfString("https://secure.protonmail.com/captcha/recaptcha_response://", withString: "", options: NSStringCompareOptions.WidthInsensitiveSearch, range: nil) {
                MBProgressHUD.showHUDAddedTo(view, animated: true)
                viewModel.humanCheck("captcha", token: token, complete: { (error: NSError?) in
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    if let err = error {
                        err.alertHumanCheckErrorToast()
                        self.webVIew.reload()
                    } else {
                        self.dismissViewControllerAnimated(true, completion: nil)
                        self.delegate?.done()
                    }
                })   
            }
            return false
        }
        return true
    }
}

