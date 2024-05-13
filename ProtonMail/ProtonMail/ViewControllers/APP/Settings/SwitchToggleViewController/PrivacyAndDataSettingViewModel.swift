// Copyright (c) 2024 Proton Technologies AG
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

import ProtonCoreUtilities

final class PrivacyAndDataSettingViewModel: SwitchToggleVMProtocol {
    typealias Dependencies = HasUserManager

    var input: SwitchToggleVMInput { self }
    var output: SwitchToggleVMOutput { self }
    let sections: [PrivacyAndDataSettingItem] = [
        .anonymousTelemetry,
        .anonymousCrashReport
    ]
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    private func configureAnalytics() {
        guard !Application.isDebug else { return }
        dependencies.user.updateTelemetryAndCatchCrash()
    }
}

extension PrivacyAndDataSettingViewModel {
    enum PrivacyAndDataSettingItem: CustomStringConvertible, CaseIterable {
        case anonymousTelemetry
        case anonymousCrashReport

        var description: String {
            switch self {
            case .anonymousTelemetry:
                return L10n.PrivacyAndDataSettings.telemetry
            case .anonymousCrashReport:
                return L10n.PrivacyAndDataSettings.crashReport
            }
        }
    }
}

extension PrivacyAndDataSettingViewModel: SwitchToggleVMInput {
    func toggle(for indexPath: IndexPath, to newStatus: Bool, completion: @escaping ToggleCompletion) {
        guard let item = sections[safeIndex: indexPath.section] else {
            completion(nil)
            return
        }
        switch item {
        case .anonymousTelemetry:
            dependencies.user.apiService.perform(
                request: SettingUpdateRequest.telemetry(newStatus),
                response: VoidResponse()
            ) { [weak self] _, response in
                if response.error == nil {
                    self?.dependencies.user.userInfo.telemetry = newStatus.intValue
                    self?.dependencies.user.parentManager?.save()
                    self?.configureAnalytics()
                }
                completion(response.error?.toNSError)
            }
        case .anonymousCrashReport:
            dependencies.user.apiService.perform(
                request: SettingUpdateRequest.crashReports(newStatus),
                response: VoidResponse()
            ) { [weak self] _, response in
                if response.error == nil {
                    self?.dependencies.user.userInfo.crashReports = newStatus.intValue
                    self?.dependencies.user.parentManager?.save()
                    self?.configureAnalytics()
                }
                completion(response.error?.toNSError)
            }
        }
    }
}

extension PrivacyAndDataSettingViewModel: SwitchToggleVMOutput {
    var headerTopPadding: CGFloat { 0 }
    var footerTopPadding: CGFloat { 8 }
    var title: String { L10n.AccountSettings.privacyAndData }
    var sectionNumber: Int { PrivacyAndDataSettingItem.allCases.count }
    var rowNumber: Int { 1 }

    func sectionHeader() -> String? { nil }

    func cellData(for indexPath: IndexPath) -> (title: String, status: Bool)? {
        guard let item = sections[safeIndex: indexPath.section] else {
            return nil
        }
        switch item {
        case .anonymousTelemetry:
            return (item.description, dependencies.user.hasTelemetryEnabled)
        case .anonymousCrashReport:
            return (item.description, dependencies.user.userInfo.hasCrashReportingEnabled)
        }
    }

    func sectionFooter(section: Int) -> ProtonCoreUtilities.Either<String, NSAttributedString>? {
        guard let section = sections[safeIndex: section] else {
            return nil
        }
        switch section {
        case .anonymousTelemetry:
            return .left(L10n.PrivacyAndDataSettings.telemetrySubtitle)
        case .anonymousCrashReport:
            return .left(L10n.PrivacyAndDataSettings.crashReportSubtitle)
        }
    }
}
