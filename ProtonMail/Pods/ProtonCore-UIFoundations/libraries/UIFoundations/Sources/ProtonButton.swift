//
//  ProtonButton.swift
//  ProtonMail - Created on 02.10.20.
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

public class ProtonButton: UIButton {

    public enum ProtonButtonMode {
        case solid
        case outlined
        case text
    }

    var mode: ProtonButtonMode = .solid { didSet { modeConfiguration() } }
    var activityIndicator: UIActivityIndicatorView?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configuration()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        configuration()
    }

    init() {
        super.init(frame: .zero)
        configuration()
    }

    public func setMode(mode: ProtonButtonMode) {
        self.mode = mode
    }

    override public var isSelected: Bool {
        willSet {
            newValue ? showLoading() : stopLoading()
        }
        didSet {
            updateOutline()
        }
    }
    override public var isHighlighted: Bool { didSet { updateOutline() } }
    override public var isEnabled: Bool { didSet { updateOutline() } }

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: self.bounds.width, height: 48)
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        modeConfiguration()
    }

    fileprivate func configuration() {
        layer.cornerRadius = 3.0
        clipsToBounds = true
        modeConfiguration()
    }

    fileprivate func modeConfiguration() {
        switch mode {
        case .solid:
            solidLayout()
            titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
            contentEdgeInsets = UIEdgeInsets(top: 12, left: 36, bottom: 12, right: 36)
        case .outlined:
            nonSolidLayout()
            setTitleColor(UIColorManager.BrandLighten40, for: .disabled)
            titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
            updateOutline()
            layer.borderWidth = 1
            contentEdgeInsets = UIEdgeInsets(top: 12, left: 36, bottom: 12, right: 36)
        case .text:
            nonSolidLayout()
            setTitleColor(UIColorManager.TextDisabled, for: .disabled)
            titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
            contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        }
    }

    fileprivate func solidLayout() {
        setTitleColor(UIColorManager.TextInverted, for: .normal)
        setTitleColor(UIColorManager.TextInverted, for: .highlighted)
        setTitleColor(UIColorManager.TextInverted, for: .selected)
        setTitleColor(UIColorManager.TextInverted.withAlphaComponent(0.4), for: .disabled)
        setBackgroundColor(UIColorManager.BrandNorm, forState: .normal)
        setBackgroundColor(UIColorManager.BrandDarken20, forState: .highlighted)
        setBackgroundColor(UIColorManager.BrandDarken20, forState: .selected)
        setBackgroundColor(UIColorManager.BrandLighten40, forState: .disabled)
    }

    fileprivate func nonSolidLayout() {
        setTitleColor(UIColorManager.BrandNorm, for: .normal)
        setTitleColor(UIColorManager.BrandDarken20, for: .highlighted)
        setTitleColor(UIColorManager.BrandDarken20, for: .selected)
        setBackgroundColor(UIColorManager.BackgroundNorm, forState: .normal)
        setBackgroundColor(UIColorManager.BackgroundSecondary, forState: .highlighted)
        setBackgroundColor(UIColorManager.BackgroundSecondary, forState: .selected)
        setBackgroundColor(UIColorManager.BackgroundNorm, forState: .disabled)
    }

    fileprivate func updateOutline() {
        if mode == .outlined {
            layer.borderColor = titleColor(for: state)?.cgColor
        }
    }

    fileprivate func showLoading() {
        contentEdgeInsets = UIEdgeInsets(top: contentEdgeInsets.top, left: 40, bottom: contentEdgeInsets.bottom, right: 40)
        if let activityIndicator = activityIndicator {
            activityIndicator.startAnimating()
        } else {
            createActivityIndicator()
        }
        isUserInteractionEnabled = false
    }

    fileprivate func stopLoading() {
        modeConfiguration()
        activityIndicator?.stopAnimating()
        isUserInteractionEnabled = true
    }

    fileprivate func createActivityIndicator() {
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator?.color = titleColor(for: state)
        } else {
            activityIndicator = UIActivityIndicatorView(style: mode == .solid ? .white : .gray)
        }
        guard let activityIndicator = activityIndicator else { return }
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        bringSubviewToFront(activityIndicator)

        trailingAnchor.constraint(equalTo: activityIndicator.trailingAnchor, constant: activityIndicator.bounds.width).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        layoutIfNeeded()
    }
}
