//
//  WelcomeView.swift
//  ProtonCore-LoginUI - Created on 17.06.2021.
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
import ProtonCoreUIFoundations
import func AVFoundation.AVMakeRect

public struct WelcomeScreenTexts {
    let body: String
    
    public init(body: String) {
        self.body = body
    }
}

public struct WelcomeScreenCustomData {
    let topImage: UIImage
    let wordmarkWithLogo: UIImage
    let body: String
    let brand: Brand
    
    public init(topImage: UIImage, wordmarkWithLogo: UIImage, body: String, brand: Brand) {
        self.topImage = topImage
        self.wordmarkWithLogo = wordmarkWithLogo
        self.body = body
        self.brand = brand
    }
}

enum WelcomeViewLayout: CaseIterable {
    case small
    case regular
    case big

    static func provideLayoutBasedOnUIScreenBounds() -> WelcomeViewLayout {
        // small iphone size (SE 1st gen, 5, 5s etc.)
        if UIScreen.main.bounds.width < 340.0 && UIScreen.main.bounds.height < 600.0 {
            return .small
        // regular iphone size
        } else if UIScreen.main.bounds.width < 600.0 {
            return .regular
        // iPad territory
        } else {
            return .big
        }
    }
}

final class WelcomeView: UIView {

    private let loginButton = ProtonButton()
    private let signupButton = ProtonButton()
    private let signupAvailable: Bool

    init(variant: WelcomeScreenVariant,
         layout: WelcomeViewLayout?,
         target: UIViewController,
         loginAction: Selector,
         signupAction: Selector,
         signupAvailable: Bool) {
        self.signupAvailable = signupAvailable

        super.init(frame: .zero)

        setUpLayout(variant: variant,
                    layout: layout ?? WelcomeViewLayout.provideLayoutBasedOnUIScreenBounds())
        setUpInteractions(target: target, loginAction: loginAction, signupAction: signupAction)
    }

    required init?(coder: NSCoder) { fatalError("not designed to be created from IB") }

    private func setUpLayout(variant: WelcomeScreenVariant, layout: WelcomeViewLayout) {

        setUpMainView(for: variant)
        let image = top(for: variant)
        let topImage = UIImageView(image: image)
        let top = UIView()
        let wordmarkWithLogo = wordmarkWithLogo(for: variant)
        let body = body(for: variant)
        let footerBrand = footer()

        setUpButtons()

        [top, wordmarkWithLogo, body, loginButton, signupButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        topImage.translatesAutoresizingMaskIntoConstraints = false
        top.addSubview(topImage)
        top.clipsToBounds = true
        topImage.clipsToBounds = true
        wordmarkWithLogo.contentMode = .scaleAspectFill
        
        let primaryButton: ProtonButton
        let secondaryButton: ProtonButton
        if signupAvailable {
            primaryButton = signupButton
            secondaryButton = loginButton
        } else {
            primaryButton = loginButton
            secondaryButton = signupButton
        }

        wordmarkWithLogo.centerXInSuperview()

        let topOffset: CGFloat = 48
        let bodyOffset: CGFloat = 24
        let buttonOffset: CGFloat = 24
        let secondaryButtonOffset: CGFloat = 12
        let bottomOffset: CGFloat = 58

        [top, topImage].forEach { view in
            [NSLayoutConstraint.Axis.vertical, .horizontal].forEach { axis in
                view.setContentHuggingPriority(.defaultLow - 1, for: axis)
                view.setContentCompressionResistancePriority(.defaultLow - 1, for: axis)
            }
        }

        // constaints that are common for all the screen sizes
        NSLayoutConstraint.activate([
            top.topAnchor.constraint(equalTo: topAnchor),
            top.leadingAnchor.constraint(equalTo: leadingAnchor),
            top.trailingAnchor.constraint(equalTo: trailingAnchor),
            top.bottomAnchor.constraint(equalTo: wordmarkWithLogo.topAnchor, constant: -topOffset),

            topImage.bottomAnchor.constraint(equalTo: top.bottomAnchor),
            topImage.centerXAnchor.constraint(equalTo: top.centerXAnchor),
            topImage.heightAnchor.constraint(greaterThanOrEqualTo: top.heightAnchor),
            topImage.widthAnchor.constraint(greaterThanOrEqualTo: top.widthAnchor),
            topImage.widthAnchor.constraint(equalTo: topImage.heightAnchor,
                                            multiplier: image.size.width / image.size.height),

            wordmarkWithLogo.widthAnchor.constraint(equalToConstant: 220),
            wordmarkWithLogo.centerXAnchor.constraint(equalTo: centerXAnchor),

            body.topAnchor.constraint(equalTo: wordmarkWithLogo.bottomAnchor, constant: bodyOffset),
            primaryButton.topAnchor.constraint(equalTo: body.bottomAnchor, constant: buttonOffset),
            secondaryButton.topAnchor.constraint(equalTo: primaryButton.bottomAnchor, constant: secondaryButtonOffset)
        ])
        
        switch layout {
        case .small:
            topImage.contentMode = .scaleAspectFit
            NSLayoutConstraint.activate([
                topImage.widthAnchor.constraint(equalTo: top.widthAnchor),
                secondaryButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
            ])
        case .regular:
            topImage.contentMode = .scaleAspectFill
            addSubview(footerBrand)
            NSLayoutConstraint.activate([
                wordmarkWithLogo.centerYAnchor.constraint(equalTo: centerYAnchor),
                footerBrand.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomOffset),
                footerBrand.heightAnchor.constraint(equalToConstant: 20),
                footerBrand.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor)
            ])
        case .big:
            topImage.contentMode = .scaleAspectFill
            addSubview(footerBrand)
            NSLayoutConstraint.activate([
                footerBrand.topAnchor.constraint(equalTo: secondaryButton.bottomAnchor, constant: 48),
                footerBrand.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -bottomOffset),
                footerBrand.heightAnchor.constraint(equalToConstant: 20),
                footerBrand.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor)
            ])
        }
        
        NSLayoutConstraint.activate([wordmarkWithLogo, body, loginButton, signupButton].flatMap { view -> [NSLayoutConstraint] in
            let readableContentIfPossible = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal,
                                                                 toItem: readableContentGuide, attribute: .leading, multiplier: 1.0, constant: 0.0)
            readableContentIfPossible.priority = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - 1)
            return [
                view.centerXAnchor.constraint(equalTo: readableContentGuide.centerXAnchor),
                readableContentIfPossible,
                view.leadingAnchor.constraint(greaterThanOrEqualTo: readableContentGuide.leadingAnchor),
                view.widthAnchor.constraint(lessThanOrEqualToConstant: 457)
            ]
        })
    }

    private func setUpMainView(for variant: WelcomeScreenVariant) {
        switch variant {
        case .mail: ColorProvider.brand = .proton
        case .calendar: ColorProvider.brand = .proton
        case .drive: ColorProvider.brand = .proton
        case .vpn: ColorProvider.brand = .vpn
        case .pass: ColorProvider.brand = .pass
        case .custom(let data): ColorProvider.brand = data.brand
        }

        backgroundColor = ColorProvider.BackgroundNorm
    }

    private func top(for variant: WelcomeScreenVariant) -> UIImage {
        switch variant {
        case .mail: return IconProvider.mailTopImage
        case .calendar: return IconProvider.calendarTopImage
        case .drive: return IconProvider.driveTopImage
        case .vpn: return IconProvider.vpnTopImage
        case .pass: return IconProvider.passTopImage
        case .custom: return IconProvider.mailTopImage
        }
    }
    
    private func wordmarkWithLogo(for variant: WelcomeScreenVariant) -> UIImageView {
        let wordmark: UIImage
        switch variant {
        case .mail: wordmark = IconProvider.mailWordmarkNoBackground
        case .calendar: wordmark = IconProvider.calendarWordmarkNoBackground
        case .drive: wordmark = IconProvider.driveWordmarkNoBackground
        case .vpn: wordmark = IconProvider.vpnWordmarkNoBackground
        case .pass: wordmark = IconProvider.passWordmarkNoBackground
        case .custom(let data): wordmark = data.wordmarkWithLogo
        }
        return UIImageView(image: wordmark)
    }

    private func body(for variant: WelcomeScreenVariant) -> UILabel {
        let body = UILabel()
        let text: String
        switch variant {
        case .mail(let texts), .calendar(let texts), .drive(let texts), .vpn(let texts), .pass(let texts):
            text = texts.body
        case .custom(let data):
            text = data.body
        }
        var attributes = PMFontAttributes.DefaultSmall
        let foregroundColor: UIColor = ColorProvider.TextWeak
        attributes[.foregroundColor] = foregroundColor
        body.attributedText = NSAttributedString(string: text, attributes: attributes)
        body.textAlignment = .center
        body.numberOfLines = 0
        return body
    }

    private func footer() -> UIView {
        let brandInFooter = UIImageView(image: IconProvider.footer)
        brandInFooter.tintColor = ColorProvider.TextHint
        brandInFooter.translatesAutoresizingMaskIntoConstraints = false
        brandInFooter.contentMode = .scaleAspectFit
        return brandInFooter
    }

    private func setUpButtons() {
        loginButton.setMode(mode: signupAvailable ? .text : .solid)
        loginButton.setTitle(LUITranslation.sign_in_button.l10n, for: .normal)
        signupButton.setMode(mode: .solid)
        signupButton.setTitle(LUITranslation.create_account_button.l10n, for: .normal)
        
        guard signupAvailable else {
            signupButton.isHidden = true
            return
        }
    }

    private func setUpInteractions(target: UIViewController, loginAction: Selector, signupAction: Selector) {
        loginButton.addTarget(target, action: loginAction, for: .touchUpInside)
        signupButton.addTarget(target, action: signupAction, for: .touchUpInside)
    }
}

extension NSLayoutConstraint {
    func with(priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}

#endif
