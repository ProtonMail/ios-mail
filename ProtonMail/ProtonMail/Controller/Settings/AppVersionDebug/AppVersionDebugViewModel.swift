//
//  AppVersionDebugViewModel.swift
//  ProtonMail
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

enum AppVersionDebugSection: CaseIterable {
    case info
    case push
}

protocol NotificationRegistrar: AnyObject {
    var shouldForceReportAll: Bool { get set }
    func registerForRemoteNotifications()
}

extension PushNotificationService: NotificationRegistrar {}

protocol PushTimestampProvider {
    var lastReceivedPushTimestamp: String { get }
}

extension SharedUserDefaults: PushTimestampProvider {}

final class AppVersionDebugViewModel {

    let notificationsRegistrar: NotificationRegistrar
    let timestampProvider: PushTimestampProvider

    init(notificationsRegistrar: NotificationRegistrar = sharedServices.get(by: PushNotificationService.self),
         timestampProvider: PushTimestampProvider = SharedUserDefaults()) {
        self.notificationsRegistrar = notificationsRegistrar
        self.timestampProvider = timestampProvider
    }
    var sections: [AppVersionDebugSection] {
        AppVersionDebugSection.allCases
    }

    func sectionName(for section: AppVersionDebugSection) -> String {
        switch section {
        case .info:
            return LocalString._app_information
        case .push:
            return LocalString._push_notification
        }
    }

    func rowDescription(for section: AppVersionDebugSection) -> String {
        switch section {
        case .info:
            return "App version"
        case .push:
            return LocalString._last_push_received
        }
    }

    func rowValue(for section: AppVersionDebugSection) -> String {
        switch section {
        case .info:
            var appVersion = "Unknown Version"
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                appVersion = "\(version)"
            }
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                appVersion = appVersion + " (\(build))"
            }
            return appVersion
        case .push:
            let timestampString = timestampProvider.lastReceivedPushTimestamp
            guard let timestamp = TimeInterval(timestampString) else {
                return timestampString
            }
            let df = DateFormatter()
            df.calendar = Calendar.current
            df.dateStyle = .short
            df.timeStyle = .medium
            return df.string(from: Date(timeIntervalSince1970: timestamp))
        }
    }

    func registerAgainForNotifications() {
        notificationsRegistrar.shouldForceReportAll = true
        notificationsRegistrar.registerForRemoteNotifications()
    }
}
