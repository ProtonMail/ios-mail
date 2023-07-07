// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCore_UIFoundations
import UIKit

extension ESIndexingInformationBanner {
    enum Target {
        case infoPage, storageSetting

        var link: String {
            switch self {
            case .infoPage:
                return "pm://search.info"
            case .storageSetting:
                return "pm://search.storage.settings"
            }
        }
    }
}

final class ESIndexingInformationBanner: UITableViewHeaderFooterView {
    static let identifier = "ESIndexingInformationBanner"
    private let greyBackground = SubviewFactory.greyBackground()
    private let contentTextView = SubviewFactory.contentTextView()
    private let closeButton = SubviewFactory.closeButton()
    var closeClosure: (() -> Void)?
    var openPage: ((Target) -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubviews()
        layoutComponents()
        setUpActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateView(
        for state: EncryptedSearchIndexState,
        oldestMessageDateInSearchIndex: Date
    ) {
        var text = ""
        var link = ""
        var target = Target.infoPage
        switch state {
        case .creatingIndex, .downloadingNewMessage:
            text = L11n.EncryptedSearch.searchInfo_downloading
            link = L11n.EncryptedSearch.searchInfo_downloading_link
        case .paused(let reason):
            text = L11n.EncryptedSearch.searchInfo_paused
            link = L11n.EncryptedSearch.searchInfo_paused_link
            if let reason {
                switch reason {
                case .lowStorage:
                    let date = PMDateFormatter.shared.string(
                        from: oldestMessageDateInSearchIndex,
                        weekStart: .automatic
                    )
                    text = String(format: L11n.EncryptedSearch.searchInfo_lowStorage, date)
                    link = ""
                default:
                    break
                }
            }
        case .partial:  // storage limit reached
            let date = PMDateFormatter.shared.string(
                from: oldestMessageDateInSearchIndex,
                weekStart: .automatic
            )
            text = "\(L11n.EncryptedSearch.searchInfo_partial_prefix)\(date)\(L11n.EncryptedSearch.searchInfo_partial_suffix)"
            link = L11n.EncryptedSearch.searchInfo_partial_link
            target = Target.storageSetting
        default:
            PMAssertionFailureIfBackendIsProduction("Unexpected ES index state")
        }
        setUpContentTextView(text: text, link: link, target: target)
    }

    private func setUpContentTextView(text: String, link: String, target: Target) {
        let message = String(format: text, link)
        let attributed = NSMutableAttributedString(string: message, attributes: [
            .foregroundColor: ColorProvider.TextWeak as UIColor,
            .font: UIFont.adjustedFont(forTextStyle: .subheadline)
        ])

        let linkRange = (message as NSString).range(of: link)
        attributed.addAttributes([.link: target.link], range: linkRange)
        let linkColor: UIColor = ColorProvider.BrandNorm
        let linkAttr: [NSAttributedString.Key: Any] = [.foregroundColor: linkColor]
        contentTextView.linkTextAttributes = linkAttr
        // Somehow the set(text:preferredFont:...) doesn't work here
        contentTextView.attributedText = attributed
    }

    private func addSubviews() {
        contentView.addSubview(greyBackground)
        greyBackground.addSubview(contentTextView)
        greyBackground.addSubview(closeButton)
    }

    private func layoutComponents() {
        [
            greyBackground.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            greyBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            greyBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            greyBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ].activate()

        [
            closeButton.trailingAnchor.constraint(equalTo: greyBackground.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: greyBackground.centerYAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            closeButton.widthAnchor.constraint(equalToConstant: 24)
        ].activate()

        [
            contentTextView.topAnchor.constraint(equalTo: greyBackground.topAnchor, constant: 16),
            contentTextView.leadingAnchor.constraint(equalTo: greyBackground.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            contentTextView.bottomAnchor.constraint(equalTo: greyBackground.bottomAnchor, constant: -16)
        ].activate()
    }

    private func setUpActions() {
        closeButton.addTarget(self, action: #selector(self.clickCloseButton), for: .touchUpInside)
        contentTextView.delegate = self
    }

    @objc
    private func clickCloseButton() {
        guard let closure = closeClosure else {
            PMAssertionFailure("Didn't set closure")
            return
        }
        closure()
    }

    private enum SubviewFactory {
        static func greyBackground() -> UIView {
            let view = UIView(frame: .zero)
            view.backgroundColor = ColorProvider.BackgroundSecondary
            view.roundCorner(8)
            return view
        }

        static func contentTextView() -> UITextView {
            let textView = UITextView(frame: .zero)
            textView.backgroundColor = .clear
            textView.isScrollEnabled = false
            textView.isEditable = false
            textView.adjustsFontForContentSizeCategory = true
            return textView
        }

        static func closeButton() -> UIButton {
            let button = UIButton(image: IconProvider.cross)
            button.tintColor = ColorProvider.IconNorm
            return button
        }
    }
}

extension ESIndexingInformationBanner: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        guard let closure = openPage else {
            PMAssertionFailure("Didn't set closure")
            return false
        }
        switch URL.absoluteString {
        case Target.infoPage.link:
            closure(.infoPage)
        case Target.storageSetting.link:
            closure(.storageSetting)
        default:
            break
        }
        return false
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        textView.selectedTextRange = nil
    }
}
