// swiftlint:disable:this file_name
//
//  MessageLocation+OriginImage.swift
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

import UIKit
import ProtonCore_UIFoundations

extension Message.Location {

    func originImage(viewMode: ViewMode = .singleMessage) -> UIImage? {
        switch self {
        case .archive:
            return IconProvider.archiveBox
        case .draft:
            return viewMode.originImage
        case .sent:
            return IconProvider.paperPlane
        case .spam:
            return IconProvider.fire
        case .trash:
            return IconProvider.trash
        case .inbox:
            return IconProvider.inbox
        case .starred, .allmail:
            return nil
        }
    }

}

private extension ViewMode {

    var originImage: UIImage {
        switch self {
        case .singleMessage:
            return IconProvider.pencil
        case .conversation:
            return IconProvider.fileLines
        }
    }

}
