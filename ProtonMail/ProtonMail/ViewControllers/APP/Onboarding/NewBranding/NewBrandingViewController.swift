// Copyright (c) 2022 Proton AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import SafariServices
import UIKit

final class NewBrandingViewController: UIViewController {

    @IBOutlet private var brandingView: UIView!
    @IBOutlet private var backgroundImage: UIImageView!
    @IBOutlet private var brandIcon: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var contentTextView: UITextView!
    @IBOutlet private var gotItButton: UIButton!
    @IBOutlet private var mailLogoIcon: UIImageView!
    @IBOutlet private var calendarLogoIcon: UIImageView!
    @IBOutlet private var driveLogoIcon: UIImageView!
    @IBOutlet private var vpnLogoIcon: UIImageView!

    static func instance() -> NewBrandingViewController {
        let viewController = NewBrandingViewController(nibName: "NewBrandingViewController", bundle: nil)
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if titleLabel.preferredMaxLayoutWidth != titleLabel.bounds.width {
            titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.width
            titleLabel.setNeedsLayout()
        }
    }

    @IBAction func clickGotItButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: UI related
extension NewBrandingViewController {
    private func setupUI() {
        self.brandingView.roundCorner(8)

        self.brandIcon.image = IconProvider.mailMain
        self.backgroundImage.image = IconProvider.swirls

        let titleStyle = FontManager.body1BoldNorm.alignment(.center)
        self.titleLabel.attributedText = LocalString._brand_new_proton.apply(style: titleStyle)

        let contentStyle = FontManager.body3RegularWeak.alignment(.center)
        let content = NSMutableAttributedString(
            attributedString: LocalString._brand_new_proton_content.apply(style: contentStyle)
        )
        let learnMoreStyle = FontManager.body3RegularWeak.link(url: .rebrandingReadMoreLink)
        let learnMore = " \(LocalString._learn_more)".apply(style: learnMoreStyle)
        content.append(learnMore)
        self.contentTextView.attributedText = content
        self.contentTextView.linkTextAttributes = [.foregroundColor: ColorProvider.InteractionNorm as UIColor]
        self.contentTextView.textContainerInset = .zero
        self.contentTextView.delegate = self

        self.gotItButton.roundCorner(8)
        self.gotItButton.setTitle(LocalString._general_gotIt_button, for: .normal)

        let shadow: TempFigmaShadow = .init(
            color: ColorProvider.BrandLighten40.withAlphaComponent(0.18),
            x: 0,
            y: 5.2,
            blur: 15,
            spread: 0
        )
        self.mailLogoIcon.image = IconProvider.mailMain
        self.mailLogoIcon.layer.apply(shadow: shadow)
        self.calendarLogoIcon.image = IconProvider.calendarMain
        self.calendarLogoIcon.layer.apply(shadow: shadow)
        self.driveLogoIcon.image = IconProvider.driveMain
        self.driveLogoIcon.layer.apply(shadow: shadow)
        self.vpnLogoIcon.image = IconProvider.vpnMain
        self.vpnLogoIcon.layer.apply(shadow: shadow)
    }
}

extension NewBrandingViewController: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        let safari = SFSafariViewController(url: URL)
        self.present(safari, animated: true, completion: nil)
        return false
    }
}
