//
//  SignUpEmailViewController.swift
//  
//
//  Created by Yanfeng Zhang on 12/18/15.
//
//

import UIKit

class SignUpEmailViewController: UIViewController {

    
    
    //define
    private let hidePriority : UILayoutPriority = 1.0;
    private let showPriority: UILayoutPriority = 750.0;
    
    
    
    @IBOutlet weak var scrollBottomPaddingConstraint: NSLayoutConstraint!
    
    func configConstraint(show : Bool) -> Void {
        let level = show ? showPriority : hidePriority
        
//        userLeftPaddingConstraint.priority = level
//        userTopPaddingConstraint.priority = level
//        logoLeftPaddingConstraint.priority = level
//        logoTopPaddingConstraint.priority = level
//        
//        userNameTopPaddingConstraint.priority = level
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

    @IBAction func backAction(sender: UIButton) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func doneAction(sender: UIButton) {
        self.navigationController?.popToRootViewControllerAnimated(true)
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