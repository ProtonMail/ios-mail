//
//  SplashViewController.swift
//  ProtonCore-UIFoundations - Created on 17/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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
import ProtonCore_Foundations

public final class SplashViewController: UIViewController, AccessibleView {

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        switch data.colorSchemeForBrand {
        case .proton: return .default
        case .vpn: return .lightContent
        }
    }

    private var data: SplashScreenData

    public convenience init(variant: SplashScreenIBVariant) {
        self.init(customData: variant.splashScreenData)
    }

    public init(customData data: SplashScreenData) {
        self.data = data
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override public func loadView() {
        view = SplashView(customData: data)
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }
}

public final class SplashView: UIView, AccessibleView {

    private var appIcon: UIImageView = .init()
    private var name: String = ""
    private var appName: UILabel = .init()
    private var footer: UILabel = .init()
    private var footerText: String = ""
    private var brand: Brand = .proton

    public var variant: SplashScreenIBVariant = .mail {
        didSet { updateViewAccordingToVariant(data: variant.splashScreenData) }
    }

    public convenience init(variant: SplashScreenIBVariant) {
        self.init(customData: variant.splashScreenData)
    }

    public init(customData data: SplashScreenData) {
        super.init(frame: .zero)
        updateViewAccordingToVariant(data: data)
        setupConstraints()
    }

    private func updateViewAccordingToVariant(data: SplashScreenData) {
        self.appIcon = UIImageView(image: data.icon)
        self.name = data.name
        self.appName = UILabel(frame: .zero)
        self.footer = UILabel(frame: .zero)
        self.footerText = data.footer
        self.brand = data.colorSchemeForBrand
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("not designed to be initialized this way") }

    private func setupUI() {
        setupMainView()
        setupAppName()
        setupFooter()
        generateAccessibilityIdentifiers()
    }

    private func setupMainView() {
        ProtonColorPallete.brand = brand
        backgroundColor = ProtonColorPallete.Splash.Background
    }

    private func setupAppName() {
        appName.attributedText = NSAttributedString(string: name, attributes: .Splash.appName)
    }

    private func setupFooter() {
        let iconAttachment = NSTextAttachment()
        iconAttachment.image = IconProvider.masterBrandBrand
        iconAttachment.limitImageHeight(to: 30)
        let iconString = NSAttributedString(attachment: iconAttachment)
        let footerString = NSMutableAttributedString(string: "\(footerText) ")
        footerString.append(iconString)
        footerString.addAttributes(.Splash.footer, range: .init(location: 0, length: footerString.length))
        footer.attributedText = footerString
        footer.clipsToBounds = true
    }

    private func setupConstraints() {
        [appIcon, appName, footer].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        appIcon.contentMode = .scaleAspectFit
        let position = NSLayoutConstraint(item: appIcon, attribute: .top, relatedBy: .equal, toItem: self,
                                          attribute: .bottom, multiplier: 0.333, constant: 0)
        NSLayoutConstraint.activate([
            position,
            appIcon.centerXAnchor.constraint(equalTo: centerXAnchor),
            appIcon.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.5),
            appIcon.heightAnchor.constraint(equalTo: appIcon.widthAnchor),
            
            appName.topAnchor.constraint(equalTo: appIcon.bottomAnchor, constant: 16),
            appName.centerXAnchor.constraint(equalTo: centerXAnchor),

            footer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -56),
            footer.centerXAnchor.constraint(equalTo: centerXAnchor),
            footer.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            footer.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            footer.heightAnchor.constraint(lessThanOrEqualToConstant: 60)
        ])
    }
}

extension NSTextAttachment {
    func limitImageHeight(to height: CGFloat) {
        guard let image = image else { return }
        guard image.size.height > height else { return }
        
        let ratio = image.size.width / image.size.height

        bounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: ratio * height, height: height)
    }
}

extension SplashScreenIBVariant {
    var splashScreenData: SplashScreenData {
        switch self {
        case .mail:
            return SplashScreenData(icon: IconProvider.mailMain,
                                    name: "ProtonMail",
                                    footer: CoreString._splash_made_by,
                                    colorSchemeForBrand: .proton)
        case .calendar:
            return SplashScreenData(icon: IconProvider.calendarMain,
                                    name: "ProtonCalendar",
                                    footer: CoreString._splash_made_by,
                                    colorSchemeForBrand: .proton)
        case .drive:
            return SplashScreenData(icon: IconProvider.driveMain,
                                    name: "ProtonDrive",
                                    footer: CoreString._splash_made_by,
                                    colorSchemeForBrand: .proton)
        case .vpn:
            return SplashScreenData(icon: IconProvider.vpnMain,
                                    name: "ProtonVPN",
                                    footer: CoreString._splash_made_by,
                                    colorSchemeForBrand: .vpn)
        }
    }
}

@objc public enum SplashScreenIBVariant: Int {
    case mail = 1
    case calendar = 2
    case drive = 3
    case vpn = 4
}

public struct SplashScreenData {
    let icon: UIImage
    let name: String
    let footer: String
    let colorSchemeForBrand: Brand
}

public enum ScreenVariant<SpecificScreenData, CustomScreenData> {
    case mail(SpecificScreenData)
    case calendar(SpecificScreenData)
    case drive(SpecificScreenData)
    case vpn(SpecificScreenData)
    case custom(CustomScreenData)
}

@available(*, deprecated, message: "Will be removed in the future version")
public typealias SplashScreenVariant = ScreenVariant<Void, SplashScreenData>

@available(*, deprecated, message: "Will be removed in the future version")
public extension SplashScreenVariant {
    static var mail: SplashScreenVariant { .mail(()) }
    static var calendar: SplashScreenVariant { .calendar(()) }
    static var drive: SplashScreenVariant { .drive(()) }
    static var vpn: SplashScreenVariant { .vpn(()) }
}

@available(*, deprecated, message: "Will be removed in the future version")
extension SplashViewController {

    @available(*, deprecated, message: "Use other initializers")
    public convenience init(variant: SplashScreenVariant) {
        switch variant {
        case .mail: self.init(variant: SplashScreenIBVariant.mail)
        case .drive: self.init(variant: SplashScreenIBVariant.drive)
        case .calendar: self.init(variant: SplashScreenIBVariant.calendar)
        case .vpn: self.init(variant: SplashScreenIBVariant.vpn)
        case .custom(let data): self.init(customData: data)
        }
    }
}
