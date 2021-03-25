//
//  RecaptchaViewController.swift
//  ProtonMail - Created on 12/17/15.
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
import MBProgressHUD
import PMCommon

class RecaptchaViewController: UIViewController {
    
    //define
    fileprivate let hidePriority : UILayoutPriority = UILayoutPriority(rawValue: 1.0);
    fileprivate let showPriority: UILayoutPriority = UILayoutPriority(rawValue: 750.0);
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!

    @IBOutlet weak var topLeftButton: UIButton!
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    private var wkWebView: WKWebView!
    private var wkWebViewHeightConstraint: NSLayoutConstraint!
    
    fileprivate let kSegueToNotificationEmail = "sign_up_pwd_email_segue"
    fileprivate var startVerify : Bool = false
    fileprivate var checkUserStatus : Bool = false
    fileprivate var stopLoading : Bool = false
    fileprivate var doneClicked : Bool = false
    var viewModel : SignupViewModel!
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTitles()
        self.resetChecking()
        self.setupWebView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kSegueToNotificationEmail {
            let viewController = segue.destination as! SignUpEmailViewController
            viewController.viewModel = self.viewModel
        }
    }
    
    // MARK: IBAction
    @IBAction private func tapAction(_ sender: UITapGestureRecognizer) {

    }
    
    @IBAction private func backAction(_ sender: UIButton) {
        stopLoading = true
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func createAccountAction(_ sender: UIButton) {
        guard viewModel.isTokenOk() else {
            self.finishChecking(false)
            let alert = LocalString._the_verification_failed.alertController()
            alert.addOKAction()
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        self.finishChecking(true)
        if doneClicked {
            return
        }

        doneClicked = true;
        self.viewModel.humanVerificationFinish()
        MBProgressHUD.showAdded(to: view, animated: true)
        self.viewModel.createNewUser { (isOK, createDone, message, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                MBProgressHUD.hide(for: self.view, animated: true)
                self.doneClicked = false
                if !message.isEmpty {
                    let title = LocalString._create_user_failed
                    var message = LocalString._default_error_please_try_again
                    if let error = error {
                        message = error.localizedDescription
                    }
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addOKAction()
                    self.present(alert, animated: true, completion: nil)
                } else {
                    if isOK || createDone {
                        self.goNotificationEmail()
                    }
                }
            })
        }
    }
}

// MARK: Setup
extension RecaptchaViewController {
    private func setupTitles() {
        topLeftButton.setTitle(LocalString._general_back_action, for: .normal)
        topTitleLabel.text = LocalString._human_verification
        continueButton.setTitle(LocalString._genernal_continue, for: .normal)
    }
    
    private func setupWebView() {
        let recptcha = URL(string: "https://secure.protonmail.com/captcha/captcha.html?token=signup&client=ios&host=\(Server.live.hostUrl)")!
        let requestObj = URLRequest(url: recptcha)
        
        // remove cache
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        
        self.wkWebView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        self.wkWebView.navigationDelegate = self
        self.wkWebView.scrollView.isScrollEnabled = false
        self.wkWebView.translatesAutoresizingMaskIntoConstraints = false
        MBProgressHUD.showAdded(to: self.wkWebView, animated: true)
        self.view.addSubview(self.wkWebView)
        
        self.wkWebView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.wkWebView.widthAnchor.constraint(equalToConstant: 345).isActive = true
        self.wkWebView.topAnchor.constraint(equalTo: self.topTitleLabel.bottomAnchor, constant: 18).isActive = true
        self.wkWebView.bottomAnchor.constraint(equalTo: self.continueButton.topAnchor, constant: -24).isActive = true
        self.wkWebViewHeightConstraint = self.wkWebView.heightAnchor.constraint(equalToConstant: 85)
        self.wkWebViewHeightConstraint.isActive = true
        self.wkWebView.load(requestObj)
        self.viewModel.requestHumanVerification()
    }
    
    private func configConstraint(_ show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
    }
    
    private func resetChecking() {
        checkUserStatus = false
    }
    
    private func finishChecking(_ isOk : Bool) {
        if isOk {
            checkUserStatus = true
        } else {

        }
    }
    
    private func goNotificationEmail() {
        self.performSegue(withIdentifier: self.kSegueToNotificationEmail, sender: self)
    }
}

extension RecaptchaViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        PMLog.D("\(navigationAction.request)")
        guard let urlString = navigationAction.request.url?.absoluteString else {
            decisionHandler(.allow)
            return
        }
        
        let verifies = [
            "https://www.google.com/recaptcha/api2/frame",
            ".com/fc/api/nojs",
            "fc/apps/canvas",
            "about:blank"
        ]
        if verifies.contains(urlString) {
            startVerify = true
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
            viewModel.setRecaptchaToken("", isExpired: true)
            resetWebviewHeight()
            webView.reload()
            decisionHandler(.cancel)
            return
        } else if urlString.contains("https://secure.protonmail.com/captcha/recaptcha_response://") {
            let token = urlString.replacingOccurrences(of: "https://secure.protonmail.com/captcha/recaptcha_response://", with: "", options: NSString.CompareOptions.widthInsensitive, range: nil)
            viewModel.setRecaptchaToken(token, isExpired: false)
            resetWebviewHeight()
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MBProgressHUD.hide(for: self.wkWebView, animated: true)
        guard startVerify else {return}
        startVerify = false
        webView.evaluateJavaScript("document.body.scrollHeight;") { (_, error) in
            if let err = error {
                PMLog.D("Get scroll height failed, error: \(err.localizedDescription)")
                return
            }
            self.wkWebViewHeightConstraint.constant = 500
        }
    }
    
    func resetWebviewHeight() {
        self.wkWebView.evaluateJavaScript("document.body.scrollHeight;") { (_, error) in
            if let err = error {
                PMLog.D("Get scroll height failed, error: \(err.localizedDescription)")
                return
            }
            self.wkWebViewHeightConstraint.constant = 85
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        PMLog.D("")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        PMLog.D("")
    }
}
