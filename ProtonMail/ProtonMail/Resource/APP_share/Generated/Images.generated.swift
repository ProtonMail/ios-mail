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
  internal static let icMinusCircleFilled = ImageAsset(name: "ic-minus-circle-filled")
  internal static let composeScheduleStar = ImageAsset(name: "compose_schedule_star")
  internal static let launchScreenBackground = ColorAsset(name: "LaunchScreenBackground")
  internal static let launchScreenMailLogo = ImageAsset(name: "LaunchScreenMailLogo")
  internal static let icFileTypeAudio = ImageAsset(name: "ic-file-type-audio")
  internal static let icFileTypeCalendar = ImageAsset(name: "ic-file-type-calendar")
  internal static let icFileTypeCode = ImageAsset(name: "ic-file-type-code")
  internal static let icFileTypeCompressed = ImageAsset(name: "ic-file-type-compressed")
  internal static let icFileTypeDefault = ImageAsset(name: "ic-file-type-default")
  internal static let icFileTypeExcel = ImageAsset(name: "ic-file-type-excel")
  internal static let icFileTypeFont = ImageAsset(name: "ic-file-type-font")
  internal static let icFileTypeIconAudio = ImageAsset(name: "ic-file-type-icon-audio")
  internal static let icFileTypeIconCalendar = ImageAsset(name: "ic-file-type-icon-calendar")
  internal static let icFileTypeIconCode = ImageAsset(name: "ic-file-type-icon-code")
  internal static let icFileTypeIconCompressed = ImageAsset(name: "ic-file-type-icon-compressed")
  internal static let icFileTypeIconDefault = ImageAsset(name: "ic-file-type-icon-default")
  internal static let icFileTypeIconExcel = ImageAsset(name: "ic-file-type-icon-excel")
  internal static let icFileTypeIconFont = ImageAsset(name: "ic-file-type-icon-font")
  internal static let icFileTypeIconImage = ImageAsset(name: "ic-file-type-icon-image")
  internal static let icFileTypeIconKey = ImageAsset(name: "ic-file-type-icon-key")
  internal static let icFileTypeIconKeynote = ImageAsset(name: "ic-file-type-icon-keynote")
  internal static let icFileTypeIconNumbers = ImageAsset(name: "ic-file-type-icon-numbers")
  internal static let icFileTypeIconPages = ImageAsset(name: "ic-file-type-icon-pages")
  internal static let icFileTypeIconPdf = ImageAsset(name: "ic-file-type-icon-pdf")
  internal static let icFileTypeIconPowerpoint = ImageAsset(name: "ic-file-type-icon-powerpoint")
  internal static let icFileTypeIconText = ImageAsset(name: "ic-file-type-icon-text")
  internal static let icFileTypeIconVideo = ImageAsset(name: "ic-file-type-icon-video")
  internal static let icFileTypeIconWord = ImageAsset(name: "ic-file-type-icon-word")
  internal static let icFileTypeImage = ImageAsset(name: "ic-file-type-image")
  internal static let icFileTypeKey = ImageAsset(name: "ic-file-type-key")
  internal static let icFileTypeKeynote = ImageAsset(name: "ic-file-type-keynote")
  internal static let icFileTypeNumbers = ImageAsset(name: "ic-file-type-numbers")
  internal static let icFileTypePages = ImageAsset(name: "ic-file-type-pages")
  internal static let icFileTypePdf = ImageAsset(name: "ic-file-type-pdf")
  internal static let icFileTypePowerpoint = ImageAsset(name: "ic-file-type-powerpoint")
  internal static let icFileTypeText = ImageAsset(name: "ic-file-type-text")
  internal static let icFileTypeVideo = ImageAsset(name: "ic-file-type-video")
  internal static let icFileTypeWord = ImageAsset(name: "ic-file-type-word")
  internal static let placeholderBoundBox = ImageAsset(name: "placeholder_bound_box")
  internal static let icSquare = ImageAsset(name: "ic_square")
  internal static let icSquareChecked = ImageAsset(name: "ic_square_checked")
  internal static let mailFolderNoResultIcon = ImageAsset(name: "mail_folder_no_result_icon")
  internal static let mailLabelCrossIcon = ImageAsset(name: "mail_label_cross_icon")
  internal static let mailNoResultIcon = ImageAsset(name: "mail_no_result_icon")
  internal static let icPaperPlaneClock = ImageAsset(name: "ic-paper-plane-clock")
  internal static let upgradeIconBig = ImageAsset(name: "upgrade-icon-big")
  internal static let upgradeIcon = ImageAsset(name: "upgrade_Icon")
  internal static let upsellButton = ImageAsset(name: "upsell_button")
  internal static let upsellPromotion = ImageAsset(name: "upsell_promotion")
  internal static let referralLogo = ImageAsset(name: "ReferralLogo")
  internal static let searchNoResult = ImageAsset(name: "search_no_result")
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
