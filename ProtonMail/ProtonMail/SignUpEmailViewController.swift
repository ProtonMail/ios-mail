//
//  SignUpEmailViewController.swift
//  
//
//  Created by Yanfeng Zhang on 12/18/15.
//
//

import UIKit
import Fabric
import Crashlytics

class SignUpEmailViewController: UIViewController {
    
    //define
    private let hidePriority : UILayoutPriority = 1.0;
    private let showPriority: UILayoutPriority = 750.0;
    
    @IBOutlet weak var logoTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var logoLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleTopPaddingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLeftPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var recoveryEmailTopPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var titleWarningLabel: UILabel!
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var recoveryEmailField: TextInsetTextField!
    @IBOutlet weak var displayNameField: TextInsetTextField!
    
    @IBOutlet weak var checkButton: UIButton!
    
    var viewModel : SignupViewModel!
    
    func configConstraint(show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
        logoTopPaddingConstraint.priority = level
        logoLeftPaddingConstraint.priority = level
        titleTopPaddingConstraint.priority = level
        titleLeftPaddingConstraint.priority = level

        recoveryEmailTopPaddingConstraint.priority = level
        
        titleWarningLabel.hidden = show
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userCachedStatus.showTourNextTime()
        recoveryEmailField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Recovery Email"), attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
        displayNameField.attributedPlaceholder = NSAttributedString(string: NSLocalizedString("Display Name"), attributes:[NSForegroundColorAttributeName : UIColor(hexColorCode: "#9898a8")])
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

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

    @IBAction func checkAction(sender: UIButton) {
        checkButton.selected = !checkButton.selected
    }

    @IBAction func backAction(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    private var doneClicked : Bool = false
    @IBAction func doneAction(sender: UIButton) {
        let email = (recoveryEmailField.text ?? "").trim()
        if email.isEmpty {
            // show a warning
            let alertController = UIAlertController(
                title: NSLocalizedString("Recovery Email Warning"),
                message: NSLocalizedString("Warning: You did not set a recovery email so account recovery is impossible if you forget your password. Proceed without recovery email?"),
                preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel"), style: .Default, handler: { action in
                
            }))
            alertController.addAction(UIAlertAction(title: NSLocalizedString("Confirm"), style: .Destructive, handler: { action in
                if (!email.isEmpty && !email.isValidEmail()) {
                    let alert = NSLocalizedString("Please input a valid email address.").alertController()
                    alert.addOKAction()
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    if self.doneClicked {
                        return
                    }
                    self.doneClicked = true
                    MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                    self.dismissKeyboard()
                    self.viewModel.setRecovery(self.checkButton.selected, email: self.recoveryEmailField.text!, displayName: self.displayNameField.text!)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        self.doneClicked = false
                        self.moveToInbox()
                    })
                }
            }))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    private func moveToInbox() {
        sharedUserDataService.isSignedIn = true
        if let addresses = sharedUserDataService.userInfo?.userAddresses.toPMNAddresses() {
            sharedOpenPGP.setAddresses(addresses);
        }
        self.loadContent()
    }
    
    private func loadContent() {
        logUser()
        userCachedStatus.pinFailedCount = 0;
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationDefined.didSignIn, object: self)
        (UIApplication.sharedApplication().delegate as! AppDelegate).switchTo(storyboard: .inbox, animated: true)
        loadContactsAfterInstall()
    }
    
    func logUser() {
        if  let username = sharedUserDataService.username {
            Crashlytics.sharedInstance().setUserIdentifier(username)
            Crashlytics.sharedInstance().setUserName(username)
        }
    }
    
    func loadContactsAfterInstall()
    {
        sharedUserDataService.fetchUserInfo()
        sharedContactDataService.fetchContacts({ (contacts, error) -> Void in
            if error != nil {
                NSLog("\(error)")
            } else {
                NSLog("Contacts count: \(contacts!.count)")
            }
        })
    }

    
    @IBAction func tapAction(sender: UITapGestureRecognizer) {
        dismissKeyboard()
    }
    func dismissKeyboard() {
        recoveryEmailField.resignFirstResponder()
    }
}


// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension SignUpEmailViewController: NSNotificationCenterKeyboardObserverProtocol {
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