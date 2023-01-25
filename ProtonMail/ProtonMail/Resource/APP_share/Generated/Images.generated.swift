// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal static let icMagicWand = ImageAsset(name: "ic-magic-wand")
  internal static let icMinusCircleFilled = ImageAsset(name: "ic-minus-circle-filled")
  internal static let composeScheduleStar = ImageAsset(name: "compose_schedule_star")
  internal static let icThreeDotsHorizontal = ImageAsset(name: "ic-three-dots-horizontal")
  internal static let icSmallCheckmark = ImageAsset(name: "ic_small_checkmark")
  internal static let esIcon = ImageAsset(name: "es-icon")
  internal static let launchScreenBackground = ColorAsset(name: "LaunchScreenBackground")
  internal static let launchScreenBrand = ImageAsset(name: "launchScreenBrand")
  internal static let launchScreenLogo = ImageAsset(name: "launchScreenLogo")
  internal static let mailAttachmentDoc = ImageAsset(name: "mail_attachment-doc")
  internal static let mailAttachmentFile = ImageAsset(name: "mail_attachment-file")
  internal static let mailAttachmentJpeg = ImageAsset(name: "mail_attachment-jpeg")
  internal static let mailAttachmentOpen = ImageAsset(name: "mail_attachment-open")
  internal static let mailAttachmentPdf = ImageAsset(name: "mail_attachment-pdf")
  internal static let mailAttachmentPng = ImageAsset(name: "mail_attachment-png")
  internal static let mailAttachmentPpt = ImageAsset(name: "mail_attachment-ppt")
  internal static let mailAttachmentTxt = ImageAsset(name: "mail_attachment-txt")
  internal static let mailAttachmentXls = ImageAsset(name: "mail_attachment-xls")
  internal static let mailAttachmentZip = ImageAsset(name: "mail_attachment-zip")
  internal static let mailAttachment = ImageAsset(name: "mail_attachment")
  internal static let mailAttachmentAudio = ImageAsset(name: "mail_attachment_audio")
  internal static let mailAttachmentFileAudio = ImageAsset(name: "mail_attachment_file_audio")
  internal static let mailAttachmentFileDoc = ImageAsset(name: "mail_attachment_file_doc")
  internal static let mailAttachmentFileGeneral = ImageAsset(name: "mail_attachment_file_general")
  internal static let mailAttachmentFileImage = ImageAsset(name: "mail_attachment_file_image")
  internal static let mailAttachmentFilePdf = ImageAsset(name: "mail_attachment_file_pdf")
  internal static let mailAttachmentFilePpt = ImageAsset(name: "mail_attachment_file_ppt")
  internal static let mailAttachmentFileUnknow = ImageAsset(name: "mail_attachment_file_unknow")
  internal static let mailAttachmentFileVideo = ImageAsset(name: "mail_attachment_file_video")
  internal static let mailAttachmentFileXls = ImageAsset(name: "mail_attachment_file_xls")
  internal static let mailAttachmentFileZip = ImageAsset(name: "mail_attachment_file_zip")
  internal static let mailAttachmentGeneral = ImageAsset(name: "mail_attachment_general")
  internal static let mailAttachmentVideo = ImageAsset(name: "mail_attachment_video")
  internal static let mailStarredActive = ImageAsset(name: "mail_starred-active")
  internal static let mailStarred = ImageAsset(name: "mail_starred")
  internal static let placeholderBoundBox = ImageAsset(name: "placeholder_bound_box")
  internal static let mailFolderNoResultIcon = ImageAsset(name: "mail_folder_no_result_icon")
  internal static let mailLabelCrossIcon = ImageAsset(name: "mail_label_cross_icon")
  internal static let mailNoResultIcon = ImageAsset(name: "mail_no_result_icon")
  internal static let schedulePromotion = ImageAsset(name: "schedule_promotion")
  internal static let upgradeIcon = ImageAsset(name: "upgrade_Icon")
  internal static let referralLogo = ImageAsset(name: "ReferralLogo")
  internal static let icMagnifier = ImageAsset(name: "ic-magnifier")
  internal static let icPenSquare = ImageAsset(name: "ic-pen-square")
  internal static let icStarFilled = ImageAsset(name: "ic-star-filled")
  internal static let magicWand = ImageAsset(name: "magicWand")
  internal static let icChevronDown = ImageAsset(name: "ic-chevron-down")
  internal static let icChevronUp = ImageAsset(name: "ic-chevron-up")
  internal static let pinCodeDel = ImageAsset(name: "pin_code_del")
  internal static let popupBehindImage = ImageAsset(name: "popup_behind_image")
  internal static let touchIdIcon = ImageAsset(name: "touch_id_icon")
  internal static let welcome1 = ImageAsset(name: "welcome_1")
  internal static let welcome2 = ImageAsset(name: "welcome_2")
  internal static let welcome3 = ImageAsset(name: "welcome_3")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  #if os(iOS) || os(tvOS)
  @available(iOS 11.0, tvOS 11.0, *)
  internal func color(compatibleWith traitCollection: UITraitCollection) -> Color {
    let bundle = BundleToken.bundle
    guard let color = Color(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }
  #endif

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}


internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

}

internal extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}


// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
