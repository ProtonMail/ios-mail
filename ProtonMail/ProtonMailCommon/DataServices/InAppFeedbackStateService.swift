// Copyright (c) 2021 Proton Technologies AG
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

import ProtonCore_DataModel

protocol InAppFeedbackStateServiceProtocol: FeatureFlagsSubscribeProtocol {
    var delegates: [InAppFeedbackStateServiceDelegate] { get }
    var isEnable: Bool { get }
    var localFeatureFlag: Bool { get }

    func register(delegate: InAppFeedbackStateServiceDelegate)
    func notifyDelegatesAboutFlagChange()
}

protocol InAppFeedbackStateServiceDelegate: AnyObject {
    func inAppFeedbackFeatureFlagHasChanged(enable: Bool)
}

class InAppFeedbackStateService: InAppFeedbackStateServiceProtocol {
    private let delegatesStore: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    var delegates: [InAppFeedbackStateServiceDelegate] {
        delegatesStore.allObjects
            .compactMap { $0 as? InAppFeedbackStateServiceDelegate }
    }
    private(set) var isEnable: Bool = false
    let localFeatureFlag: Bool

    init(localFeatureFlag: Bool = UserInfo.isInAppFeedbackEnabled) {
        self.localFeatureFlag = localFeatureFlag
    }

    func register(delegate: InAppFeedbackStateServiceDelegate) {
        delegatesStore.add(delegate)
    }

    func notifyDelegatesAboutFlagChange() {
        delegates.forEach {
            $0.inAppFeedbackFeatureFlagHasChanged(enable: isEnable)
        }
    }
}

extension InAppFeedbackStateService: FeatureFlagsSubscribeProtocol {
    func handleNewFeatureFlags(_ featureFlags: [String: Any]) {
        guard let newFlag = featureFlags[FeatureFlagKey.inAppFeedback.rawValue] as? Int else {
            return
        }
        var convertedFlag = false
        switch newFlag {
        case 0:
            convertedFlag = false
        case 1:
            convertedFlag = true
        default:
            break
        }

        if self.localFeatureFlag == false {
            convertedFlag = false
            return
        }

        if isEnable != convertedFlag {
            isEnable = convertedFlag
            notifyDelegatesAboutFlagChange()
        }
    }
}
