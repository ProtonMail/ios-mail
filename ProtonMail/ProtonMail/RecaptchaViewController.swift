//
//  SignUpUserNameViewController.swift
//
//
//  Created by Yanfeng Zhang on 12/17/15.
//
//

import UIKit

class RecaptchaViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    
    //define
    private let hidePriority : UILayoutPriority = 1.0;
    private let showPriority: UILayoutPriority = 750.0;
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!

    private let kSegueToNotificationEmail = "sign_up_pwd_email_segue"
    private var startVerify : Bool = false
    private var checkUserStatus : Bool = false
    private var stopLoading : Bool = false
    private var doneClicked : Bool = false
    var viewModel : SignupViewModel!
    
    func configConstraint(show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetChecking()
        webView.scrollView.scrollEnabled = false
        
        NSURLCache.sharedURLCache().removeAllCachedResponses();
        
        let recptcha = NSURL(string: "https://secure.protonmail.com/mobile.html")!
        let requestObj = NSURLRequest(URL: recptcha)
        webView.loadRequest(requestObj)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default;
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSegueToNotificationEmail {
            let viewController = segue.destinationViewController as! SignUpEmailViewController
            viewController.viewModel = self.viewModel
        }
    }

    @IBAction func backAction(sender: UIButton) {
        stopLoading = true
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func startChecking() {
        
    }
    
    func resetChecking() {
        checkUserStatus = false
    }
    
    func finishChecking(isOk : Bool) {
        if isOk {
            checkUserStatus = true
        } else {

        }
    }
    
    @IBAction func createAccountAction(sender: UIButton) {
        if viewModel.isTokenOk() {
            self.finishChecking(true)
            if doneClicked {
                return
            }
            doneClicked = true;
            MBProgressHUD.showHUDAddedTo(view, animated: true)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.viewModel.createNewUser { (isOK, createDone, message, error) -> Void in
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    self.doneClicked = false
                    if !message.isEmpty {
                        let alert = message.alertController()
                        alert.addOKAction()
                    } else {
                        if isOK || createDone {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.goNotificationEmail()
                            })
                        }
                    }
                    
                }
            })
        } else {
            self.finishChecking(false)
            let alert = "The verification failed!".alertController()
            alert.addOKAction()
        }
    }
    
    func goNotificationEmail() {
        self.performSegueWithIdentifier(self.kSegueToNotificationEmail, sender: self)
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        PMLog.D("\(request)")
        let urlString = request.URL?.absoluteString;
        if urlString?.contains("https://www.google.com/recaptcha/api2/frame") == true {
            startVerify = true;
        }
        
        if urlString?.contains("https://www.google.com/intl/en/policies/privacy") == true {
            return false
        }
        
        if urlString?.contains("https://www.google.com/intl/en/policies/terms") == true {
            return false
        }
        
        if let tmp = urlString?.rangeOfString("https://secure.protonmail.com/expired_recaptcha_response://") {
            viewModel.setRecaptchaToken("", isExpired: true)
            resetWebviewHeight()
            webView.reload()
            return false
        }
        else if let tmp = urlString?.rangeOfString("https://secure.protonmail.com/recaptcha_response://") {
            if let token = urlString?.stringByReplacingOccurrencesOfString("https://secure.protonmail.com/recaptcha_response://", withString: "", options: NSStringCompareOptions.WidthInsensitiveSearch, range: nil) {
                viewModel.setRecaptchaToken(token, isExpired: false)
            }
            resetWebviewHeight()
            return false
        }
        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        if startVerify {
            if let result = webView.stringByEvaluatingJavaScriptFromString("document.body.scrollHeight;")?.toInt()  {
                let height = CGFloat(500)
                webViewHeightConstraint.constant = height;
            }
            startVerify = false
        }
    }
    
    func resetWebviewHeight() {
        if let result = webView.stringByEvaluatingJavaScriptFromString("document.body.scrollHeight;")?.toInt()  {
            let height = CGFloat(85)
            webViewHeightConstraint.constant = height;
        }
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        PMLog.D("")
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        PMLog.D("")
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {

    }
}
