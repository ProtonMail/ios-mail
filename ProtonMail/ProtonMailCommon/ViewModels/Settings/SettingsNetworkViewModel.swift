//
//  SettingsNetworkViewModel.swift
//  Proton Mail
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

import Foundation

class SettingsNetworkViewModel {
    enum SettingSection {
        case alternativeRouting

        var title: String {
            switch self {
            case .alternativeRouting:
                return LocalString._allow_alternative_routing
            }
        }

        var foot: String {
            switch self {
            case .alternativeRouting:
                return LocalString._settings_alternative_routing_footer
            }
        }

        var head: String {
            switch self {
            case .alternativeRouting:
                return LocalString._settings_alternative_routing_title
            }
        }
    }

    var sections: [SettingSection] = [.alternativeRouting]
    var isDohOn: Bool {
        return self.dohSetting.status == .on
    }

    private var userCache: DohCacheProtocol
    private var dohSetting: DohStatusProtocol

    init(userCache: DohCacheProtocol, dohSetting: DohStatusProtocol) {
        self.userCache = userCache
        self.dohSetting = dohSetting
    }

    func setDohStatus(_ newStatus: Bool) {
        self.dohSetting.status = newStatus ? .on : .off
        self.userCache.isDohOn = newStatus
    }
}
