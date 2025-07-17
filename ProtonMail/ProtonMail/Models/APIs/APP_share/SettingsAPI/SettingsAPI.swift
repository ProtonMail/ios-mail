//
//  SettingAPI.swift
//  Proton Mail - Created on 7/13/15.
//
//
//  Copyright (c) 2019 Proton AG
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
import ProtonCoreDataModel
import ProtonCoreNetworking

/**
 [Settings API Part 1]:
 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_mail_settings.md
 [Settings API Part 2]:
 https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_settings.md
 
 Settings API
 - Doc: [Settings API Part 1], [Settings API Part 2]
 */
struct SettingsAPI {
    /// base settings api path
    static let path: String = "/\(Constants.App.API_PREFIXED)/settings"
}

final class SettingsResponse: Response {
    var userSettings: [String: Any]?
    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        if let settings = response["UserSettings"] as? [String: Any] {
            self.userSettings = settings
        }
        return true
    }
}

// Mark : get mail settings -- MailSettingsResponse
struct GetMailSettings: Request {
    var path: String {
        return SettingsAPI.path
    }
}

final class MailSettingsResponse: Response {
    var mailSettings: [String: Any]?
    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        if let settings = response["MailSettings"] as? [String: Any] {
            self.mailSettings = settings
        }
        return true
    }
}
