// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation

enum SpotlightableFeatureKey: String, CaseIterable {
    case answerInvitation
    case dynamicFontSize
    case scheduledSend
    case toolbarCustomization
    case messageSwipeNavigationAnimation
    case autoImportContacts
    case jumpToNextMessage

    var correspondingRemoteFeatureFlag: MailFeatureFlag? {
        switch self {
        case .autoImportContacts:
            return .autoImportContacts
        case .answerInvitation:
            return .answerInvitation
        case .dynamicFontSize:
            return .dynamicFontSizeInMessageBody
        default:
            return nil
        }
    }
}

// sourcery: mock
protocol UserIntroductionProgressProvider {
    func shouldShowSpotlight(for feature: SpotlightableFeatureKey, toUserWith userID: UserID) -> Bool
    func markSpotlight(for feature: SpotlightableFeatureKey, asSeen seen: Bool, byUserWith userID: UserID)
}
