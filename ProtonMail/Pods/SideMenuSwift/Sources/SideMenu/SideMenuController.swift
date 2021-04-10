//
//  SideMenuController.swift
//  SideMenu
//
//  Created by kukushi on 10/02/2018.
//  Copyright © 2018 kukushi. All rights reserved.
//

import UIKit

// MARK: SideMenuController

/// A container view controller owns a menu view controller and a content view controller.
///
/// The overall architecture of SideMenuController is:
/// SideMenuController
/// ├── Menu View Controller
/// └── Content View Controller
open class SideMenuController: UIViewController {

    /// Configure this property to change the behavior of SideMenuController;
    public static var preferences = Preferences()
    private var preferences: Preferences {
        return type(of: self).preferences
    }

    private lazy var adjustedDirection = Preferences.MenuDirection.left

    private var isInitiatedFromStoryboard: Bool {
        return storyboard != nil
    }

    /// The identifier of content view controller segue.
    /// If the SideMenuController instance is initiated from IB, this identifier will
    /// be used to retrieve the content view controller.
    @IBInspectable public var contentSegueID: String = SideMenuSegue.ContentType.content.rawValue

    /// The identifier of menu view controller segue.
    /// If the SideMenuController instance is initiated from IB, this identifier will
    /// be used to retrieve the menu view controller.
    @IBInspectable public var menuSegueID: String = SideMenuSegue.ContentType.menu.rawValue

    /// Caching
    private lazy var lazyCachedViewControllerGenerators: [String: () -> UIViewController?] = [:]
    private lazy var lazyCachedViewControllers: [String: UIViewController] = [:]

    /// The side menu controller's delegate object.
    public weak var delegate: SideMenuControllerDelegate?

    /// Tell whether `setContentViewController` setter should call the delegate.
    /// Work as a workaround when switching content view controller from other animation approach which also change the
    /// `contentViewController`.
    // swiftlint:disable:next weak_delegate
    private var shouldCallSwitchingDelegate = true

    /// The content view controller. Changes its value will change the display immediately.
    /// If the new value is already one of the side menu controller's child controllers, nothing will happen beside value change.
    /// If you want a caching approach, use `setContentViewController(with)`. Its value should not be nil.
    // swiftlint:disable:next implicitly_unwrapped_optional
    open var contentViewController: UIViewController! {
        didSet {
            guard contentViewController !== oldValue &&
                isViewLoaded &&
                !children.contains(contentViewController) else {
                    return
            }

            if shouldCallSwitchingDelegate {
                delegate?.sideMenuController(self, willShow: contentViewController, animated: false)
            }

            load(contentViewController, on: contentContainerView)
            contentContainerView.sendSubviewToBack(contentViewController.view)
            unload(oldValue)

            if shouldCallSwitchingDelegate {
                delegate?.sideMenuController(self, didShow: contentViewController, animated: false)
            }

            setNeedsStatusBarAppearanceUpdate()
        }
    }

    /// The menu view controller. Its value should not be nil.
    // swiftlint:disable:next implicitly_unwrapped_optional
    open var menuViewController: UIViewController! {
        didSet {
            guard menuViewController !== oldValue && isViewLoaded else {
                return
            }

            load(menuViewController, on: menuContainerView)
            unload(oldValue)
        }
    }

    private let menuContainerView = UIView()
    private let contentContainerView = UIView()
    private var statusBarScreenShotView: UIView?

    /// Return true if the menu is now revealing.
    open var isMenuRevealed = false

    private var shouldShowShadowOnContent: Bool {
        return preferences.animation.shouldAddShadowWhenRevealing && preferences.basic.position != .under
    }

    /// States used in panning gesture
    private var isValidatePanningBegan = false
    private var panningBeganPointX: CGFloat = 0

    private var isContentOrMenuNotInitialized: Bool {
        return menuViewController == nil || contentViewController == nil
    }

    /// The view responsible for tapping to hide the menu and shadow
    private weak var contentContainerOverlay: UIView?

    // The pan gesture recognizer responsible for revealing and hiding side menu
    private weak var panGestureRecognizer: UIPanGestureRecognizer?

    var shouldReverseDirection: Bool {
        guard preferences.basic.shouldRespectLanguageDirection else {
            return false
        }
        let attribute = view.semanticContentAttribute
        let layoutDirection = UIView.userInterfaceLayoutDirection(for: attribute)
        return layoutDirection == .rightToLeft
    }

    // MARK: Initialization

    /// Creates a SideMenuController instance with the content view controller and menu view controller.
    ///
    /// - Parameters:
    ///   - contentViewController: the content view controller
    ///   - menuViewController: the menu view controller
    public convenience init(contentViewController: UIViewController, menuViewController: UIViewController) {
        self.init(nibName: nil, bundle: nil)

        // Assignment in initializer won't trigger the setter
        self.contentViewController = contentViewController
        self.menuViewController = menuViewController
    }

    deinit {
        unregisterNotifications()
    }

    // MARK: Life Cycle

    // `SideMenu` may be initialized from Storyboard, thus we shouldn't load the view in `loadView()`.
    // As mentioned by Apple, "If you use Interface Builder to create your views and initialize the view controller,
    // you must not override this method."
    open override func viewDidLoad() {
        super.viewDidLoad()

        // Setup from the IB
        // Side menu may be initialized from the IB while segues are not used, thus passing the performing of
        // segues if content and menu is already set
        if isInitiatedFromStoryboard && isContentOrMenuNotInitialized {
            // Note that if you are using the `SideMenuController` from the IB, you must supply the default or
            // custom view controller ID in the storyboard.
            performSegue(withIdentifier: contentSegueID, sender: self)
            performSegue(withIdentifier: menuSegueID, sender: self)
        }

        if isContentOrMenuNotInitialized {
            fatalError("[SideMenuSwift] `menuViewController` or `contentViewController` should not be nil.")
        }

        contentContainerView.frame = view.bounds
        view.addSubview(contentContainerView)

        resolveDirection(with: contentContainerView)

        menuContainerView.frame = sideMenuFrame(visibility: false)
        view.addSubview(menuContainerView)

        load(contentViewController, on: contentContainerView)
        load(menuViewController, on: menuContainerView)

        if preferences.basic.position == .under {
            view.bringSubviewToFront(contentContainerView)
        }

        // Forwarding status bar style/hidden status to content view controller
        setNeedsStatusBarAppearanceUpdate()

        if let key = preferences.basic.defaultCacheKey {
            lazyCachedViewControllers[key] = contentViewController
        }

        configureGesturesRecognizer()
        setUpNotifications()
    }

    private func resolveDirection(with view: UIView) {
        if shouldReverseDirection {
            adjustedDirection = (preferences.basic.direction == .left ? .right : .left)
        } else {
            adjustedDirection = preferences.basic.direction
        }
    }

    // MARK: Storyboard

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segue = segue as? SideMenuSegue, let identifier = segue.identifier else {
            return
        }
        switch identifier {
        case contentSegueID:
            segue.contentType = .content
        case menuSegueID:
            segue.contentType = .menu
        default:
            break
        }
    }

    // MARK: Reveal/Hide Menu

    /// Reveals the menu.
    ///
    /// - Parameters:
    ///   - animated: If set to true, the process will be animated. The default is true.
    ///   - completion: Completion closure that will be executed after revealing the menu.
    open func revealMenu(animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        changeMenuVisibility(reveal: true, animated: animated, completion: completion)
    }

    /// Hides the menu.
    ///
    /// - Parameters:
    ///   - animated: If set to true, the process will be animated. The default is true.
    ///   - completion: Completion closure that will be executed after hiding the menu.
    open func hideMenu(animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        changeMenuVisibility(reveal: false, animated: animated, completion: completion)
    }

    private func changeMenuVisibility(reveal: Bool,
                                      animated: Bool = true,
                                      shouldCallDelegate: Bool = true,
                                      shouldChangeStatusBar: Bool = true,
                                      completion: ((Bool) -> Void)? = nil) {
        menuViewController.beginAppearanceTransition(reveal, animated: animated)

        if shouldCallDelegate {
            reveal ? delegate?.sideMenuControllerWillRevealMenu(self) : delegate?.sideMenuControllerWillHideMenu(self)
        }

        if reveal {
            addContentOverlayViewIfNeeded()
        }

        UIApplication.shared.beginIgnoringInteractionEvents()

        let animationClosure = {
            self.menuContainerView.frame = self.sideMenuFrame(visibility: reveal)
            self.contentContainerView.frame = self.contentFrame(visibility: reveal)
            if self.shouldShowShadowOnContent {
                self.contentContainerOverlay?.alpha = reveal ? self.preferences.animation.shadowAlpha : 0
            }
        }

        let animationCompletionClosure: (Bool) -> Void = { finish in
            self.menuViewController.endAppearanceTransition()

            if shouldCallDelegate {
                if reveal {
                    self.delegate?.sideMenuControllerDidRevealMenu(self)
                } else {
                    self.delegate?.sideMenuControllerDidHideMenu(self)
                }
            }

            if !reveal {
                self.contentContainerOverlay?.removeFromSuperview()
                self.contentContainerOverlay = nil
            }

            completion?(true)

            UIApplication.shared.endIgnoringInteractionEvents()

            self.isMenuRevealed = reveal
        }

        if animated {
            animateMenu(with: reveal,
                        shouldChangeStatusBar: shouldChangeStatusBar,
                        animations: animationClosure,
                        completion: animationCompletionClosure)
        } else {
            setStatusBar(hidden: reveal)
            animationClosure()
            animationCompletionClosure(true)
            completion?(true)
        }

    }

    private func animateMenu(with reveal: Bool,
                             shouldChangeStatusBar: Bool = true,
                             animations: @escaping () -> Void,
                             completion: ((Bool) -> Void)? = nil) {
        let shouldAnimateStatusBarChange = preferences.basic.statusBarBehavior != .hideOnMenu
        if shouldChangeStatusBar && !shouldAnimateStatusBarChange && reveal {
            setStatusBar(hidden: reveal)
        }
        let duration = reveal ? preferences.animation.revealDuration : preferences.animation.hideDuration
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: preferences.animation.dampingRatio,
                       initialSpringVelocity: preferences.animation.initialSpringVelocity,
                       options: preferences.animation.options,
                       animations: {
                        if shouldChangeStatusBar && shouldAnimateStatusBarChange {
                            self.setStatusBar(hidden: reveal)
                        }

                        animations()
        }, completion: { (finished) in
            if shouldChangeStatusBar && !shouldAnimateStatusBarChange && !reveal {
                self.setStatusBar(hidden: reveal)
            }

            completion?(finished)
        })
    }

    // MARK: Gesture Recognizer

    private func configureGesturesRecognizer() {
        // The gesture will be added anyway, its delegate will tell whether it should be recognized
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(SideMenuController.handlePanGesture(_:)))
        panGesture.delegate = self
        panGestureRecognizer = panGesture
        view.addGestureRecognizer(panGesture)
    }

    private func addContentOverlayViewIfNeeded() {
        guard contentContainerOverlay == nil else {
            return
        }

        let overlay = UIView(frame: contentContainerView.bounds)
        overlay.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        if !shouldShowShadowOnContent {
            overlay.backgroundColor = .clear
        } else {
            overlay.backgroundColor = SideMenuController.preferences.animation.shadowColor
            overlay.alpha = 0
        }

        // UIKit can coordinate overlay's tap gesture and controller view's pan gesture correctly
        let tapToHideGesture = UITapGestureRecognizer()
        tapToHideGesture.addTarget(self, action: #selector(SideMenuController.handleTapGesture(_:)))
        overlay.addGestureRecognizer(tapToHideGesture)

        contentContainerView.insertSubview(overlay, aboveSubview: contentViewController.view)
        contentContainerOverlay = overlay
        contentContainerOverlay?.accessibilityIdentifier = "ContentShadowOverlay"
    }

    @objc private func handleTapGesture(_ tap: UITapGestureRecognizer) {
        hideMenu()
    }

    @objc private func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        let menuWidth = preferences.basic.menuWidth
        let isLeft = adjustedDirection == .left
        var translation = pan.translation(in: pan.view).x
        let viewToAnimate: UIView
        let viewToAnimate2: UIView?
        var leftBorder: CGFloat
        var rightBorder: CGFloat
        let containerWidth: CGFloat
        switch preferences.basic.position {
        case .above:
            viewToAnimate = menuContainerView
            viewToAnimate2 = nil
            containerWidth = viewToAnimate.frame.width
            leftBorder = -containerWidth
            rightBorder = menuWidth - containerWidth
        case .under:
            viewToAnimate = contentContainerView
            viewToAnimate2 = nil
            containerWidth = viewToAnimate.frame.width
            leftBorder = 0
            rightBorder = menuWidth
        case .sideBySide:
            viewToAnimate = contentContainerView
            viewToAnimate2 = menuContainerView
            containerWidth = viewToAnimate.frame.width
            leftBorder = 0
            rightBorder = menuWidth
        }

        if !isLeft {
            swap(&leftBorder, &rightBorder)
            leftBorder *= -1
            rightBorder *= -1
        }

        switch pan.state {
        case .began:
            panningBeganPointX = viewToAnimate.frame.origin.x
            isValidatePanningBegan = false
        case .changed:
            let resultX = panningBeganPointX + translation
            let notReachLeftBorder = (!isLeft && preferences.basic.enableRubberEffectWhenPanning) || resultX >= leftBorder
            let notReachRightBorder = (isLeft && preferences.basic.enableRubberEffectWhenPanning) || resultX <= rightBorder
            guard notReachLeftBorder && notReachRightBorder else {
                return
            }

            if !isValidatePanningBegan {
                // Do some setup works in the initial step of validate panning. This can't be done in the `.began` period
                // because we can't know whether its a validate panning
                addContentOverlayViewIfNeeded()
                setStatusBar(hidden: true, animate: true)

                isValidatePanningBegan = true
            }

            let factor: CGFloat = isLeft ? 1 : -1
            let notReachDesiredBorder = isLeft ? resultX <= rightBorder : resultX >= leftBorder
            if notReachDesiredBorder {
                viewToAnimate.frame.origin.x = resultX
            } else {
                if !isMenuRevealed {
                    translation -= menuWidth * factor
                }
                viewToAnimate.frame.origin.x = (isLeft ? rightBorder : leftBorder) + factor * menuWidth
                    * log10(translation * factor / menuWidth + 1) * 0.5
            }

            if let viewToAnimate2 = viewToAnimate2 {
                viewToAnimate2.frame.origin.x = viewToAnimate.frame.origin.x - containerWidth * factor
            }

            if shouldShowShadowOnContent {
                let movingDistance: CGFloat
                if isLeft {
                    movingDistance = menuContainerView.frame.maxX
                } else {
                    movingDistance = menuWidth - menuContainerView.frame.minX
                }
                let shadowPercent = min(movingDistance / menuWidth, 1)
                contentContainerOverlay?.alpha = self.preferences.animation.shadowAlpha * shadowPercent
            }
        case .ended, .cancelled, .failed:
            let offset: CGFloat
            switch preferences.basic.position {
            case .above:
                offset = isLeft ? viewToAnimate.frame.maxX : containerWidth - viewToAnimate.frame.minX
            case .under, .sideBySide:
                offset = isLeft ? viewToAnimate.frame.minX : containerWidth - viewToAnimate.frame.maxX
            }
            let offsetPercent = offset / menuWidth
            let decisionPoint: CGFloat = isMenuRevealed ? 0.85 : 0.15
            if offsetPercent > decisionPoint {
                // We need to call the delegates, change the status bar only when the menu was previous hidden
                changeMenuVisibility(reveal: true, shouldCallDelegate: !isMenuRevealed, shouldChangeStatusBar: !isMenuRevealed)
            } else {
                changeMenuVisibility(reveal: false, shouldCallDelegate: isMenuRevealed, shouldChangeStatusBar: true)
            }
        default:
            break
        }
    }

    // MARK: Notification

    private func setUpNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(SideMenuController.appDidEnteredBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    private func unregisterNotifications() {
        // swiftlint:disable:next notification_center_detachment
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appDidEnteredBackground() {
        if preferences.basic.hideMenuWhenEnteringBackground {
            hideMenu(animated: false)
        }
    }

    // MARK: Status Bar

    private func setStatusBar(hidden: Bool, animate: Bool = false) {
        // UIKit provides `setNeedsStatusBarAppearanceUpdate` and couple of methods to animate the status bar changes.
        // The problem with this approach is it will hide the status bar and it's underlying space completely, as a result,
        // the navigation bar will go up as we don't expect.
        // So we need to manipulate the windows of status bar manually.

        let behavior = self.preferences.basic.statusBarBehavior
        guard let sbw = UIWindow.sb, sbw.isStatusBarHidden(with: behavior) != hidden else {
            return
        }

        if animate && behavior != .hideOnMenu {
            UIView.animate(withDuration: 0.4, animations: {
                sbw.setStatusBarHidden(hidden, with: behavior)
            })
        } else {
            sbw.setStatusBarHidden(hidden, with: behavior)
        }

        if behavior == .hideOnMenu {
            if !hidden {
                statusBarScreenShotView?.removeFromSuperview()
                statusBarScreenShotView = nil
            } else if statusBarScreenShotView == nil, let newStatusBarScreenShot = statusBarScreenShot() {
                statusBarScreenShotView = newStatusBarScreenShot
                contentContainerView.insertSubview(newStatusBarScreenShot, aboveSubview: contentViewController.view)
            }
        }
    }

    private func statusBarScreenShot() -> UIView? {
        let statusBarFrame = UIApplication.shared.statusBarFrame
        let screenshot = UIScreen.main.snapshotView(afterScreenUpdates: false)
        screenshot.frame = statusBarFrame
        screenshot.contentMode = .top
        screenshot.clipsToBounds = true
        return screenshot
    }

    open override var childForStatusBarStyle: UIViewController? {
        // Forward to the content view controller
        return contentViewController
    }

    open override var childForStatusBarHidden: UIViewController? {
        return contentViewController
    }

    // MARK: Caching

    /// Caches the closure that generate the view controller with identifier.
    ///
    /// It's useful when you want to configure the caching relation without instantiating the view controller immediately.
    ///
    /// - Parameters:
    ///   - viewControllerGenerator: The closure that generate the view controller. It will only executed when needed.
    ///   - identifier: Identifier used to change content view controller
    open func cache(viewControllerGenerator: @escaping () -> UIViewController?, with identifier: String) {
        lazyCachedViewControllerGenerators[identifier] = viewControllerGenerator
    }

    /// Caches the view controller with identifier.
    ///
    /// - Parameters:
    ///   - viewController: the view controller to cache
    ///   - identifier: the identifier
    open func cache(viewController: UIViewController, with identifier: String) {
        lazyCachedViewControllers[identifier] = viewController
    }

    /// Changes the content view controller to the cached one with given `identifier`.
    /// - Parameters:
    ///   - identifier: the identifier that associates with a cache view controller or generator.
    ///   - animated: whether the transition should be animated, default is `false`.
    ///   - completion: the completion closure will be called when the transition  complete. Notice that if the caller is the current content view controller, once the transition completed, the caller will be removed from the parent view controller, and it will have no access to the side menu controller via `sideMenuController`
    open func setContentViewController(with identifier: String,
                                       animated: Bool = false,
                                       completion: (() -> Void)? = nil) {
        if let viewController = lazyCachedViewControllers[identifier] {
            setContentViewController(to: viewController, animated: animated, completion: completion)
        } else if let viewController = lazyCachedViewControllerGenerators[identifier]?() {
            lazyCachedViewControllerGenerators[identifier] = nil
            lazyCachedViewControllers[identifier] = viewController
            setContentViewController(to: viewController, animated: animated, completion: completion)
        } else {
            fatalError("[SideMenu] View controller associated with \(identifier) not found!")
        }
    }

    /// Change the content view controller to `viewController`
    /// - Parameters:
    ///   - viewController: the view controller which will become the content view controller
    ///   - animated: whether the transition should be animated, default is `false`.
    ///   - completion: the completion closure will be called when the transition  complete. Notice that if the caller is the current content view controller, once the transition completed, the caller will be removed from the parent view
    open func setContentViewController(to viewController: UIViewController,
                                       animated: Bool = false,
                                       completion: (() -> Void)? = nil) {
        guard contentViewController !== viewController && isViewLoaded else {
            completion?()
            return
        }

        if animated {
            delegate?.sideMenuController(self, willShow: viewController, animated: animated)

            addChild(viewController)

            viewController.view.frame = view.bounds
            viewController.view.translatesAutoresizingMaskIntoConstraints = true
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            let animatorFromDelegate = delegate?.sideMenuController(self,
                                                                    animationControllerFrom: contentViewController,
                                                                    to: viewController)

            #if DEBUG
            if animatorFromDelegate == nil {
                // swiftlint:disable:next line_length
                print("[SideMenu] `setContentViewController` is called with animated while the delegate method return nil, fall back to the fade animation.")
            }
            #endif

            let animator = animatorFromDelegate ?? BasicTransitionAnimator()

            let transitionContext = SideMenuController.TransitionContext(with: contentViewController,
                                                                         toViewController: viewController)
            transitionContext.isAnimated = true
            transitionContext.isInteractive = false
            transitionContext.completion = { finish in
                self.unload(self.contentViewController)

                self.shouldCallSwitchingDelegate = false
                // It's tricky here.
                // `contentViewController` setter won't trigger due to the `viewController` already is added to the hierarchy.
                // `shouldCallSwitchingDelegate` also prevent the delegate from been calling.
                self.contentViewController = viewController
                self.shouldCallSwitchingDelegate = true

                self.delegate?.sideMenuController(self, didShow: viewController, animated: animated)

                viewController.didMove(toParent: self)

                completion?()
            }
            animator.animateTransition(using: transitionContext)

        } else {
            contentViewController = viewController
            completion?()
        }
    }

    /// Return the identifier of current content view controller.
    ///
    /// - Returns: if not exist, returns nil.
    open func currentCacheIdentifier() -> String? {
        guard let index = lazyCachedViewControllers.values.firstIndex(of: contentViewController) else {
            return nil
        }
        return lazyCachedViewControllers.keys[index]
    }

    /// Clears cached view controller or generators with identifier.
    ///
    /// - Parameter identifier: the identifier that associates with a cache view controller or generator.
    open func clearCache(with identifier: String) {
        lazyCachedViewControllerGenerators[identifier] = nil
        lazyCachedViewControllers[identifier] = nil
    }

    // MARK: - Helper Methods

    private func sideMenuFrame(visibility: Bool, targetSize: CGSize? = nil) -> CGRect {
        let position = preferences.basic.position
        switch position {
        case .above, .sideBySide:
            var baseFrame = CGRect(origin: view.frame.origin, size: targetSize ?? view.frame.size)
            if visibility {
                baseFrame.origin.x = preferences.basic.menuWidth - baseFrame.width
            } else {
                baseFrame.origin.x = -baseFrame.width
            }
            let factor: CGFloat = adjustedDirection == .left ? 1 : -1
            baseFrame.origin.x *= factor
            return CGRect(origin: baseFrame.origin, size: targetSize ?? baseFrame.size)
        case .under:
            return CGRect(origin: view.frame.origin, size: targetSize ?? view.frame.size)
        }
    }

    private func contentFrame(visibility: Bool, targetSize: CGSize? = nil) -> CGRect {
        let position = preferences.basic.position
        switch position {
        case .above:
            return CGRect(origin: view.frame.origin, size: targetSize ?? view.frame.size)
        case .under, .sideBySide:
            var baseFrame = CGRect(origin: view.frame.origin, size: targetSize ?? view.frame.size)
            if visibility {
                let factor: CGFloat = adjustedDirection == .left ? 1 : -1
                baseFrame.origin.x = preferences.basic.menuWidth * factor
            } else {
                baseFrame.origin.x = 0
            }
            return CGRect(origin: baseFrame.origin, size: targetSize ?? baseFrame.size)
        }
    }

    // MARK: Orientation

    open override var shouldAutorotate: Bool {
        if preferences.basic.shouldUseContentSupportedOrientations {
            return contentViewController.shouldAutorotate
        }
        return preferences.basic.shouldAutorotate
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if preferences.basic.shouldUseContentSupportedOrientations {
            return contentViewController.supportedInterfaceOrientations
        }
        return preferences.basic.supportedOrientations
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        hideMenu(animated: false, completion: { _ in
            // Temporally hide the menu container view for smooth animation
            self.menuContainerView.isHidden = true
            coordinator.animate(alongsideTransition: { _ in
                self.contentContainerView.frame = self.contentFrame(visibility: self.isMenuRevealed, targetSize: size)
            }, completion: { (_) in
                self.menuContainerView.isHidden = false
                self.menuContainerView.frame = self.sideMenuFrame(visibility: self.isMenuRevealed, targetSize: size)
            })
        })

        super.viewWillTransition(to: size, with: coordinator)
    }
}

// MARK: UIGestureRecognizerDelegate

extension SideMenuController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard preferences.basic.enablePanGesture else {
            return false
        }

        if isViewControllerInsideNavigationStack(for: touch.view) {
            return false
        }

        if touch.view is UISlider {
            return false
        }

        // If the view is scrollable in horizon direction, don't receive the touch
        if let scrollView = touch.view as? UIScrollView, scrollView.frame.width > scrollView.contentSize.width {
            return false
        }

        return true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let velocity = panGestureRecognizer?.velocity(in: view) {
            return isValidateHorizontalMovement(for: velocity)
        }
        return true
    }

    private func isViewControllerInsideNavigationStack(for view: UIView?) -> Bool {
        guard let view = view,
            let viewController = view.parentViewController else {
                return false
        }
        
        if let navigationController = viewController as? UINavigationController {
            return navigationController.viewControllers.count > 1
        } else if let navigationController = viewController.navigationController {
            if let index = navigationController.viewControllers.firstIndex(of: viewController) {
                return index > 0
            }
        }
        return false
    }

    private func isValidateHorizontalMovement(for velocity: CGPoint) -> Bool {
        if isMenuRevealed {
            return true
        }

        let direction = preferences.basic.direction
        var factor: CGFloat = direction == .left ? 1 : -1
        factor *= shouldReverseDirection ? -1 : 1
        guard velocity.x * factor > 0 else {
            return false
        }
        return abs(velocity.y / velocity.x) < 0.25
    }
}
