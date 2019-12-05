//
//  APIService+ErrorExtension.swift
//  ProtonMail - Created on 8/22/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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


import Foundation

let AuthErrorTitle : String          = "AuthRefresh-Error"
let QueueErrorTitle : String         = "Queue-Error"
let CacheErrorTitle : String         = "LocalCache-Error"
let SendingErrorTitle : String       = "Sending-Error"
let ContactsErrorTitle : String      = "Contacts-Error"
let FetchUserInfoErrorTitle : String = "UserInfo-Error"

extension NSError {
    
    func upload(toAnalytics title : String ) -> Void {
        var ver = "1.0.0"
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            ver = version
        }
        
        Analytics.shared.logCustomEvent(customAttributes: [
                                        "CustomEventTitle" : title,
                                        "DeviceModel" : UIDevice.current.model,
                                        "DeviceVersion" : UIDevice.current.systemVersion,
                                        "AppVersion" : "iOS_\(ver)",
                                        "code" : code,
                                        "error_desc": description,
                                        "error_full": localizedDescription,
                                        "error_reason" : "\(String(describing: localizedFailureReason))"])
    }
}
