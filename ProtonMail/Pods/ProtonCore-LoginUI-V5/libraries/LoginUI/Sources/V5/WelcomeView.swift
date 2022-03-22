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

import UIKit
import ProtonCore_CoreTranslation
import ProtonCore_CoreTranslation_V5
import ProtonCore_Foundations
import ProtonCore_UIFoundations
import func AVFoundation.AVMakeRect

public struct WelcomeScreenTexts {
    let body: String
    
    public init(body: String) {
        self.body = body
    }
    
    @available(*, deprecated, message: "Welcome screen no longer has headline")
    let headline: String = ""

    @available(*, deprecated, renamed: "init(body:)")
    public init(headline _: String, body: String) {
        self.init(body: body)
    }
}

public struct WelcomeScreenCustomData {
    let topImage: UIImage
    let logo: UIImage
    let wordmark: UIImage
    let body: String
    let brand: Brand
    
    public init(topImage: UIImage, logo: UIImage, wordmark: UIImage, body: String, brand: Brand) {
        self.topImage = topImage
        self.logo = logo
        self.wordmark = wordmark
        self.body = body
        self.brand = brand
    }
    
    @available(*, deprecated, message: "Welcome screen no longer has headline")
    let headline: String = ""

    @available(*, deprecated, renamed: "init(topImage:logo:wordmark:body:brand:)")
    public init(topImage: UIImage, logo: UIImage, headline _: String, body: String, brand: Brand) {
        self.init(topImage: topImage, logo: logo, wordmark: UIImage(), body: body, brand: brand)
    }
}

final class WelcomeView: UIView {

    private let loginButton = ProtonButton()
    private let signupButton = ProtonButton()
    private let signupAvailable: Bool

    init(variant: WelcomeScreenVariant,
         target: UIViewController,
         loginAction: Selector,
         signupAction: Selector,
         signupAvailable: Bool) {
        self.signupAvailable = signupAvailable

        super.init(frame: .zero)

        setUpLayout(variant: variant)
        setUpInteractions(target: target, loginAction: loginAction, signupAction: signupAction)
    }

    required init?(coder: NSCoder) { fatalError("not designed to be created from IB") }

    private func setUpLayout(variant: WelcomeScreenVariant) {

        setUpMainView(for: variant)

        let image: UIImage = IconProvider.swirls
        let topImage = UIImageView(image: image)
        let top = UIView()
        let logo = logo(for: variant)
        let wordmark = wordmark(for: variant)
        let body = body(for: variant)
        let (footerBrand, footerLabel) = footer()
        
        logo.layer.shadowColor = UIColor(red: 0.051, green: 0.02, blue: 0.18, alpha: 0.07).cgColor
        logo.layer.shadowRadius = 15.0
        logo.layer.shadowOffset = .init(width: 0, height: 5.2)
        logo.layer.shadowOpacity = 1

        setUpButtons()

        [top, logo, wordmark, body, loginButton, signupButton, footerBrand, footerLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        topImage.translatesAutoresizingMaskIntoConstraints = false
        top.addSubview(topImage)
        
        top.clipsToBounds = true

        topImage.contentMode = .scaleAspectFill
        logo.contentMode = .scaleAspectFit
        wordmark.contentMode = .scaleAspectFit
        
        let primaryButton: ProtonButton
        let secondaryButton: ProtonButton
        if signupAvailable {
            primaryButton = signupButton
            secondaryButton = loginButton
        } else {
            primaryButton = loginButton
            secondaryButton = signupButton
        }
        
        logo.centerXInSuperview()
        
        let topOffset: CGFloat
        let trailingOffset: CGFloat
        let bodyOffset: CGFloat
        let buttonOffset: CGFloat
        let secondaryButtonOffset: CGFloat
        
        // small iphone size
        if UIScreen.main.bounds.width < 340.0 {
            topOffset = 40.0
            trailingOffset = 289.0
            bodyOffset = 16.0
            buttonOffset = 16.0
            secondaryButtonOffset = 4.0
        // regular iphone size
        } else if UIScreen.main.bounds.width < 600.0 {
            topOffset = 32.0
            trailingOffset = 234.0
            bodyOffset = 24.0
            buttonOffset = 44.0
            secondaryButtonOffset = 12.0
        // iPad territory
        } else {
            topOffset = 0.0
            trailingOffset = 16.0
            bodyOffset = 24.0
            buttonOffset = 44.0
            secondaryButtonOffset = 12.0
        }
        
        let position = NSLayoutConstraint(item: top, attribute: .bottom, relatedBy: .equal,
                                          toItem: self, attribute: .bottom, multiplier: 0.3, constant: 0)
        NSLayoutConstraint.activate([
            top.topAnchor.constraint(equalTo: topAnchor),
            top.leadingAnchor.constraint(equalTo: leadingAnchor),
            top.trailingAnchor.constraint(equalTo: trailingAnchor),
            position,
            
            topImage.topAnchor.constraint(equalTo: top.topAnchor, constant: -topOffset),
            topImage.trailingAnchor.constraint(equalTo: top.trailingAnchor, constant: trailingOffset),
            topImage.widthAnchor.constraint(greaterThanOrEqualTo: top.widthAnchor, constant: trailingOffset),
            topImage.widthAnchor.constraint(greaterThanOrEqualToConstant: image.size.width),  // + trailingOffset),
            topImage.heightAnchor.constraint(greaterThanOrEqualToConstant: image.size.height), // + topOffset),
            topImage.widthAnchor.constraint(equalTo: topImage.heightAnchor, multiplier: image.size.width / image.size.height),

            logo.centerYAnchor.constraint(equalTo: top.bottomAnchor, constant: -8),
            logo.widthAnchor.constraint(equalToConstant: 106),
            logo.heightAnchor.constraint(equalToConstant: 106),

            wordmark.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 16),
            body.topAnchor.constraint(equalTo: wordmark.bottomAnchor, constant: bodyOffset),
            primaryButton.topAnchor.constraint(equalTo: body.bottomAnchor, constant: buttonOffset),
            secondaryButton.topAnchor.constraint(equalTo: primaryButton.bottomAnchor, constant: secondaryButtonOffset),
            footerBrand.topAnchor.constraint(greaterThanOrEqualTo: secondaryButton.bottomAnchor, constant: 8),
            footerBrand.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -40),
            footerBrand.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            
            footerLabel.topAnchor.constraint(equalTo: footerBrand.bottomAnchor, constant: 8),
            footerLabel.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([wordmark, body, loginButton, signupButton].flatMap { view -> [NSLayoutConstraint] in
            let readableContentIfPossible = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal,
                                                                 toItem: readableContentGuide, attribute: .leading, multiplier: 1.0, constant: 0.0)
            readableContentIfPossible.priority = UILayoutPriority(rawValue: UILayoutPriority.required.rawValue - 1)
            return [
                view.centerXAnchor.constraint(equalTo: readableContentGuide.centerXAnchor),
                readableContentIfPossible,
                view.leadingAnchor.constraint(greaterThanOrEqualTo: readableContentGuide.leadingAnchor),
                view.widthAnchor.constraint(lessThanOrEqualToConstant: 344)
            ]
        })
    }

    fileprivate func setUpMainView(for variant: WelcomeScreenVariant) {
        switch variant {
        case .mail: ColorProvider.brand = .proton
        case .calendar: ColorProvider.brand = .proton
        case .drive: ColorProvider.brand = .proton
        case .vpn: ColorProvider.brand = .vpn
        case .custom(let data): ColorProvider.brand = data.brand
        }

        backgroundColor = ColorProvider.BackgroundNorm
    }

    private func logo(for variant: WelcomeScreenVariant) -> UIImageView {
        let logo: UIImage
        switch variant {
        case .mail: logo = IconProvider.mailMain
        case .calendar: logo = IconProvider.calendarMain
        case .drive: logo = IconProvider.driveMain
        case .vpn: logo = IconProvider.vpnMain
        case .custom(let data): logo = data.logo
        }
        return UIImageView(image: logo)
    }
    
    private func wordmark(for variant: WelcomeScreenVariant) -> UIImageView {
        let wordmark: UIImage
        switch variant {
        case .mail: wordmark = IconProvider.mailWordmarkNoIcon
        case .calendar: wordmark = IconProvider.calendarWordmarkNoIcon
        case .drive: wordmark = IconProvider.driveWordmarkNoIcon
        case .vpn: wordmark = IconProvider.vpnWordmarkNoIcon
        case .custom(let data): wordmark = data.wordmark
        }
        return UIImageView(image: wordmark)
    }

    private func body(for variant: WelcomeScreenVariant) -> UILabel {
        let body = UILabel()
        let text: String
        switch variant {
        case .mail(let texts), .calendar(let texts), .drive(let texts), .vpn(let texts): text = texts.body
        case .custom(let data): text = data.body
        }
        var attributes = PMFontAttributes.DefaultSmall
        let foregroundColor: UIColor = ColorProvider.TextWeak
        attributes[.foregroundColor] = foregroundColor
        body.attributedText = NSAttributedString(string: text, attributes: attributes)
        body.textAlignment = .center
        body.numberOfLines = 0
        return body
    }

    private func footer() -> (UIView, UIView) {
        let brandInFooter = UIImageView(image: IconProvider.masterBrandBrandColorNoEffect)
        brandInFooter.translatesAutoresizingMaskIntoConstraints = false
        brandInFooter.heightAnchor.constraint(equalToConstant: 32).isActive = true
        brandInFooter.contentMode = .scaleAspectFit
        
        let font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.08
        paragraphStyle.alignment = .center
        let foregroundColor: UIColor = UIColor.dynamic(light: ColorProvider.BrandNorm,
                                                       dark: ColorProvider.BrandLighten20)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foregroundColor,
            .kern: 0.07,
            .paragraphStyle: paragraphStyle
        ]

        let label = UILabel()
        label.attributedText = NSAttributedString(string: CoreString_V5._ls_welcome_footer, attributes: attributes)

        return (brandInFooter, label)
    }

    private func setUpButtons() {
        loginButton.setMode(mode: signupAvailable ? .text : .solid)
        loginButton.setTitle(CoreString._ls_sign_in_button, for: .normal)
        signupButton.setMode(mode: .solid)
        signupButton.setTitle(CoreString._ls_create_account_button, for: .normal)
        
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
