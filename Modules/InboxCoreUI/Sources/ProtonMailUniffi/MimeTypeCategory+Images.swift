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

import InboxDesignSystem
import proton_app_uniffi

import struct DeveloperToolsSupport.ImageResource

public extension MimeTypeCategory {
    var icon: ImageResource {
        switch self {
        case .audio:
            DS.Icon.icFileTypeIconAudio
        case .calendar:
            DS.Icon.icFileTypeIconCalendar
        case .code:
            DS.Icon.icFileTypeIconCode
        case .compressed:
            DS.Icon.icFileTypeIconCompressed
        case .default, .unknown:
            DS.Icon.icFileTypeIconDefault
        case .excel:
            DS.Icon.icFileTypeIconExcel
        case .font:
            DS.Icon.icFileTypeIconFont
        case .image:
            DS.Icon.icFileTypeIconImage
        case .key:
            DS.Icon.icFileTypeIconKey
        case .keynote:
            DS.Icon.icFileTypeIconKeynote
        case .numbers:
            DS.Icon.icFileTypeIconNumbers
        case .pages:
            DS.Icon.icFileTypeIconPages
        case .pdf:
            DS.Icon.icFileTypeIconPdf
        case .powerpoint:
            DS.Icon.icFileTypeIconPowerPoint
        case .text:
            DS.Icon.icFileTypeIconText
        case .video:
            DS.Icon.icFileTypeIconVideo
        case .word:
            DS.Icon.icFileTypeIconWord
        }
    }

    var bigIcon: ImageResource {
        switch self {
        case .audio:
            DS.Icon.icFileTypeAudio
        case .calendar:
            DS.Icon.icFileTypeCalendar
        case .code:
            DS.Icon.icFileTypeCode
        case .compressed:
            DS.Icon.icFileTypeCompressed
        case .default, .unknown:
            DS.Icon.icFileTypeDefault
        case .excel:
            DS.Icon.icFileTypeExcel
        case .font:
            DS.Icon.icFileTypeFont
        case .image:
            DS.Icon.icFileTypeImage
        case .key:
            DS.Icon.icFileTypeKey
        case .keynote:
            DS.Icon.icFileTypeKeynote
        case .numbers:
            DS.Icon.icFileTypeNumbers
        case .pages:
            DS.Icon.icFileTypePages
        case .pdf:
            DS.Icon.icFileTypePdf
        case .powerpoint:
            DS.Icon.icFileTypePowerpoint
        case .text:
            DS.Icon.icFileTypeText
        case .video:
            DS.Icon.icFileTypeVideo
        case .word:
            DS.Icon.icFileTypeWord
        }
    }
}
