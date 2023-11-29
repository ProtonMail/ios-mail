//
//  ProtonButton.swift
//  ProtonCore-UIFoundations - Created on 02.10.20.
//
//  Copyright (c) 2022 Proton Technologies AG
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

#if os(iOS)

import UIKit
import ProtonCoreFoundations

public class ProtonButton: UIButton, AccessibleView {
    
    public enum ImageType: Equatable {
        case textWithImage(image: UIImage?)
        case textWithChevron
        case chevron
    }

    public enum ProtonButtonMode: Equatable {
        case solid
        case outlined
        case text
        case image(type: ImageType)
    }

    var mode: ProtonButtonMode = .solid { didSet { modeConfiguration() } }
    var activityIndicator: UIActivityIndicatorView?
    private var rightHandImage: UIImageView?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        setup()
    }

    init() {
        super.init(frame: .zero)
        setup()
    }

    public func setMode(mode: ProtonButtonMode) {
        self.mode = mode
        if isChevron {
            animateChevron(isSelected: false, animated: false)
        }
    }

    override public var isSelected: Bool {
        willSet {
            switch mode {
            case .solid, .outlined, .text:
                newValue ? showLoading() : stopLoading()
            case .image:
                if isChevron {
                    animateChevron(isSelected: newValue, animated: true)
                }
            }
        }
        didSet {
            dynamicUpdate()
        }
    }
    override public var isHighlighted: Bool { didSet { dynamicUpdate() } }
    override public var isEnabled: Bool { didSet { dynamicUpdate() } }

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: self.bounds.width, height: 48)
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        modeConfiguration()
    }

    private func setup() {
        clipsToBounds = true
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.textAlignment = .center
        modeConfiguration()
        generateAccessibilityIdentifiers()
    }

    private func modeConfiguration() {
        switch Brand.currentBrand {
        case .proton, .vpn:
            layer.cornerRadius = 8.0
        case .pass:
            layer.cornerRadius = 24.0
        }
        switch mode {
        case .solid:
            solidLayout()
            titleLabel?.font = .adjustedFont(forTextStyle: .body)
            updateEdgeInsets(top: 12, leading: 36, bottom: 12, trailing: 36)
        case .outlined:
            nonSolidLayout()
            setTitleColor(ColorProvider.BrandLighten40, for: .disabled)
            titleLabel?.font = .adjustedFont(forTextStyle: .body)
            dynamicUpdate()
            layer.borderWidth = 1
            updateEdgeInsets(top: 12, leading: 36, bottom: 12, trailing: 36)
        case .text:
            nonSolidLayout()
            setTitleColor(ColorProvider.TextDisabled, for: .disabled)
            titleLabel?.font = .adjustedFont(forTextStyle: .subheadline)
            updateEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        case .image(let type):
            let isImageOnly = type == .chevron
            imageLayout(isImageOnly: isImageOnly)
            dynamicUpdate()
            layer.masksToBounds = true
            titleLabel?.font = .adjustedFont(forTextStyle: .body)
            titleLabel?.minimumScaleFactor = 0.5
            titleLabel?.textAlignment = .natural
            contentHorizontalAlignment = .leading
            switch type {
            case .textWithChevron, .chevron:
                applyImage(image: IconProvider.chevronDown, isImageOnly: isImageOnly)
            case .textWithImage(image: let image):
                applyImage(image: image, isImageOnly: isImageOnly)
            }
            dynamicUpdate()
        }
    }
    
    private func applyImage(image: UIImage?, isImageOnly: Bool) {
        if let rightImage = createRightImage(image: image, isImageOnly: isImageOnly) {
            rightImage.tintColor = ColorProvider.IconNorm
            updateEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 36)
        } else {
            updateEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        }
    }
    
    private func updateEdgeInsets(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
        if #available(iOS 15.0, *), var configuration = configuration {
            configuration.contentInsets = .init(top: top, leading: leading, bottom: bottom, trailing: trailing)
            self.configuration = configuration
        } else {
            contentEdgeInsets = UIEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
        }
    }

    private func solidLayout() {
        setTitleColor(ColorProvider.White, for: .normal)
        setTitleColor(ColorProvider.White, for: .highlighted)
        setTitleColor(ColorProvider.White, for: .selected)
        setTitleColor(ColorProvider.White.withAlphaComponent(0.4), for: .disabled)
        switch Brand.currentBrand {
        case .proton, .vpn:
            setBackgroundColor(ColorProvider.InteractionNorm, forState: .normal)
        case .pass:
            setBackgroundColor(.dynamic(light: ColorProvider.InteractionNorm,
                                        dark: ColorProvider.InteractionNormMajor1PassTheme),
                               forState: .normal)
        }
        setBackgroundColor(ColorProvider.InteractionNormPressed, forState: .highlighted)
        setBackgroundColor(ColorProvider.InteractionNormPressed, forState: .selected)
        setBackgroundColor(ColorProvider.InteractionNormDisabled, forState: .disabled)
    }

    private func nonSolidLayout() {
        switch Brand.currentBrand {
        case .proton, .vpn:
            setTitleColor(ColorProvider.TextAccent, for: .normal)
        case .pass:
            setTitleColor(.dynamic(light: ColorProvider.TextAccent,
                                   dark: ColorProvider.InteractionNormMajor2PassTheme),
                          for: .normal)
        }
        setTitleColor(ColorProvider.BrandDarken20, for: .highlighted)
        setTitleColor(ColorProvider.BrandDarken20, for: .selected)
        setBackgroundColor(.clear, forState: .normal)
        setBackgroundColor(ColorProvider.BackgroundSecondary, forState: .highlighted)
        setBackgroundColor(ColorProvider.BackgroundSecondary, forState: .selected)
        setBackgroundColor(ColorProvider.BackgroundNorm, forState: .disabled)
    }
    
    private func imageLayout(isImageOnly: Bool) {
        if isImageOnly {
            switch Brand.currentBrand {
            case .proton, .vpn:
                setTitleColor(ColorProvider.InteractionNorm, for: .normal)
            case .pass:
                setTitleColor(.dynamic(light: ColorProvider.InteractionNorm,
                                       dark: ColorProvider.InteractionNormMajor1PassTheme),
                              for: .normal)
            }
            setTitleColor(ColorProvider.InteractionNorm, for: .highlighted)
            setTitleColor(ColorProvider.InteractionNorm, for: .selected)
            setTitleColor(ColorProvider.TextDisabled, for: .disabled)
            setBackgroundColor(.clear, forState: .normal)
            setBackgroundColor(.clear, forState: .highlighted)
            setBackgroundColor(.clear, forState: .selected)
            setBackgroundColor(.clear, forState: .disabled)
        } else {
            setTitleColor(ColorProvider.TextNorm, for: .normal)
            setTitleColor(ColorProvider.TextWeak, for: .highlighted)
            setTitleColor(ColorProvider.TextWeak, for: .selected)
            setTitleColor(ColorProvider.TextDisabled, for: .disabled)
            setBackgroundColor(ColorProvider.InteractionWeakDisabled, forState: .normal)
            setBackgroundColor(ColorProvider.InteractionWeakDisabled, forState: .highlighted)
            setBackgroundColor(ColorProvider.InteractionWeakDisabled, forState: .selected)
            setBackgroundColor(ColorProvider.BackgroundNorm, forState: .disabled)
            layer.borderColor = ColorProvider.BrandNorm
        }
    }

    fileprivate func dynamicUpdate() {
        if mode == .outlined {
            layer.borderColor = titleColor(for: state)?.cgColor
        }
        if case .image = mode {
            layer.borderWidth = hasImageBorder && isHighlighted ? 1 : 0
            rightHandImage?.tintColor = titleColor(for: state)
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
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator?.color = titleColor(for: state)

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
    
    @discardableResult
    private func createRightImage(image: UIImage?, isImageOnly: Bool) -> UIImageView? {
        guard let image = image else {
            self.rightHandImage?.removeFromSuperview()
            self.rightHandImage = nil
            return nil
        }

        if let rightHandImage = rightHandImage {
            return rightHandImage
        }
        
        let rightHandImage = UIImageView(image: image)
        addSubview(rightHandImage)
        rightHandImage.translatesAutoresizingMaskIntoConstraints = false
        bringSubviewToFront(rightHandImage)
        if isImageOnly {
            rightHandImage.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        } else {
            trailingAnchor.constraint(equalTo: rightHandImage.trailingAnchor, constant: 12).isActive = true
        }
        rightHandImage.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        self.rightHandImage = rightHandImage
        return rightHandImage
    }
    
    private var isChevron: Bool {
        return .image(type: .textWithChevron) == mode || .image(type: .chevron) == mode
    }
    
    private var hasImageBorder: Bool {
        return .image(type: .textWithChevron) == mode || .image(type: .textWithImage(image: nil)) == mode
    }
    
    private func animateChevron(isSelected: Bool, animated: Bool) {
        guard isChevron else { return }
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                rotateChevron(isSelected: isSelected)
            })
        } else {
            rotateChevron(isSelected: isSelected)
        }
        
        func rotateChevron(isSelected: Bool) {
            rightHandImage?.transform = CGAffineTransform(rotationAngle: isSelected ? -Double.pi : Double.pi * 2)
        }
    }
}

#endif
