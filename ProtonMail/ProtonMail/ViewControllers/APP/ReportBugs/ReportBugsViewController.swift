//
//  ReportBugsViewController.swift
//  Proton Mail
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import LifetimeTracker
import MBProgressHUD
import ProtonCoreHumanVerification
import ProtonCoreLog
import ProtonCoreTroubleShooting
import ProtonCoreUIFoundations
import SideMenuSwift

final class ReportBugsViewController: ProtonMailViewController, LifetimeTrackable {
    typealias Dependencies = HasSendBugReport & HasUserDefaults & HasUserManager

    class var lifetimeConfiguration: LifetimeConfiguration {
        .init(maxCount: 1)
    }

    fileprivate let textViewMinimumHeight: CGFloat = 120.0
    fileprivate let textViewInset: CGFloat = 16.0
    fileprivate let topTextViewMargin: CGFloat = 24.0

    fileprivate var sendButton: UIBarButtonItem!

    private let scrollView = UIScrollView()
    private let stackView = UIStackView.stackView(axis: .vertical, distribution: .equalSpacing)
    private let topSpacer = UIView()
    private let textView = UITextView()

    private let logAttachmentSwitch: UISwitch = {
        let isEnabled: Bool
        if let logFile = PMLog.logFile {
            isEnabled = FileManager.default.fileExists(atPath: logFile.path)
        } else {
            isEnabled = false
        }

        let switchView = UISwitch()
        switchView.onTintColor = ColorProvider.BrandNorm
        switchView.isEnabled = isEnabled
        switchView.isOn = switchView.isEnabled  // on by default if possible
        return switchView
    }()

    private let logAttachmentSwitchRow = UIStackView.stackView(alignment: .center, spacing: 8)
    private let logAttachmentSwitchRowContainer = UIView()

    private var reportSent: Bool = false

    private let doh = BackendConfiguration.shared.doh
    private let dependencies: Dependencies
    private let troubleShootingHelper: TroubleShootingHelper

    private var cachedBugReport: String {
        get {
            dependencies.userDefaults[.lastBugReport]
        }
        set {
            dependencies.userDefaults[.lastBugReport] = newValue
        }
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        troubleShootingHelper = TroubleShootingHelper(doh: doh)

        super.init(nibName: nil, bundle: nil)
        trackLifetime()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = ColorProvider.BackgroundSecondary
        self.sendButton = UIBarButtonItem(title: LocalString._general_send_action,
                                          style: UIBarButtonItem.Style.plain,
                                          target: self,
                                          action: #selector(ReportBugsViewController.sendAction(_:)))
        setUpSendButtonAttribute()
        self.navigationItem.rightBarButtonItem = sendButton

        if cachedBugReport.isEmpty {
            addPlaceholder()
        } else {
            textView.set(text: cachedBugReport, preferredFont: .body)
        }
        self.title = LocalString._menu_bugs_title

        setupMenuButton(userInfo: dependencies.user.userInfo)
        setupSubviews()
        setupLayout()
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    private func setUpSendButtonAttribute() {
        let sendButtonAttributes = FontManager.HeadlineSmall
        self.sendButton.setTitleTextAttributes(
            sendButtonAttributes.foregroundColor(ColorProvider.InteractionNormDisabled),
            for: .disabled
        )
        self.sendButton.setTitleTextAttributes(
            sendButtonAttributes.foregroundColor(ColorProvider.InteractionNorm),
            for: .normal
        )
    }

    private func setupSubviews() {
        view.addSubview(scrollView)

        self.textView.delegate = self
        self.textView.backgroundColor = ColorProvider.BackgroundNorm
        self.textView.isScrollEnabled = false
        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.textContainerInset = .init(all: textViewInset)
        setUpSideMenuMethods()

        let logAttachmentLabel = UILabel()
        logAttachmentLabel.set(text: L10n.BugReport.includeLogs, preferredFont: .body)
        [logAttachmentLabel, logAttachmentSwitch].forEach(logAttachmentSwitchRow.addArrangedSubview)

        logAttachmentSwitchRowContainer.addSubview(logAttachmentSwitchRow)

        [topSpacer, textView, logAttachmentSwitchRowContainer].forEach(stackView.addArrangedSubview)

        scrollView.addSubview(stackView)
    }

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            topSpacer.heightAnchor.constraint(equalToConstant: topTextViewMargin),

            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: textViewMinimumHeight),

            logAttachmentSwitchRow.topAnchor.constraint(
                equalTo: logAttachmentSwitchRowContainer.topAnchor,
                constant: 8
            ),
            logAttachmentSwitchRow.leadingAnchor.constraint(
                equalTo: logAttachmentSwitchRowContainer.leadingAnchor,
                constant: 8
            )
        ])

        stackView.fillSuperview()
        logAttachmentSwitchRow.centerInSuperview()
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
        setupMenuButton(userInfo: dependencies.user.userInfo)
        NotificationCenter.default.addKeyboardObserver(self)
        textView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textView.resignFirstResponder()
        NotificationCenter.default.removeKeyboardObserver(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let keywindow = UIApplication.shared.topMostWindow, self.reportSent else { return }
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

    // MARK: - Private methods

    fileprivate func addPlaceholder() {
        textView.set(text: L10n.BugReport.placeHolder, preferredFont: .body)
    }

    fileprivate func reset() {
        addPlaceholder()
        cachedBugReport = ""
        updateSendButtonForText(textView.text)
        addPlaceholder()
    }

    fileprivate func updateSendButtonForText(_ text: String?) {
        sendButton.isEnabled = (text != nil) && !text!.isEmpty && !(text! == L10n.BugReport.placeHolder)
    }

    @objc
    private func preferredContentSizeChanged() {
        textView.font = .adjustedFont(forTextStyle: .body, weight: .regular)
        setUpSendButtonAttribute()
    }

    // MARK: Actions

    @IBAction fileprivate func sendAction(_ sender: UIBarButtonItem) {
        guard let text = textView.text, !text.isEmpty else {
            return
        }

        let storeKitManager = dependencies.user.payments.storeKitManager
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

        send(text: text) { error in
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

    private func send(text: String, completion: @MainActor @escaping (NSError?) -> Void) {
        let username = String(dependencies.user.defaultEmail.split(separator: "@")[0])
        let shouldIncludeLogs = logAttachmentSwitch.isOn

        let sendBugReportParams = SendBugReport.Params(
            reportBody: text,
            userName: username,
            emailAddress: dependencies.user.defaultEmail,
            logFile: shouldIncludeLogs ? PMLog.logFile : nil
        )

        Task {
            do {
                try await dependencies.sendBugReport.execute(params: sendBugReportParams)

                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error as NSError)
                }
            }
        }
    }

    private func checkDoh(_ error: NSError) -> Bool {
        guard doh.errorIndicatesDoHSolvableProblem(error: error) else {
            return false
        }

        let message = error.localizedDescription
        let alertController = UIAlertController(title: LocalString._protonmail,
                                                message: message,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Troubleshoot", style: .default) { _ in
            self.troubleShootingHelper.showTroubleShooting(over: self)
        })
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: { action in

        }))
        present(alertController, animated: true, completion: nil)

        return true
    }
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol

extension ReportBugsViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        updateKeyboardHeight(keyboardInfo: notification.keyboardInfo)
    }

    func keyboardWillShowNotification(_ notification: Notification) {
        updateKeyboardHeight(keyboardInfo: notification.keyboardInfo)
    }

    private func updateKeyboardHeight(keyboardInfo: KeyboardInfo) {
        scrollView.contentInset.bottom = keyboardInfo.endFrame.height
    }
}

extension ReportBugsViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let oldText = textView.text as NSString
        let changedText = oldText.replacingCharacters(in: range, with: text)
        updateSendButtonForText(changedText)
        cachedBugReport = changedText
        return true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            addPlaceholder()
        }
    }
}
