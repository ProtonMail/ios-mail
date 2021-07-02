//
//  SplashViewController.swift
//  ProtonCore-Login - Created on 17/06/2021.
//
//
//  Copyright (c) 2021 Proton Technologies AG
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

import UIKit
import ProtonCore_CoreTranslation

public enum ScreenVariant<SpecificScreenData, CustomScreenData> {
    case mail(SpecificScreenData)
    case calendar(SpecificScreenData)
    case drive(SpecificScreenData)
    case vpn(SpecificScreenData)
    case custom(CustomScreenData)
}

public typealias SplashScreenVariant = ScreenVariant<Void, SplashScreenData>

public extension SplashScreenVariant {
    static var mail: SplashScreenVariant { .mail(()) }
    static var calendar: SplashScreenVariant { .calendar(()) }
    static var drive: SplashScreenVariant { .drive(()) }
    static var vpn: SplashScreenVariant { .vpn(()) }
}

public struct SplashScreenData {
    let icon: UIImage
    let name: String
    let colorSchemeForBrand: Brand
}

public final class SplashViewController: UIViewController {

    private let appIcon: UIImageView
    private let name: String
    private let appName: UILabel
    private let footer: UILabel
    private let brand: Brand

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        switch brand {
        case .proton: return .default
        case .vpn: return .lightContent
        }
    }

    public convenience init(variant: SplashScreenVariant) {
        switch variant {
        case .mail:
            self.init(icon: icon(named: "SplashMailIcon"), name: "ProtonMail", colorSchemeForBrand: .proton)
        case .calendar:
            self.init(icon: icon(named: "SplashCalendarIcon"), name: "ProtonCalendar", colorSchemeForBrand: .proton)
        case .drive:
            self.init(icon: icon(named: "SplashDriveIcon"), name: "ProtonDrive", colorSchemeForBrand: .proton)
        case .vpn:
            self.init(icon: icon(named: "SplashVPNIcon"), name: "ProtonVPN", colorSchemeForBrand: .vpn)
        case let .custom(data):
            self.init(icon: data.icon, name: data.name, colorSchemeForBrand: data.colorSchemeForBrand)
        }
    }

    private init(icon: UIImage, name: String, colorSchemeForBrand: Brand) {
        self.appIcon = UIImageView(image: icon)
        self.name = name
        self.appName = UILabel(frame: .zero)
        self.footer = UILabel(frame: .zero)
        self.brand = colorSchemeForBrand
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("not designed to be initialized this way") }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupMainView()
        setupAppIcon()
        setupAppName()
        setupFooter()
    }

    private func setupMainView() {
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
        UIColorManager.brand = brand
        view.backgroundColor = UIColorManager.Splash.Background

        [appIcon, appName, footer].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }

    private func setupAppIcon() {
        let position = NSLayoutConstraint(item: appIcon, attribute: .top, relatedBy: .equal, toItem: view,
                                          attribute: .bottom, multiplier: 0.333, constant: 0)
        NSLayoutConstraint.activate([
            position,
            appIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupAppName() {
        appName.attributedText = NSAttributedString(string: name, attributes: .Splash.appName)
        NSLayoutConstraint.activate([
            appName.topAnchor.constraint(equalTo: appIcon.bottomAnchor, constant: 16),
            appName.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupFooter() {
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = icon(named: "SplashProtonLogo")
        let iconString = NSAttributedString(attachment: iconAttachment)
        let footerString = NSMutableAttributedString(string: "\(CoreString._splash_made_by) ")
        footerString.append(iconString)
        footerString.addAttributes(.Splash.footer, range: .init(location: 0, length: footerString.length))
        footer.attributedText = footerString

        NSLayoutConstraint.activate([
            footer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -56),
            footer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            footer.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            footer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
}

private func icon(named name: String) -> UIImage {
    guard let icon = UIImage(named: name, in: PMUIFoundations.bundle, compatibleWith: nil) else {
        assertionFailure("Asset not available, configuration error")
        return .init()
    }
    return icon
}
