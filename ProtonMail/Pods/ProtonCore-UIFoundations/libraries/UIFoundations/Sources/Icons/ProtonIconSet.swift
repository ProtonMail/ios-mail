//
//  ProtonIconSet.swift
//  ProtonCore-UIFoundations - Created on 08.02.22.
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

public struct ProtonIconSet {
    static let instance = ProtonIconSet()

    private init() {}
    
    // Icons

    public let arrowLeft = ProtonIcon(name: "ic-arrow-left")
    
    public let arrowOutFromRectangle = ProtonIcon(name: "ic-Arrow-out-from-rectangle")
    
    public let arrowRight = ProtonIcon(name: "ic-arrow-right")
    
    public let arrowsRotate = ProtonIcon(name: "ic-Arrows-rotate")
    
    public let checkmarkCircle = ProtonIcon(name: "ic-Checkmark-circle")
    
    public let checkmark = ProtonIcon(name: "ic-Checkmark")
    
    public let chevronDown = ProtonIcon(name: "ic-chevron-down")
    
    public let crossCircleFilled = ProtonIcon(name: "ic-Cross-circle-filled")
    
    public let cogWheel = ProtonIcon(name: "ic-cog-wheel")
    
    public let crossSmall = ProtonIcon(name: "ic-Cross_small")
    
    public let envelope = ProtonIcon(name: "ic-envelope")
    
    public let eyeSlash = ProtonIcon(name: "ic-eye-slash")
    
    public let eye = ProtonIcon(name: "ic-eye")
    
    public let fileArrowIn = ProtonIcon(name: "ic-File-arrow-in")
    
    public let info = ProtonIcon(name: "ic-info")
    
    public let key = ProtonIcon(name: "ic-key")
    
    public let lightbulb = ProtonIcon(name: "ic-lightbulb")
    
    public let plus = ProtonIcon(name: "ic-plus")
    
    public let minus = ProtonIcon(name: "ic-minus")
    
    public let minusCircle = ProtonIcon(name: "ic-minus-circle")
    
    public let mobile = ProtonIcon(name: "ic-mobile")
    
    public let questionCircle = ProtonIcon(name: "ic-question-circle")
    
    public let signIn = ProtonIcon(name: "ic-sign-in")
    
    public let speechBubble = ProtonIcon(name: "ic-Speech-bubble")
    
    public let threeDotsHorizontal = ProtonIcon(name: "ic-three-dots-horizontal")
    
    public let userCircle = ProtonIcon(name: "ic-user-circle")
    
    // Apple-specific icons
    
    public let faceId = ProtonIcon(name: "ic-face-id")
    
    public let touchId = ProtonIcon(name: "ic-touch-id")
    
    // Flags
    
    public func flag(forCountryCode countryCode: String) -> ProtonIcon {
        ProtonIcon(name: "flags-\(countryCode)")
    }
    
    // Logos
    
    // swiftlint:disable inclusive_language
    
    public let masterBrandBrand = ProtonIcon(name: "MasterBrandBrand")
    
    // swiftlint:enable inclusive_language
    
    public let calendarMain = ProtonIcon(name: "CalendarMain")
    
    public let driveMain = ProtonIcon(name: "DriveMain")
    
    public let mailMain = ProtonIcon(name: "MailMain")
    
    public let vpnMain = ProtonIcon(name: "VPNMain")
    
    @available(*, deprecated, renamed: "masterBrandBrand")
    public let logoProton = ProtonIcon(name: "MasterBrandBrand")
    
    @available(*, deprecated, renamed: "calendarWordmarkNoBackground")
    public let logoProtonCalendar = ProtonIcon(name: "CalendarWordmarkNoBackground")
    @available(*, deprecated, renamed: "calendarWordmarkNoBackground")
    public let loginWelcomeCalendarLogo = ProtonIcon(name: "CalendarWordmarkNoBackground")
    
    public let calendarWordmarkNoBackground = ProtonIcon(name: "CalendarWordmarkNoBackground")
    
    @available(*, deprecated, renamed: "driveWordmarkNoBackground")
    public let logoProtonDrive = ProtonIcon(name: "DriveWordmarkNoBackground")
    @available(*, deprecated, renamed: "driveWordmarkNoBackground")
    public let loginWelcomeDriveLogo = ProtonIcon(name: "DriveWordmarkNoBackground")
    
    public let driveWordmarkNoBackground = ProtonIcon(name: "DriveWordmarkNoBackground")
    
    @available(*, deprecated, renamed: "mailWordmarkNoBackground")
    public let logoProtonMail = ProtonIcon(name: "MailWordmarkNoBackground")
    @available(*, deprecated, renamed: "mailWordmarkNoBackground")
    public let loginWelcomeMailLogo = ProtonIcon(name: "MailWordmarkNoBackground")
    
    public let mailWordmarkNoBackground = ProtonIcon(name: "MailWordmarkNoBackground")
    
    @available(*, deprecated, renamed: "vpnWordmarkNoBackground")
    public let logoProtonVPN = ProtonIcon(name: "VPNWordmarkNoBackground")
    @available(*, deprecated, renamed: "vpnWordmarkNoBackground")
    public let loginWelcomeVPNLogo = ProtonIcon(name: "VPNWordmarkNoBackground")
    
    public let vpnWordmarkNoBackground = ProtonIcon(name: "VPNWordmarkNoBackground")
    
    @available(*, deprecated, renamed: "calendarMainTransparent")
    public let loginWelcomeCalendarSmallLogo = ProtonIcon(name: "CalendarMainTransparent")
    public let calendarMainTransparent = ProtonIcon(name: "CalendarMainTransparent")
    
    @available(*, deprecated, renamed: "driveMainTransparent")
    public let loginWelcomeDriveSmallLogo = ProtonIcon(name: "DriveMainTransparent")
    public let driveMainTransparent = ProtonIcon(name: "DriveMainTransparent")
    
    @available(*, deprecated, renamed: "mailMainTransparent")
    public let loginWelcomeMailSmallLogo = ProtonIcon(name: "MailMainTransparent")
    public let mailMainTransparent = ProtonIcon(name: "MailMainTransparent")
    
    @available(*, deprecated, renamed: "vpnMainTransparent")
    public let loginWelcomeVPNSmallLogo = ProtonIcon(name: "VPNMainTransparent")
    public let vpnMainTransparent = ProtonIcon(name: "VPNMainTransparent")
    
    // Login-specific
    
    public let loginSummaryBottom = ProtonIcon(name: "summary_bottom")
    
    public let loginSummaryProton = ProtonIcon(name: "summary_proton")
    
    public let loginSummaryVPN = ProtonIcon(name: "summary_vpn")
    
    public let loginWelcomeTopImageForProton = ProtonIcon(name: "WelcomeTopImageForProton")
    
    public let loginWelcomeTopImageForVPN = ProtonIcon(name: "WelcomeTopImageForVPN")
}
