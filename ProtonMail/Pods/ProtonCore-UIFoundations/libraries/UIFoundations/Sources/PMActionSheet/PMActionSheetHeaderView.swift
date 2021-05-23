//
//  PMActionSheetHeaderView.swift
//  ProtonMail - Created on 17.07.20.
//
//  Copyright (c) 2020 Proton Technologies AG
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
//

import UIKit

public final class PMActionSheetHeaderView: UIView {

    // MARK: Constant
    private let TITLE_PADDING: CGFloat = 63
    private let MAX_BUTTON_SIZE: CGFloat = 57

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
        self.backgroundColor = BackgroundColors._Main
        let titleView = self.createTitleView()
        self.setupTitlViewConstraint(titleView)
        self.setupItem(item: self.leftItem, isRightBtn: false)
        self.setupItem(item: self.rightItem, isRightBtn: true)
        if hasSeparator {
            self.addLine()
        }
    }

    private func createTitleView() -> UIStackView {
        let stack = UIStackView(.vertical, alignment: .center, distribution: .fillProportionally, useAutoLayout: true)

        if let title = self.title {
            let font: UIFont = .boldSystemFont(ofSize: 17)
            let color: UIColor = AdaptiveTextColors._N5
            let lbl = UILabel(title, font: font, textColor: color)
            stack.addArrangedSubview(lbl)
        }

        if let subtitle = self.subtitle {
            let font: UIFont = .systemFont(ofSize: 15)
            let color: UIColor = AdaptiveTextColors._N3
            let lbl = UILabel(subtitle, font: font, textColor: color)
            lbl.numberOfLines = 2
            lbl.textAlignment = .center
            stack.addArrangedSubview(lbl)
        }
        return stack
    }

    private func setupTitlViewConstraint(_ container: UIStackView) {
        self.addSubview(container)
        container.topAnchor.constraint(equalTo: self.topAnchor, constant: 13).isActive = true
        container.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: TITLE_PADDING).isActive = true
        container.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -1 * TITLE_PADDING).isActive = true
        container.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -9).isActive = true
    }

    private func setupItem(item: PMActionSheetPlainItem?, isRightBtn: Bool) {
        guard let btn = self.createButton(item: item, isRightBtn: isRightBtn) else { return }
        self.addSubview(btn)
        btn.heightAnchor.constraint(lessThanOrEqualToConstant: MAX_BUTTON_SIZE).isActive = true
        btn.widthAnchor.constraint(lessThanOrEqualToConstant: MAX_BUTTON_SIZE).isActive = true
        btn.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        let size = btn.sizeThatFits(CGSize(width: MAX_BUTTON_SIZE,
                                           height: MAX_BUTTON_SIZE))
        let width = min(size.width, MAX_BUTTON_SIZE)
        let padding = (TITLE_PADDING - width) / 2
        if isRightBtn {
            btn.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -1 * padding).isActive = true
        } else {
            btn.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: padding).isActive = true
        }
    }

    private func createButton(item: PMActionSheetPlainItem?, isRightBtn: Bool) -> UIButton? {
        guard let _item = item else { return nil }
        let btn = UIButton()
        btn.translatesAutoresizingMaskIntoConstraints = false
        if let title = _item.title {
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(_item.textColor, for: .normal)
        } else if let icon = _item.icon {
            btn.setImage(icon, for: .normal)
            btn.tintColor = _item.textColor
        }
        btn.tag = isRightBtn ? 10: 20
        btn.addTarget(self, action: #selector(self.clickButton(sender:)), for: .touchUpInside)
        return btn
    }

    private func addLine() {
        let line = UIView()
        line.backgroundColor = AdaptiveColors._N2
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
