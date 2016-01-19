//
//  SignUpUserNameViewController.swift
//
//
//  Created by Yanfeng Zhang on 12/17/15.
//
//

import UIKit

class SignUpUserNameViewController: UIViewController, UIWebViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var usernameTextField: TextInsetTextField!
    @IBOutlet weak var pickedDomainLabel: UILabel!
    
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var warningIcon: UIImageView!
    
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
    
    
    let domains : [String] = ["protonmail.com", "protonmail.ch"]
    var selected : Int = 0;
    
    private var startVerify : Bool = false
    
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
        
        NSURLCache.sharedURLCache().removeAllCachedResponses();
        
        let recptcha = NSURL(string: "https://secure.protonmail.com/mobile.html")!
        let requestObj = NSURLRequest(URL: recptcha)
        webView.loadRequest(requestObj)
        
        usernameTextField.attributedPlaceholder = NSAttributedString(string: "Username", attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        self.updatePickedDomain()
    }
    
    func updatePickedDomain () {
        pickedDomainLabel.text = "@\(domains[selected])"
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.Default;
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
        dismissKeyboard()
        self.performSegueWithIdentifier("sign_up_password_segue", sender: self)
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        PMLog.D("\(request)")
        let urlString = request.URL?.absoluteString;
        
        if urlString?.contains("https://www.google.com/recaptcha/api2/frame") == true {
            startVerify = true;
        }
        
        if let tmp = urlString?.rangeOfString("recaptcha_response://") {
            resetWebviewHeight()
            return false
        }
        
        //        if requ else if ([urlString rangeOfString:@"scroll://"].location != NSNotFound) {
        //
        //            NSInteger position = [[urlString stringByReplacingOccurrencesOfString:@"scroll://" withString:@""] integerValue];
        //            [self editorDidScrollWithPosition:position];
        //
        //        }
        
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
    
    @IBAction func pickDomainName(sender: UIButton) {
        showPickerInActionSheet()
    }
    
    func showPickerInActionSheet() {
        var title = ""
        var message = "\n\n\n\n\n\n\n\n\n\n";
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet);
        alert.modalInPopover = true;
        
        //Create a frame (placeholder/wrapper) for the picker and then create the picker
        var pickerFrame: CGRect = CGRectMake(17, 52, 270, 100); // CGRectMake(left), top, width, height) - left and top are like margins
        var picker: UIPickerView = UIPickerView(frame: pickerFrame);
        
        //set the pickers datasource and delegate
        picker.delegate = self;
        picker.dataSource = self;
        
        //Add the picker to the alert controller
        alert.view.addSubview(picker);
        
        //Create the toolbar view - the view witch will hold our 2 buttons
        var toolFrame = CGRectMake(17, 5, 270, 45);
        var toolView: UIView = UIView(frame: toolFrame);
        
        //add buttons to the view
        var buttonCancelFrame: CGRect = CGRectMake(0, 7, 100, 30); //size & position of the button as placed on the toolView
        
        //Create the cancel button & set its title
        var buttonCancel: UIButton = UIButton(frame: buttonCancelFrame);
        buttonCancel.setTitle("Done", forState: UIControlState.Normal);
        buttonCancel.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal);
        toolView.addSubview(buttonCancel); //add it to the toolView
        
        //Add the target - target, function to call, the event witch will trigger the function call
        buttonCancel.addTarget(self, action: "cancelSelection:", forControlEvents: UIControlEvents.TouchDown);
        
        
        //        //add buttons to the view
        //        var buttonOkFrame: CGRect = CGRectMake(170, 7, 100, 30); //size & position of the button as placed on the toolView
        //
        //        //Create the Select button & set the title
        //        var buttonOk: UIButton = UIButton(frame: buttonOkFrame);
        //        buttonOk.setTitle("Select", forState: UIControlState.Normal);
        //        buttonOk.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal);
        //        toolView.addSubview(buttonOk); //add to the subview
        //        //Add the tartget. In my case I dynamicly set the target of the select button
        //        buttonOk.addTarget(self, action: "pickedOK:", forControlEvents: UIControlEvents.TouchDown);
        
        //add the toolbar to the alert controller
        alert.view.addSubview(toolView);
        
        picker.selectRow(selected, inComponent: 0, animated: true)
        
        self.presentViewController(alert, animated: true, completion: nil);
    }
    
    func pickedOK(sender: UIButton){
        println("OK");
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func cancelSelection(sender: UIButton){
        println("Cancel");
        self.dismissViewControllerAnimated(true, completion: nil);
        // We dismiss the alert. Here you can add your additional code to execute when cancel is pressed
    }
    
    // Return the title of each row in your picker ... In my case that will be the profile name or the username string
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return domains[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selected = row;
        updatePickedDomain ()
    }
    
    // returns the number of 'columns' to display.
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // returns the # of rows in each component..
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return domains.count
    }
    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    func dismissKeyboard() {
        usernameTextField.resignFirstResponder()
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
