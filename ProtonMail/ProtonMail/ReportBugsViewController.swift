//
//  ReportBugsViewController.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class ReportBugsViewController: ProtonMailViewController {
    
    private let bottomPadding: CGFloat = 30.0
    
    @IBOutlet weak var sendButton: UIBarButtonItem!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = cachedBugReport.cachedBug
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateSendButtonForText(textView.text)
        NSNotificationCenter.defaultCenter().addKeyboardObserver(self)
        textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        textView.resignFirstResponder()
        NSNotificationCenter.defaultCenter().removeKeyboardObserver(self)
    }
    
    // MARK: - Private methods
    
    private func reset() {
        textView.text = ""
        cachedBugReport.cachedBug = ""
        updateSendButtonForText(textView.text)
    }
    
    private func updateSendButtonForText(text: String?) {
        sendButton.enabled = (text != nil) && !text!.isEmpty
    }
    
    // MARK: Actions
    
    @IBAction private func sendAction(sender: UIBarButtonItem) {
        if let text = textView.text {
            if !text.isEmpty {
                BugDataService().reportBug(text, completion: { error in
                    if let error = error {
                        let alert = error.alertController()
                        alert.addAction(UIAlertAction(title: NSLocalizedString("OK"), style: .Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: nil)
                    } else {
                        let alert = UIAlertController(title: NSLocalizedString("Bug Report Received"), message: NSLocalizedString("Thank you for submitting a bug report.  We have added your report to our bug tracking system."), preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("OK"), style: .Default, handler: nil))
                        self.presentViewController(alert, animated: true, completion: {
                            self.reset()
                            NSNotificationCenter.defaultCenter().postNotificationName(MenuViewController.ObserverSwitchView, object: nil)
                        })
                    }
                })
            }
        }
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension ReportBugsViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        textViewBottomConstraint.constant = bottomPadding
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(notification: NSNotification) {
        let keyboardInfo = notification.keyboardInfo
        textViewBottomConstraint.constant = keyboardInfo.beginFrame.height + bottomPadding
        UIView.animateWithDuration(keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}

extension ReportBugsViewController: UITextViewDelegate {
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let oldText = textView.text as NSString
        let changedText = oldText.stringByReplacingCharactersInRange(range, withString: text)
        updateSendButtonForText(changedText)
        cachedBugReport.cachedBug = changedText
        return true
    }
}
