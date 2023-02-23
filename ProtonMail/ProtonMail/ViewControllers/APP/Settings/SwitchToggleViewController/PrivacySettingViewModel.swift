// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCore_DataModel
import struct UIKit.CGFloat

extension PrivacySettingViewModel {
    enum SettingPrivacyItem: CustomStringConvertible, CaseIterable {
        case autoLoadRemoteContent
        case autoLoadEmbeddedImage
        case blockEmailTracking
        case linkOpeningMode
        case metadataStripping

        var description: String {
            switch self {
            case .autoLoadRemoteContent:
                return LocalString._auto_load_remote_content
            case .autoLoadEmbeddedImage:
                return LocalString._auto_load_embedded_images
            case .blockEmailTracking:
                return LocalString._block_email_tracking
            case .linkOpeningMode:
                return LocalString._request_link_confirmation
            case .metadataStripping:
                return LocalString._strip_metadata
            }
        }
    }
}

final class PrivacySettingViewModel: SwitchToggleVMProtocol {
    var input: SwitchToggleVMInput { self }
    var output: SwitchToggleVMOutput { self }

    var privacySections: [SettingPrivacyItem] {
        var sections: [SettingPrivacyItem] = [
            .autoLoadRemoteContent,
            .autoLoadEmbeddedImage,
            .blockEmailTracking,
            .linkOpeningMode,
            .metadataStripping
        ]

        if !UserInfo.isImageProxyAvailable {
            sections.removeAll { $0 == .blockEmailTracking }
        }

        return sections
    }

    let user: UserManager
    private(set) var metaStrippingProvider: AttachmentMetadataStrippingProtocol

    init(user: UserManager, metaStrippingProvider: AttachmentMetadataStrippingProtocol) {
        self.user = user
        self.metaStrippingProvider = metaStrippingProvider
    }
}

extension PrivacySettingViewModel: SwitchToggleVMInput {
    func toggle(for indexPath: IndexPath, to newStatus: Bool, completion: @escaping ToggleCompletion) {
        guard indexPath.section < sectionNumber,
              let item = privacySections[safe: indexPath.row] else {
            completion(NSError.badParameter("Bad indexPath"))
            return
        }
        switch item {
        case .autoLoadRemoteContent:
            let status: UpdateImageAutoloadSetting.Setting = newStatus ? .show : .hide
            updateAutoLoadImageStatus(to: status, imageType: .remote, completion: completion)
        case .autoLoadEmbeddedImage:
            let status: UpdateImageAutoloadSetting.Setting = newStatus ? .show : .hide
            updateAutoLoadImageStatus(to: status, imageType: .embedded, completion: completion)
        case .blockEmailTracking:
            updateBlockEmailTrackingStatus(newStatus: newStatus, completion: completion)
        case .linkOpeningMode:
            updateLinkConfirmation(to: newStatus, completion: completion)
        case .metadataStripping:
            metaStrippingProvider.metadataStripping = newStatus ? .stripMetadata : .sendAsIs
            completion(nil)
        }
    }
}

extension PrivacySettingViewModel: SwitchToggleVMOutput {
    var title: String { LocalString._privacy }
    var sectionNumber: Int { 1 }
    var rowNumber: Int { privacySections.count }
    var headerTopPadding: CGFloat { 8 }
    var footerTopPadding: CGFloat { 0 }

    func cellData(for indexPath: IndexPath) -> (title: String, status: Bool)? {
        guard indexPath.section < sectionNumber,
              let item = privacySections[safe: indexPath.row] else {
            return nil
        }
        let status = status(of: item)
        return (item.description, status)
    }

    func sectionHeader(of section: Int) -> String? {
        nil
    }

    func sectionFooter(of section: Int) -> String? {
        nil
    }
}

extension PrivacySettingViewModel {
    private func status(of item: SettingPrivacyItem) -> Bool {
        switch item {
        case .autoLoadRemoteContent:
            return user.userInfo.isAutoLoadRemoteContentEnabled
        case .autoLoadEmbeddedImage:
            return user.userInfo.isAutoLoadEmbeddedImagesEnabled
        case .blockEmailTracking:
            return user.userInfo.imageProxy.contains(.imageProxy)
        case .linkOpeningMode:
            return user.userInfo.linkConfirmation == .confirmationAlert
        case .metadataStripping:
            return metaStrippingProvider.metadataStripping == .stripMetadata
        }
    }

    private func updateAutoLoadImageStatus(to newStatus: UpdateImageAutoloadSetting.Setting,
                                           imageType: UpdateImageAutoloadSetting.ImageType,
                                           completion: @escaping ToggleCompletion) {
        user.userService.updateImageAutoloadSetting(
            currentAuth: user.authCredential,
            userInfo: user.userInfo,
            imageType: imageType,
            setting: newStatus,
            completion: saveData(thenPerform: completion)
        )
    }

    func updateBlockEmailTrackingStatus(newStatus: Bool, completion: @escaping (NSError?) -> Void) {
        user.userService.updateBlockEmailTracking(
            authCredential: user.authCredential,
            userInfo: user.userInfo,
            action: newStatus ? .add : .remove,
            completion: saveData(thenPerform: completion)
        )
    }

    private func updateLinkConfirmation(to newStatus: Bool, completion: @escaping ToggleCompletion) {
        user.userService.updateLinkConfirmation(
            auth: user.authCredential,
            user: user.userInfo,
            newStatus ? .confirmationAlert : .openAtWill,
            completion: saveData(thenPerform: completion)
        )
    }

    private func saveData(thenPerform completion: @escaping (NSError?) -> Void) -> (NSError?) -> Void {
        { error in
            if error == nil {
                self.user.save()
            }
            completion(error)
        }
    }
}
