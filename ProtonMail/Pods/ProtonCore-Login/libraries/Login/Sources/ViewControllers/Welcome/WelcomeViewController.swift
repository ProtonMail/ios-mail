//
//  WelcomeViewController.swift
//  ProtonCore-Login
//
//  Created by Krzysztof Siejkowski on 17/06/2021.
//

import UIKit
import ProtonCore_UIFoundations
import ProtonCore_CoreTranslation

public typealias WelcomeScreenVariant = ScreenVariant<WelcomeScreenTexts, WelcomeScreenCustomData>

public struct WelcomeScreenTexts {
    let headline: String
    let body: String

    public init(headline: String, body: String) {
        self.headline = headline
        self.body = body
    }
}

public struct WelcomeScreenCustomData {
    let topImage: UIImage
    let logo: UIImage
    let headline: String
    let body: String

    public init(topImage: UIImage, logo: UIImage, headline: String, body: String) {
        self.topImage = topImage
        self.logo = logo
        self.headline = headline
        self.body = body
    }
}

protocol WelcomeViewControllerDelegate: AnyObject {
    func userWantsToLogIn(username: String?)
    func userWantsToSignUp()
}

final class WelcomeViewController: UIViewController {

    private let variant: WelcomeScreenVariant
    private let username: String?
    private let signupAvailable: Bool
    private weak var delegate: WelcomeViewControllerDelegate?

    init(variant: WelcomeScreenVariant, delegate: WelcomeViewControllerDelegate, username: String?, signupAvailable: Bool) {
        self.variant = variant
        self.delegate = delegate
        self.username = username
        self.signupAvailable = signupAvailable
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("not designed to be created from IB") }

    override func loadView() {
        let loginAction = #selector(WelcomeViewController.loginActionWasPerformed)
        let signupAction = #selector(WelcomeViewController.signupActionWasPerformed)
        view = WelcomeView(variant: variant, target: self, loginAction: loginAction, signupAction: signupAction, signupAvailable: signupAvailable)
    }

    @objc private func loginActionWasPerformed() {
        delegate?.userWantsToLogIn(username: username)
    }

    @objc private func signupActionWasPerformed() {
        delegate?.userWantsToSignUp()
    }
}

final class WelcomeView: UIView {

    private let loginButton = ProtonButton()
    private let signupButton = UIButton()
    private let signupAvailable: Bool

    init(variant: WelcomeScreenVariant, target: UIViewController, loginAction: Selector, signupAction: Selector, signupAvailable: Bool) {
        self.signupAvailable = signupAvailable

        super.init(frame: .zero)

        setUpLayout(variant: variant)
        setUpInteractions(target: target, loginAction: loginAction, signupAction: signupAction)
    }

    required init?(coder: NSCoder) { fatalError("not designed to be created from IB") }

    private func setUpLayout(variant: WelcomeScreenVariant) {

        setUpMainView(for: variant)

        let topImage = topImage(for: variant)
        let logo = logo(for: variant)
        let headline = headline(for: variant)
        let body = body(for: variant)
        let footer = footer()

        setUpButtons()

        [topImage, logo, headline, body, loginButton, signupButton, footer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        topImage.contentMode = .center

        NSLayoutConstraint.activate([
            topImage.topAnchor.constraint(equalTo: topAnchor),
            topImage.centerXAnchor.constraint(equalTo: centerXAnchor),

            logo.topAnchor.constraint(equalTo: topImage.bottomAnchor, constant: 24),
            logo.centerXAnchor.constraint(equalTo: centerXAnchor),

            headline.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 36),

            body.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 8),
            body.centerXAnchor.constraint(equalTo: centerXAnchor),
            body.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            body.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            loginButton.topAnchor.constraint(equalTo: body.bottomAnchor, constant: 32),
            loginButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            loginButton.widthAnchor.constraint(equalTo: readableContentGuide.widthAnchor),

            signupButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 26),
            signupButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            signupButton.widthAnchor.constraint(equalTo: readableContentGuide.widthAnchor),

            footer.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            footer.centerXAnchor.constraint(equalTo: centerXAnchor),
            footer.widthAnchor.constraint(equalTo: readableContentGuide.widthAnchor)
        ])

        NSLayoutConstraint.activate([headline, body, loginButton, signupButton, footer].flatMap { view in
            [view.centerXAnchor.constraint(equalTo: centerXAnchor),
             view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
             view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)]
        })
    }

    fileprivate func setUpMainView(for variant: WelcomeScreenVariant) {
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }

        switch variant {
        case .mail: UIColorManager.brand = .proton
        case .calendar: UIColorManager.brand = .proton
        case .drive: UIColorManager.brand = .proton
        case .vpn: UIColorManager.brand = .vpn
        case .custom: fatalError("not implemented yet")
        }

        backgroundColor = UIColorManager.Splash.Background
    }

    private func topImage(for variant: WelcomeScreenVariant) -> UIImageView {
        let topImage: UIImage
        switch variant {
        case .mail: topImage = image(named: "WelcomeTopImageForProton")
        case .calendar: topImage = image(named: "WelcomeTopImageForProton")
        case .drive: topImage = image(named: "WelcomeTopImageForProton")
        case .vpn: topImage = image(named: "WelcomeTopImageForVPN")
        case .custom(let data): topImage = data.topImage
        }
        return UIImageView(image: topImage)
    }

    private func logo(for variant: WelcomeScreenVariant) -> UIImageView {
        let logo: UIImage
        switch variant {
        case .mail: logo = image(named: "WelcomeMailLogo")
        case .calendar: logo = image(named: "WelcomeCalendarLogo")
        case .drive: logo = image(named: "WelcomeDriveLogo")
        case .vpn: logo = image(named: "WelcomeVPNLogo")
        case .custom(let data): logo = data.logo
        }
        return UIImageView(image: logo)
    }

    private func headline(for variant: WelcomeScreenVariant) -> UILabel {
        let headline = UILabel()
        let text: String
        switch variant {
        case .mail(let texts), .calendar(let texts), .drive(let texts), .vpn(let texts): text = texts.headline
        case .custom(let data): text = data.headline
        }
        headline.attributedText = NSAttributedString(string: text, attributes: .HeadlineSmall)
        headline.textAlignment = .center
        headline.numberOfLines = 0
        return headline
    }

    private func body(for variant: WelcomeScreenVariant) -> UILabel {
        let body = UILabel()
        let text: String
        switch variant {
        case .mail(let texts), .calendar(let texts), .drive(let texts), .vpn(let texts): text = texts.body
        case .custom(let data): text = data.body
        }
        var attributes = PMFontAttributes.DefaultSmall
        attributes[.foregroundColor] = UIColorManager.Splash.TextHintForProtonBrand
        body.attributedText = NSAttributedString(string: text, attributes: attributes)
        body.textAlignment = .center
        body.numberOfLines = 0
        return body
    }

    private func footer() -> UIView {
        let iconsNamesInOrder = ["WelcomeCalendarSmallLogo", "WelcomeVPNSmallLogo", "WelcomeDriveSmallLogo", "WelcomeMailSmallLogo"]
        let iconsInFooter = UIStackView(arrangedSubviews: iconsNamesInOrder.map(image(named:)).map { $0.withRenderingMode(.alwaysTemplate) }.map(UIImageView.init(image:)))
        iconsInFooter.tintColor = UIColorManager.Splash.TextHint
        iconsInFooter.axis = .horizontal
        iconsInFooter.spacing = 32
        iconsInFooter.alignment = .center

        let font = UIFont.systemFont(ofSize: 11, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.07
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: UIColorManager.Splash.TextHint, .kern: 0.07, .paragraphStyle: paragraphStyle
        ]

        let label = UILabel()
        label.attributedText = NSAttributedString(string: CoreString._ls_welcome_footer, attributes: attributes)

        let footer = UIStackView(arrangedSubviews: [iconsInFooter, label])
        footer.axis = .vertical
        footer.spacing = 8
        footer.alignment = .center
        return footer
    }

    private func setUpButtons() {
        loginButton.setMode(mode: .solid)

        loginButton.setTitle(CoreString._ls_sign_in_button, for: .normal)

        guard signupAvailable else {
            signupButton.isHidden = true
            return
        }

        let signUpTitle = CoreString._ls_create_account_button
        signupButton.setAttributedTitle(NSAttributedString(string: signUpTitle, attributes: .DefaultSmall), for: .normal)
        signupButton.setAttributedTitle(NSAttributedString(string: signUpTitle, attributes: .DefaultSmallDisabled), for: .disabled)
        signupButton.setAttributedTitle(NSAttributedString(string: signUpTitle, attributes: .DefaultSmallWeek), for: .highlighted)
        signupButton.setAttributedTitle(NSAttributedString(string: signUpTitle, attributes: .DefaultSmallStrong), for: .selected)
    }

    private func setUpInteractions(target: UIViewController, loginAction: Selector, signupAction: Selector) {
        loginButton.addTarget(target, action: loginAction, for: .touchUpInside)
        signupButton.addTarget(target, action: signupAction, for: .touchUpInside)
    }

}

private func image(named name: String) -> UIImage {
    guard let icon = UIImage(named: name, in: PMLogin.bundle, compatibleWith: nil) else {
        assertionFailure("Asset not available, configuration error")
        return .init()
    }
    return icon
}
