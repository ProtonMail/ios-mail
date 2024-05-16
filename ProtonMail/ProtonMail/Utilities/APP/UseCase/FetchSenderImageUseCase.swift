// Copyright (c) 2023 Proton Technologies AG
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

import Foundation
import ProtonCoreDataModel
import UIKit

typealias FetchSenderImageUseCase = UseCase<UIImage?, FetchSenderImage.Params>

final class FetchSenderImage: FetchSenderImageUseCase {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    override func executionBlock(params: Params, callback: @escaping Callback) {
        guard
            dependencies.featureFlagCache.isFeatureFlag(.senderImage, enabledForUserWithID: params.userID),
            !dependencies.mailSettings.hideSenderImages
        else {
            callback(.failure(FetchSenderImageError.featureDisabled))
            return
        }

        dependencies.senderImageService.fetchSenderImage(
            email: params.senderImageRequestInfo.senderAddress,
            isDarkMode: params.senderImageRequestInfo.isDarkMode,
            size: .init(scale: params.scale),
            bimiSelector: params.senderImageRequestInfo.bimiSelector,
            completion: { result in
                switch result {
                case .success(let imageData):
                    if let image = UIImage(data: imageData) {
                        image.prepareForDisplay(completionHandler: { preparedImage in
                            callback(.success(preparedImage))
                        })
                    } else {
                        callback(.success(nil))
                    }
                case .failure(let error):
                    callback(.failure(error))
                }
            })
    }
}

extension FetchSenderImage {
    enum FetchSenderImageError: Error {
        case featureDisabled
    }

    struct Params {
        let senderImageRequestInfo: SenderImageRequestInfo
        let scale: CGFloat
        let userID: UserID
    }

    struct Dependencies {
        let featureFlagCache: FeatureFlagCache
        let senderImageService: SenderImageService
        let mailSettings: MailSettings

        init(
            featureFlagCache: FeatureFlagCache,
            senderImageService: SenderImageService,
            mailSettings: MailSettings
        ) {
            self.featureFlagCache = featureFlagCache
            self.senderImageService = senderImageService
            self.mailSettings = mailSettings
        }
    }
}
