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

import AVFoundation
import InboxCoreUI
import SwiftUI

final class AttachmentSourcePickerSheetModel: ObservableObject {
    private let cameraPermissionProvider: CameraPermissionProvider
    @Published var alertModel: AlertModel?

    init(cameraPermissionProvider: CameraPermissionProvider = .production) {
        self.cameraPermissionProvider = cameraPermissionProvider
    }

    func isAuthorized(source: AttachmentSource) -> Bool {
        if source == .camera {
            switch cameraPermissionProvider.authorizationStatus(.video) {
            case .authorized, .notDetermined:
                return true
            case .denied, .restricted:
                return false
            @unknown default:
                return false
            }
        } else {
            return true
        }
    }

    func setAlertModelForMissingCameraPermission() {
        alertModel = .init(
            title: L10n.Attachments.cameraAccessDeniedTitle,
            message: L10n.Attachments.cameraAccessDeniedMessage,
            actions: [.init(details: CameraPermissionInfo(), action: { [weak self] in self?.alertModel = nil })]
        )
    }
}

private struct CameraPermissionInfo: AlertActionInfo {
    let info: (title: LocalizedStringResource, buttonRole: ButtonRole) = (L10n.Common.gotIt, .cancel)
}

struct CameraPermissionProvider {
    let authorizationStatus: (AVMediaType) -> AVAuthorizationStatus
}

extension CameraPermissionProvider {
    static var production: Self {
        .init(authorizationStatus: AVCaptureDevice.authorizationStatus)
    }
}
