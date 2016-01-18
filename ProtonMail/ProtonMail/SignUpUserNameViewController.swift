//
//  SignUpUserNameViewController.swift
//
//
//  Created by Yanfeng Zhang on 12/17/15.
//
//

import UIKit

class SignUpUserNameViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var usernameTextField: TextInsetTextField!
    
    @IBOutlet weak var webView: UIWebView!
    
    //define
    private let hidePriority : UILayoutPriority = 1.0;
    private let showPriority: UILayoutPriority = 750.0;
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var userNameTopPaddingConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!
    
    
    private var startVerify : Bool = false;
    
    
    func configConstraint(show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level
        
        userNameTopPaddingConstraint.priority = level
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.scrollView.scrollEnabled = false
        
        let recptcha = NSURL(string: "http://protonmail.xyz/recaptcha.html")!
        let requestObj = NSURLRequest(URL: recptcha)
        webView.loadRequest(requestObj)

        usernameTextField.attributedPlaceholder = NSAttributedString(string: "Username", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        
        // Do any additional setup after loading the view.
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func checkAction(sender: UIButton) {
        let result = webView.stringByEvaluatingJavaScriptFromString("grecaptcha.getResponse(widgetId1)")
        if (result != nil) {
            PMLog.D("\(result)")
        } else {
        }
    }
    
    @IBAction func backAction(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func createAccountAction(sender: UIButton) {
        
        self.performSegueWithIdentifier("sign_up_password_segue", sender: self)
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        PMLog.D("\(request)")
        if request.URL?.absoluteString?.contains("https://www.google.com/recaptcha/api2/frame") == true {
            startVerify = true;
        }
        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        if startVerify {
            if let result = webView.stringByEvaluatingJavaScriptFromString("document.body.scrollHeight;")?.toInt()  {
                let height = CGFloat(500)
                webViewHeightConstraint.constant = height;
            }
        }
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        PMLog.D("")
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
         PMLog.D("")
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension SignUpUserNameViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        scrollBottomPaddingConstraint.constant = 0.0
        self.configConstraint(false)
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo!
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
            scrollBottomPaddingConstraint.constant = keyboardSize.height;
        }
        self.configConstraint(true)
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}
