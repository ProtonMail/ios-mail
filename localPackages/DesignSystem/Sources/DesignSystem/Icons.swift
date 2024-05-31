//
//  File.swift
//  
//
//  Created by xavi on 5/3/24.
//

import SwiftUI

public extension DS.Icon {
    static let icArrowOutFromRectangle = icon(named: "ic-arrow-out-from-rectangle")

    static let icBug = icon(named: "ic-bug")
    static let icCheckmark = icon(named: "ic-checkmark")
    static let icChevronLeft = icon(named: "ic-chevron-left")
    static let icChevronDown = icon(named: "ic-chevron-down")
    static let icCircleFilled = icon(named: "ic-circle-filled")
    static let icClock = icon(named: "ic-clock")
    static let icCogWheel = icon(named: "ic-cog-wheel")
    static let icHamburguer = icon(named: "ic-hamburger")
    static let icArchiveBox = icon(named: "ic-archive-box")
    static let icEnvelopes = icon(named: "ic-envelopes")
    static let icFile = icon(named: "ic-file")
    static let icFire = icon(named: "ic-fire")
    static let icFolder = icon(named: "ic-folder")
    static let icFolders = icon(named: "ic-folders")
    static let icInbox = icon(named: "ic-inbox")
    static let icMinus = icon(named: "ic-minus")
    static let icPaperClip = icon(named: "ic-paper-clip")
    static let icPaperPlane = icon(named: "ic-paper-plane")
    static let icPencil = icon(named: "ic-pencil")
    static let icPlus = icon(named: "ic-plus")
    static let icStarFilled = icon(named: "ic-star-filled")
    static let icTrash = icon(named: "ic-trash")
    static let icTrashCross = icon(named: "ic-trash-cross")

}

// MARK: mailbox messages

public extension DS.Icon {
    static let icForward = icon(named: "ic-forward")
    static let icReplay = icon(named: "ic-reply")
    static let icReplayAll = icon(named: "ic-reply-all")
}

// MARK: mailbox item actions

public extension DS.Icon {
    static let icEnvelope = icon(named: "ic-envelope")
    static let icEnvelopeDot = icon(named: "ic-envelope-dot")
    static let icEnvelopeOpen = icon(named: "ic-envelope-open")
    static let icFolderArrowIn = icon(named: "ic-folder-arrow-in")
    static let icStar = icon(named: "ic-star")
    static let icStarSlash = icon(named: "ic-star-slash")
    static let icTag = icon(named: "ic-tag")
    static let icThreeDotsHorizontal = icon(named: "ic-three-dots-horizontal")
}

// MARK: File type icons

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
