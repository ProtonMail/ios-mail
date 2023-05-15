//
//  SideMenuPreferences.swift
//  SideMenu
//
//  Created by kukushi on 21/02/2018.
//  Copyright © 2018 kukushi. All rights reserved.
//

import UIKit

extension SideMenuController {
    /// The preferences of side menu controller.
    public struct Preferences {

        /// The animation that will apply to the status bar when the menu is revealed/hidden.
        @available(iOS, deprecated: 13.0, message: "Status bar animation no longer work after iOS 13")
        public enum StatusBarBehavior {
            /// Nothing will happen to the status bar.
            case none
            /// The status bar will slide up when revealed and slide down when hidden.
            case slide
            /// The status bar will fade out when revealed and show up when hidden.
            case fade
            /// The status bar on the side menu will be hidden (without animation),
            ///               while the one the on content view will still show.
            case hideOnMenu
        }

        /// The direction where menu will show up from.
        public enum MenuDirection {
            /// Side menu will reveal from the left side.
            case left
            /// Side menu will reveal from the right side.
            case right
        }

        /// The menu view position compared to the content view.
        public enum MenuPosition {
            /// Menu view is placed above the content view.
            case above
            /// Menu view is placed below the content view.
            case under
            /// Menu view is placed in the same layer with the content view.
            case sideBySide
        }

        public struct Animation {
            /// The animation interval of revealing side menu. Default is 0.4.
            public var revealDuration: TimeInterval = 0.4

            /// The animation interval of hiding side menu. Default is 0.4.
            public var hideDuration: TimeInterval = 0.4

            /// The animation option of reveal/hide. Default is `.curveEaseInOut`.
            public var options: UIView.AnimationOptions = .curveEaseInOut

            /// The amping ratio option used in the revealing and hiding animation of the menu. The default is 1.
            public var dampingRatio: CGFloat = 1

            /// The ``initialSpringVelocity`` option used in the revealing and hiding animation of the menu. The default is 1.
            public var initialSpringVelocity: CGFloat = 1

            /// Whether a shadow effect should be added on content view when revealing the menu. The default is true.
            /// If the position is `.under`, the shadow effect will not be added even if this value is set to `true`.
            public var shouldAddShadowWhenRevealing = true

            /// The shadow's alpha when showing on the content view. Default is 0.2.
            public var shadowAlpha: CGFloat = 0.2

            /// The shadow's color when showing on the content view. Default is black.
            public var shadowColor: UIColor = .black

            /// Whether we should add a blurr effect on shadow when revealing
            public var shouldAddBlurWhenRevealing = false
        }

        public struct Configuration {
            /// The width of the side menu. The default is 300.
            /// Note that you should only modify this property before the side menu controller is initialized.
            public var menuWidth: CGFloat = 300

            /// The position of the side menu. Default is `.above`.
            /// Note that you should only modify this property before the side menu controller is initialized.
            public var position: MenuPosition = .above

            /// Whether the direction of side menu should be reversed when the user interaction layout direction is RTL.
            /// More specific, when the app is using a right to left (RTL) language, the direction of side menu will be
            /// reversed
            public var shouldRespectLanguageDirection = true

            /// The direction of side menu. Default is `.left`.
            /// Note that you should only modify this property before the side menu controller is initialized.
            public var direction: MenuDirection = .left

            /// The status bar behavior when menu revealed / hidden. Default is `.none`.
            @available(iOS, deprecated: 13.0, message: "Status bar animation no longer work after iOS 13")
            public var statusBarBehavior: StatusBarBehavior = .none

            /// Whether the pan gesture should be enabled. The default is true.
            public var enablePanGesture = true

            /// If enabled, the menu view will act like a rubber band when reaching the border. The default is true.
            public var enableRubberEffectWhenPanning = true

            /// If enabled, the menu view will be hidden when the app entering background. The default is false.
            public var hideMenuWhenEnteringBackground = false

            /// The cache key for the first content view controller.
            public var defaultCacheKey: String?

            /// The side menu should use content's supported orientations. Default is false.
            public var shouldUseContentSupportedOrientations: Bool = false

            /// The supported orientations of side menu controller. Default is `.portrait`.
            public var supportedOrientations: UIInterfaceOrientationMask = .allButUpsideDown
            
            /// The side menu shouldAutorotate. Default is `true`.
            public var shouldAutorotate: Bool = true
            
            /// The sensitivity of the pan gesture recognizer revealing menu view controller.
            public var panGestureSensitivity: CGFloat = 0.25

            /// If the side menu should keep open on rotation. Default is false.
            public var shouldKeepMenuOpen: Bool = false
        }

        /// The basic configuration of side menu
        public var basic = Configuration()

        /// The animation configuration of side menu
        public var animation = Animation()
    }
}
