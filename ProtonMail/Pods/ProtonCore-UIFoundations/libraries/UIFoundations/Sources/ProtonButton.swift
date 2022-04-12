//
//  ProtonButton.swift
//  ProtonCore-UIFoundations - Created on 02.10.20.
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
        layer.cornerRadius = 8.0
        clipsToBounds = true
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center
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
            setTitleColor(ColorProvider.BrandLighten40, for: .disabled)
            titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
            updateOutline()
            layer.borderWidth = 1
            contentEdgeInsets = UIEdgeInsets(top: 12, left: 36, bottom: 12, right: 36)
        case .text:
            nonSolidLayout()
            setTitleColor(ColorProvider.TextDisabled, for: .disabled)
            titleLabel?.font = UIFont.systemFont(ofSize: 15.0)
            contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        }
        layoutIfNeeded()
    }

    fileprivate func solidLayout() {
        setTitleColor(ProtonColorPallete.White, for: .normal)
        setTitleColor(ProtonColorPallete.White, for: .highlighted)
        setTitleColor(ProtonColorPallete.White, for: .selected)
        setTitleColor(ProtonColorPallete.White.withAlphaComponent(0.4), for: .disabled)
        setBackgroundColor(ColorProvider.BrandNorm, forState: .normal)
        setBackgroundColor(ColorProvider.BrandDarken20, forState: .highlighted)
        setBackgroundColor(ColorProvider.BrandDarken20, forState: .selected)
        setBackgroundColor(ColorProvider.BrandLighten40, forState: .disabled)
    }

    fileprivate func nonSolidLayout() {
        setTitleColor(ColorProvider.BrandNorm, for: .normal)
        setTitleColor(ColorProvider.BrandDarken20, for: .highlighted)
        setTitleColor(ColorProvider.BrandDarken20, for: .selected)
        setBackgroundColor(.clear, forState: .normal)
        setBackgroundColor(ColorProvider.BackgroundSecondary, forState: .highlighted)
        setBackgroundColor(ColorProvider.BackgroundSecondary, forState: .selected)
        setBackgroundColor(ColorProvider.BackgroundNorm, forState: .disabled)
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
