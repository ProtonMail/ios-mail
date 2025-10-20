// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import SwiftUI

public extension DS.Images {
    static let calendarToday = ImageResource.icCalendarToday
    static let emptyMailbox = ImageResource.emptyMailbox
    static let emptyOutbox = ImageResource.emptyOutbox
    static let mailProductLogo = ImageResource.mailProductLogo
    static let notificationPrompt = ImageResource.notificationPrompt
    static let onboardingFirstPage = ImageResource.onboarding1
    static let onboardingSecondPage = ImageResource.onboarding2
    static let onboardingThirdPage = ImageResource.onboarding3
    static let searchNoResults = ImageResource.searchNoResults
    static let noConnection = ImageResource.noConnection
    static let protonMail = ImageResource.protonMail
    static let protonCalendar = ImageResource.protonCalendar
    static let lock = ImageResource.lock

    enum Upsell {
        public static let logoAutoDelete = ImageResource.upsellLogoAutoDelete
        public static let logoContactGroups = ImageResource.upsellLogoContactGroups
        public static let logoDefault = ImageResource.upsellLogoDefault
        public static let logoFoldersAndLabels = ImageResource.upsellLogoFoldersAndLabels
        public static let logoMobileSignature = ImageResource.upsellLogoMobileSignature
        public static let logoScheduleSend = ImageResource.upsellLogoScheduleSend
        public static let logoSnooze = ImageResource.upsellLogoSnooze

        public enum BlackFriday {
            public static let background = ImageResource.upsellBlackFridayBackground
            public static let logo50 = ImageResource.upsellLogoBlackFriday50
            public static let logo80 = ImageResource.upsellLogoBlackFriday80
        }
    }
}
