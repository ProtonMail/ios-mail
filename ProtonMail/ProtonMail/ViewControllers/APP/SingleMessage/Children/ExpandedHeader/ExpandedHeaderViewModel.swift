//
//  ExpandedHeaderViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

final class ExpandedHeaderViewModel {

    var reloadView: (() -> Void)?

    private(set) var infoProvider: MessageInfoProvider {
        didSet { reloadView?() }
    }

    var trackerProtectionRowInfo: (title: NSAttributedString, trackersFound: Bool)? {
        guard let trackerProtectionSummary = infoProvider.trackerProtectionSummary else {
            return nil
        }
        let trackerCount = trackerProtectionSummary.trackers.values.compactMap { $0.count }.reduce(0, +)
        let text = String.localizedStringWithFormat(L11n.EmailTrackerProtection.n_email_trackers_found, trackerCount)
        return (text.apply(style: .CaptionWeak), trackerCount != 0)
    }

    init(infoProvider: MessageInfoProvider) {
        self.infoProvider = infoProvider
    }

    func providerHasChanged(provider: MessageInfoProvider) {
        infoProvider = provider
    }
}
