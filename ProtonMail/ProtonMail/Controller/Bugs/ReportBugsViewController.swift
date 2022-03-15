//
//  ReportBugsViewController.swift
//  ProtonMail
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

import Foundation
import MBProgressHUD
import SideMenuSwift
import ProtonCore_Payments
import ProtonCore_UIFoundations
import Reachability

class ReportBugsViewController: ProtonMailViewController {
    var user: UserManager!
    fileprivate let bottomPadding: CGFloat = 30.0
    fileprivate let textViewDefaultHeight: CGFloat = 120.0
    fileprivate var beginningVerticalPositionOfKeyboard: CGFloat = 30.0
    fileprivate let textViewInset: CGFloat = 16.0
    fileprivate let topTextViewMargin: CGFloat = 24.0

    fileprivate var sendButton: UIBarButtonItem!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!

    private var kSegueToTroubleshoot: String = "toTroubleShootSegue"
    private var reportSent: Bool = false

    class func instance() -> ReportBugsViewController {
        let board = UIStoryboard.Storyboard.inbox.storyboard
        let vc = board.instantiateViewController(withIdentifier: "ReportBugsViewController") as! ReportBugsViewController
        _ = UINavigationController(rootViewController: vc)
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorProvider.BackgroundSecondary
        self.sendButton = UIBarButtonItem(title: LocalString._general_send_action,
                                          style: UIBarButtonItem.Style.plain,
                                          target: self,
                                          action: #selector(ReportBugsViewController.sendAction(_:)))
        let sendButtonAttributes = FontManager.HeadlineSmall
        self.sendButton.setTitleTextAttributes(
            sendButtonAttributes.foregroundColor(ColorProvider.InteractionNormDisabled),
            for: .disabled
        )
        self.sendButton.setTitleTextAttributes(
            sendButtonAttributes.foregroundColor(ColorProvider.InteractionNorm),
            for: .normal
        )
        self.navigationItem.rightBarButtonItem = sendButton

        if cachedBugReport.cachedBug.isEmpty {
            addPlaceholder()
        } else {
            removePlaceholder()
            textView.attributedText = cachedBugReport.cachedBug.apply(style: FontManager.Default)
        }
        self.title = LocalString._menu_bugs_title

        self.textView.backgroundColor = ColorProvider.BackgroundNorm
        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.textContainerInset = .init(all: textViewInset)
        setUpSideMenuMethods()
    }

    private func setUpSideMenuMethods() {
        let pmSideMenuController = sideMenuController as? PMSideMenuController
        pmSideMenuController?.willHideMenu = { [weak self] in
            self?.textView.becomeFirstResponder()
        }

        pmSideMenuController?.willRevealMenu = { [weak self] in
            self?.textView.resignFirstResponder()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSendButtonForText(textView.text)
        NotificationCenter.default.addKeyboardObserver(self)
        textView.becomeFirstResponder()
        resizeHeightIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textView.resignFirstResponder()
        NotificationCenter.default.removeKeyboardObserver(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let keywindow = UIApplication.shared.keyWindow, self.reportSent else { return }
        keywindow.enumerateViewControllerHierarchy { (controller, stop) in
            guard controller is MenuViewController else {return}
            let alert = UIAlertController(title: LocalString._bug_report_received,
                                          message: LocalString._thank_you_for_submitting_a_bug_report_we_have_added_your_report_to_our_bug_tracking_system,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: LocalString._general_ok_action, style: .default, handler: { (_) in

            }))
            controller.present(alert, animated: true, completion: {

            })

            stop = true
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizeHeightIfNeeded()
    }

    // MARK: - Private methods

    fileprivate func addPlaceholder() {
        textView.attributedText = LocalString._bug_description.apply(style: FontManager.Default.foregroundColor(ColorProvider.TextHint))
    }

    fileprivate func removePlaceholder() {
        textView.attributedText = .init()
        textView.typingAttributes = FontManager.Default
    }

    fileprivate func reset() {
        removePlaceholder()
        cachedBugReport.cachedBug = ""
        updateSendButtonForText(textView.text)
        resizeHeightIfNeeded()
        addPlaceholder()
    }

    fileprivate func updateSendButtonForText(_ text: String?) {
        sendButton.isEnabled = (text != nil) && !text!.isEmpty && !(text! == LocalString._bug_description)
    }

    // MARK: Actions

    @IBAction fileprivate func sendAction(_ sender: UIBarButtonItem) {
        guard let text = textView.text, !text.isEmpty else {
            return
        }

        let storeKitManager = self.user.payments.storeKitManager
        if storeKitManager.hasUnfinishedPurchase(),
            let receipt = try? storeKitManager.readReceipt() {
            let alert = UIAlertController(title: LocalString._iap_bugreport_title, message: LocalString._iap_bugreport_user_agreement, preferredStyle: .alert)
            alert.addAction(.init(title: LocalString._iap_bugreport_yes, style: .default, handler: { _ in
                self.send(text + "\n\n\n --- AppStore receipt: ---\n\n\(receipt)")
            }))
            alert.addAction(.init(title: LocalString._iap_bugreport_no, style: UIAlertAction.Style.cancel, handler: { _ in
                self.send(text)
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.send(text)
        }
    }

    private func send(_ text: String) {
        let v: UIView = self.navigationController?.view ?? self.view
        MBProgressHUD.showAdded(to: v, animated: true)
        sendButton.isEnabled = false
        let username = self.user.defaultEmail.split(separator: "@")[0]
        let reachabilityStatus: String = (try? Reachability().connection.description) ?? Reachability.Connection.unavailable.description
        user.reportService.reportBug(text,
                                     username: String(username),
                                     email: self.user.defaultEmail,
                                     lastReceivedPush: SharedUserDefaults().lastReceivedPushTimestamp,
                                     reachabilityStatus: reachabilityStatus) { error in
            MBProgressHUD.hide(for: v, animated: true)
            self.sendButton.isEnabled = true
            if let error = error {
                guard !self.checkDoh(error), !error.isBadVersionError else {
                    return
                }
                let alert = error.alertController(title: LocalString._offline_bug_report)
                alert.addAction(UIAlertAction(title: LocalString._general_ok_action, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.reportSent = true
                self.reset()
                NotificationCenter.default.post(name: .switchView, object: nil)
            }
        }
    }

    private func checkDoh(_ error: NSError) -> Bool {
        let code = error.code
        guard DoHMail.default.codeCheck(code: code) else {
            return false
        }

        let message = error.localizedDescription
        let alertController = UIAlertController(title: LocalString._protonmail,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Troubleshoot", style: .default, handler: { action in
            self.performSegue(withIdentifier: self.kSegueToTroubleshoot, sender: nil)
        }))
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: { action in

        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)

        return true
    }

    fileprivate func resizeHeightIfNeeded() {
        let maxTextViewSize = CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
        let wantedHeightAfterVerticalGrowth = textView.sizeThatFits(maxTextViewSize).height
        if wantedHeightAfterVerticalGrowth < textViewDefaultHeight {
            textViewHeightConstraint.constant = textViewDefaultHeight
        } else {
            let heightMinusKeyboard = view.bounds.height - topTextViewMargin - beginningVerticalPositionOfKeyboard
            textViewHeightConstraint.constant = min(wantedHeightAfterVerticalGrowth + textViewInset * 2, heightMinusKeyboard)
        }
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension ReportBugsViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        beginningVerticalPositionOfKeyboard = bottomPadding
        resizeHeightIfNeeded()
        UIView.animate(withDuration: keyboardInfo.duration, delay: 0, options: keyboardInfo.animationOption, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }, completion: nil)
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        beginningVerticalPositionOfKeyboard = view.window?.convert(keyboardInfo.endFrame, to: view).origin.y ?? bottomPadding
        resizeHeightIfNeeded()
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
        resizeHeightIfNeeded()
        return true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == LocalString._bug_description {
            removePlaceholder()
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            addPlaceholder()
        }
    }
}
