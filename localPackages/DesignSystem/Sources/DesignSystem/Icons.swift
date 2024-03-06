//
//  File.swift
//  
//
//  Created by xavi on 5/3/24.
//

import SwiftUI

public extension DS.Icon {
    static let icCheckmark = icon(named: "ic-checkmark")
    static let icHamburguer = icon(named: "ic-hamburger")
    static let icStar = icon(named: "ic-star")
    static let icStarFilled = icon(named: "ic-star-filled")
}

public extension DS.Icon {

    static let icFileTypeAttachment = icon(named: "ic-file-type-attachment")
    static let icFileTypeAudio = icon(named: "ic-file-type-audio")
    static let icFileTypeCalendar = icon(named: "ic-file-type-calendar")
    static let icFileTypeCode = icon(named: "ic-file-type-code")
    static let icFileTypeCompressed = icon(named: "ic-file-type-compressed")
    static let icFileTypeDefault = icon(named: "ic-file-type-default")
    static let icFileTypeExcel = icon(named: "ic-file-type-excel")
    static let icFileTypeFont = icon(named: "ic-file-type-font")
    static let icFileTypeIconAudio = icon(named: "ic-file-type-icon-audio")
    static let icFileTypeIconCalendar = icon(named: "ic-file-type-icon-calendar")
    static let icFileTypeIconCode = icon(named: "ic-file-type-icon-code")
    static let icFileTypeIconCompressed = icon(named: "ic-file-type-icon-compressed")
    static let icFileTypeIconDefault = icon(named: "ic-file-type-icon-default")
    static let icFileTypeIconExcel = icon(named: "ic-file-type-icon-excel")
    static let icFileTypeIconFont = icon(named: "ic-file-type-icon-font")
    static let icFileTypeIconImage = icon(named: "ic-file-type-icon-image")
    static let icFileTypeIconKey = icon(named: "ic-file-type-icon-key")
    static let icFileTypeIconKeynote = icon(named: "ic-file-type-icon-keynote")
    static let icFileTypeIconNumbers = icon(named: "ic-file-type-icon-numbers")
    static let icFileTypeIconPages = icon(named: "ic-file-type-icon-pages")
    static let icFileTypeIconPdf = icon(named: "ic-file-type-icon-pdf")
    static let icFileTypeIconPowerPoint = icon(named: "ic-file-type-icon-powerpoint")
    static let icFileTypeIconText = icon(named: "ic-file-type-icon-text")
    static let icFileTypeIconVideo = icon(named: "ic-file-type-icon-video")
    static let icFileTypeIconWord = icon(named: "ic-file-type-icon-word")
    static let icFileTypeImage = icon(named: "ic-file-type-image")
    static let icFileTypeKey = icon(named: "ic-file-type-key")
    static let icFileTypeKeynote = icon(named: "ic-file-type-keynote")
    static let icFileTypeNumbers = icon(named: "ic-file-type-numbers")
    static let icFileTypePages = icon(named: "ic-file-type-pages")
    static let icFileTypePdf = icon(named: "ic-file-type-pdf")
    static let icFileTypePowerpoint = icon(named: "ic-file-type-powerpoint")
    static let icFileTypeText = icon(named: "ic-file-type-text")
    static let icFileTypeVideo = icon(named: "ic-file-type-video")
    static let icFileTypeWord = icon(named: "ic-file-type-word")
}

private extension DS.Icon {
    static func icon(named: String) -> UIImage {
        UIImage(named: named, in: .module, with: nil)!
    }
}


