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

    var trackerProtectionRowInfo: (title: String, trackersFound: Bool)? {
        guard infoProvider.imageProxyEnabled else {
            return nil
        }

        let trackerCount = infoProvider.trackerProtectionSummary?.totalTrackerCount ?? 0
        let trackersFound = trackerCount != 0
        let text = trackersFound ? String.localizedStringWithFormat(
            L11n.EmailTrackerProtection.n_email_trackers_blocked,
            trackerCount
        ) : L11n.EmailTrackerProtection.no_email_trackers_found
        return (text, trackersFound)
    }

    init(infoProvider: MessageInfoProvider) {
        self.infoProvider = infoProvider
    }

    func providerHasChanged(provider: MessageInfoProvider) {
        infoProvider = provider
    }
}
