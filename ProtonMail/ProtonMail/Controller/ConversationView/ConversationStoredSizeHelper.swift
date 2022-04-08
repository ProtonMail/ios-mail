// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import CoreGraphics

class ConversationStoredSizeHelper {
    var storedSize: [String: HeightStoreInfo] = [:]

    func getStoredSize(of messageID: String) -> HeightStoreInfo? {
        return storedSize[messageID]
    }

    func resetStoredSize(of messageID: String) {
        storedSize[messageID] = nil
    }

    /// - Returns: true if the size has changed
    func updateStoredSizeIfNeeded(newHeightInfo: HeightStoreInfo, messageID: String) -> Bool {
        let storedHeightInfo = storedSize[messageID]

        if let oldHeight = storedHeightInfo, oldHeight == newHeightInfo {
            return false
        }

        let isHeightForLoadedPageStored = storedHeightInfo?.loaded == true
        let shouldChangeLoadedHeight = isHeightForLoadedPageStored && storedHeightInfo?.height != newHeightInfo.height
        let isStoredHeightInfoEmpty = storedHeightInfo == nil
        let headerStateHasChanged = newHeightInfo.isHeaderExpanded != storedHeightInfo?.isHeaderExpanded

        if shouldChangeLoadedHeight ||
            !isHeightForLoadedPageStored ||
            isStoredHeightInfoEmpty ||
            headerStateHasChanged {
            storedSize[messageID] = newHeightInfo
        }

        return true
    }
}

struct HeightStoreInfo: Hashable, Equatable {
    let height: CGFloat
    let isHeaderExpanded: Bool
    let loaded: Bool
}
