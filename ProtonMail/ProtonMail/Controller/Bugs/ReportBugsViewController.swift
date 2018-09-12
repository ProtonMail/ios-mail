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
    
    fileprivate let bottomPadding: CGFloat = 30.0
    
    fileprivate var sendButton: UIBarButtonItem!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topTitleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sendButton = UIBarButtonItem(title: LocalString._general_send_action,
                                          style: UIBarButtonItemStyle.plain,
                                          target: self,
                                          action: #selector(ReportBugsViewController.sendAction(_:)))
        self.navigationItem.rightBarButtonItem = sendButton
        
        textView.text = cachedBugReport.cachedBug
        
        topTitleLabel.text = LocalString._bug_description
        self.title = LocalString._menu_bugs_title
        
        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.textContainerInset = .zero
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSendButtonForText(textView.text)
        NotificationCenter.default.addKeyboardObserver(self)
        textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textView.resignFirstResponder()
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    // MARK: - Private methods
    
    fileprivate func reset() {
        textView.text = ""
        cachedBugReport.cachedBug = ""
        updateSendButtonForText(textView.text)
    }
    
    fileprivate func updateSendButtonForText(_ text: String?) {
        sendButton.isEnabled = (text != nil) && !text!.isEmpty
    }
    
    // MARK: Actions
    
    @IBAction fileprivate func sendAction(_ sender: UIBarButtonItem) {
        if let text = textView.text {
            if !text.isEmpty {
                ActivityIndicatorHelper.showActivityIndicator(at: view)
                sender.isEnabled = false
                BugDataService().reportBug(text, completion: { error in
                    ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
                    sender.isEnabled = true
                    if let error = error {
                        let alert = error.alertController()
                        alert.addAction(UIAlertAction(title: LocalString._general_ok_action, style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        let alert = UIAlertController(title: LocalString._bug_report_received,
                                                      message: LocalString._thank_you_for_submitting_a_bug_report_we_have_added_your_report_to_our_bug_tracking_system,
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: LocalString._general_ok_action, style: .default, handler: nil))
                        self.present(alert, animated: true, completion: {
                            self.reset()
                            NotificationCenter.default.post(name: .switchView,
                                                            object: nil)
                        })
                    }
                })
            }
        }
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension ReportBugsViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        textViewBottomConstraint.constant = bottomPadding
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        textViewBottomConstraint.constant = keyboardInfo.beginFrame.height + bottomPadding
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}

extension ReportBugsViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let oldText = textView.text as NSString
        let changedText = oldText.replacingCharacters(in: range, with: text)
        updateSendButtonForText(changedText)
        cachedBugReport.cachedBug = changedText
        return true
    }
}
