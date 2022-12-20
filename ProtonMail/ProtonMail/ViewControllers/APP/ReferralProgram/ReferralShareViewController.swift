// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import CoreServices
import ProtonCore_UIFoundations
import UIKit
import UniformTypeIdentifiers

final class ReferralShareViewController: UIViewController {
    let customView: ReferralShareView = ReferralShareView()
    private let referralLink: String
    private let notificationCenter: NotificationCenter

    init(
        referralLink: String,
        notificationCenter: NotificationCenter = NotificationCenter.default
    ) {
        self.referralLink = referralLink
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalString._menu_refer_a_friend
        setUpCloseButton(showCloseButton: true, action: #selector(self.dismissView))
        setupView()
        setupActions()

        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(preferredContentSizeChanged(_:)),
                         name: UIContentSizeCategory.didChangeNotification,
                         object: nil)
    }

    private func setupView() {
        customView.linkTextField.text = referralLink
    }

    private func setupActions() {
        customView.linkShareButton.addTarget(
            self,
            action: #selector(self.copyLinkToClipboard),
            for: .touchUpInside
        )
        customView.shareButton.addTarget(
            self,
            action: #selector(self.shareLink),
            for: .touchUpInside
        )
        customView.trackRewardButton.addTarget(
            self,
            action: #selector(self.openTrackRewards),
            for: .touchUpInside
        )
        customView.termsAndConditionButton.addTarget(
            self,
            action: #selector(self.openTermsAndConditions),
            for: .touchUpInside
        )
    }

    private func openLink(_ link: String) {
        let deepLink = DeepLink(.toWebBrowser, sender: link)
        notificationCenter.post(name: .switchView, object: deepLink)
    }

    // MARK: - Actions

    @objc
    private func dismissView() {
        dismiss(animated: true)
    }

    @objc
    private func copyLinkToClipboard() {
        if #available(iOS 14.0, *) {
            UIPasteboard.general.setValue(
                referralLink,
                forPasteboardType: UTType.plainText.identifier)
        } else {
            UIPasteboard.general.setValue(
                referralLink,
                forPasteboardType: kUTTypePlainText as String)
        }
        let banner = PMBanner(
            message: L11n.ReferralProgram.linkCopied,
            style: PMBannerNewStyle.info
        )
        banner.show(at: .bottom, on: self)
    }

    @objc
    private func shareLink(_ sender: UIButton) {
        let shareContent = "\(L11n.ReferralProgram.shareContent) \(referralLink)"
        let activityVC = UIActivityViewController(
            activityItems: [shareContent],
            applicationActivities: nil
        )
        activityVC.popoverPresentationController?.sourceView = sender
        activityVC.popoverPresentationController?.sourceRect = sender.frame
        present(activityVC, animated: true, completion: nil)
    }

    @objc
    private func openTrackRewards() {
        openLink(Link.ReferralProgram.trackYourRewards)
    }

    @objc
    private func openTermsAndConditions() {
        openLink(Link.ReferralProgram.referralTermsAndConditions)
    }

    @objc
    private func preferredContentSizeChanged(_ notification: Notification) {
        // The following elements can't reflect font size changed automatically
        // Reset font when event happened
        customView.setupFont()
    }
}
