//
//  PMActionSheetHeaderView.swift
//  ProtonCore-UIFoundations - Created on 17.07.20.
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

public final class PMActionSheetHeaderView: UIView {

    // MARK: Constant
    private let TITLE_PADDING: CGFloat = 63
    private let MAX_TEXT_BUTTON_SIZE: CGFloat = 120
    private let MIN_TEXT_BUTTON_SIZE: CGFloat = 44
    private let MIN_ICON_BUTTON_SIZE: CGFloat = 24

    // MARK: Customize variable
    private var leftItem: PMActionSheetPlainItem?
    private var rightItem: PMActionSheetPlainItem?
    private var title: String?
    private var subtitle: String?

    /// Initializer of `PMActionSheetHeaderView`
    /// - Parameters:
    ///   - title: Title of action sheet
    ///   - subtitle: Subtitle of action sheet
    ///   - leftItem: Left item of header view, if `title` set, `icon` will be ignored
    ///   - rightItem: Right item of header view, if `title` set, `icon` will be ignored
    public convenience init(title: String, subtitle: String?,
                            leftItem: PMActionSheetPlainItem?,
                            rightItem: PMActionSheetPlainItem?,
                            hasSeparator: Bool = false) {
        self.init(frame: .zero)
        self.leftItem = leftItem
        self.rightItem = rightItem
        self.title = title
        self.subtitle = subtitle
        self.setup(hasSeparator: hasSeparator)
    }

    override private init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
}

// MARK: UI Relative
extension PMActionSheetHeaderView {
    private func setup(hasSeparator: Bool = false) {
        guard self.title != nil else { return }
        self.backgroundColor = ColorProvider.BackgroundNorm
        let titleView = self.createTitleView()
        self.setupTitleViewConstraint(titleView)
        // swiftlint:disable:next sorted_first_last
        let refTitle = titleView.arrangedSubviews.sorted(by: { $0.frame.size.width >=  $1.frame.size.width }).first
        self.setupItem(item: self.leftItem,
                       isRightBtn: false,
                       refTitle: refTitle)
        self.setupItem(item: self.rightItem,
                       isRightBtn: true,
                       refTitle: refTitle)
        if hasSeparator {
            self.addLine()
        }
    }

    private func createTitleView() -> UIStackView {
        let stack = UIStackView(.vertical, alignment: .center, distribution: .fillProportionally, useAutoLayout: true)

        if let title = self.title {
            let fontSize: CGFloat = self.subtitle == nil ? 17: 15
            let font: UIFont = .systemFont(ofSize: fontSize, weight: .semibold)
            let color: UIColor = ColorProvider.TextNorm
            let lbl = UILabel(title, font: font, textColor: color)
            lbl.sizeToFit()
            stack.addArrangedSubview(lbl)
        }

        if let subtitle = self.subtitle {
            let font: UIFont = .systemFont(ofSize: 12)
            let color: UIColor = ColorProvider.TextWeak
            let lbl = UILabel(subtitle, font: font, textColor: color)
            lbl.numberOfLines = 2
            lbl.textAlignment = .center
            lbl.sizeToFit()
            stack.addArrangedSubview(lbl)
        }
        return stack
    }

    private func setupTitleViewConstraint(_ container: UIStackView) {
        self.addSubview(container)
        container.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: 4).isActive = true
        container.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: TITLE_PADDING).isActive = true
        container.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -1 * TITLE_PADDING).isActive = true
        container.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -4).isActive = true
        container.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }

    private func setupItem(item: PMActionSheetPlainItem?,
                           isRightBtn: Bool,
                           refTitle: UIView?) {
        guard let btn = self.createButton(item: item, isRightBtn: isRightBtn) else { return }
        self.addSubview(btn)
        btn.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

        if isRightBtn {
            btn.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16).isActive = true
            if let refTitle = refTitle {
                btn.leadingAnchor.constraint(greaterThanOrEqualTo: refTitle.trailingAnchor, constant: 8).isActive = true
            }
        } else {
            btn.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16).isActive = true
            if let refTitle = refTitle {
                btn.trailingAnchor.constraint(lessThanOrEqualTo: refTitle.leadingAnchor, constant: -8).isActive = true
            }
        }
    }

    private func createButton(item: PMActionSheetPlainItem?, isRightBtn: Bool) -> UIButton? {
        guard let _item = item else { return nil }
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        if let title = _item.title {
            btn.setTitle(title, for: .normal)
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.setTitleColor(_item.textColor, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            btn.widthAnchor.constraint(greaterThanOrEqualToConstant: MIN_TEXT_BUTTON_SIZE).isActive = true
            btn.widthAnchor.constraint(lessThanOrEqualToConstant: MAX_TEXT_BUTTON_SIZE).isActive = true
        } else if let icon = _item.icon {
            btn.setImage(icon, for: .normal)
            btn.tintColor = _item.textColor
            btn.widthAnchor.constraint(greaterThanOrEqualToConstant: MIN_ICON_BUTTON_SIZE).isActive = true
        }
        if isRightBtn {
            btn.contentHorizontalAlignment = .right
            btn.tag = 10
        } else {
            btn.contentHorizontalAlignment = .left
            btn.tag = 20
        }
        btn.addTarget(self, action: #selector(self.clickButton(sender:)), for: .touchUpInside)
        return btn
    }

    private func addLine() {
        let line = UIView()
        line.backgroundColor = ColorProvider.SeparatorNorm
        line.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(line)
        NSLayoutConstraint.activate([
            line.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            line.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            line.heightAnchor.constraint(equalToConstant: 1)
        ])

    }
}

extension PMActionSheetHeaderView {
    @objc private func clickButton(sender: UIButton) {
        let item = sender.tag == 10 ? self.rightItem: self.leftItem
        guard let _item = item,
            let handler = _item.handler else { return }
        handler(_item)
    }
}
