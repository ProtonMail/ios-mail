import SideMenuSwift

class PMSideMenuController: SideMenuController, SideMenuControllerDelegate {

    var willRevealMenu: (() -> Void)?
    var willHideMenu: (() -> Void)?

    private var isMenuPresented = false

    convenience init() {
        let contentViewController = UINavigationController(rootViewController: SkeletonViewController(style: .plain))
        self.init(contentViewController: contentViewController, menuViewController: UIViewController())
        delegate = self
    }

    override var childForStatusBarHidden: UIViewController? {
        isMenuPresented ? menuViewController : contentViewController
    }

    override var childForStatusBarStyle: UIViewController? {
        isMenuPresented ? menuViewController : contentViewController
    }

    func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
        isMenuPresented = true
        willRevealMenu?()
        self.handleStatusBar(add: true)
        setNeedsStatusBarAppearanceUpdate()
        sideMenuController.menuViewController.view.accessibilityElementsHidden = false
        sideMenuController.contentViewController.view.accessibilityElementsHidden = true
        sideMenuController.contentViewController.view.isUserInteractionEnabled = false
    }

    func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
        isMenuPresented = false
        willHideMenu?()
        self.handleStatusBar(add: false)
        setNeedsStatusBarAppearanceUpdate()
        sideMenuController.menuViewController.view.accessibilityElementsHidden = true
        sideMenuController.contentViewController.view.accessibilityElementsHidden = false
        sideMenuController.contentViewController.view.isUserInteractionEnabled = true
    }
}

extension PMSideMenuController {
    private var additionalHeight: CGFloat {
        // The status bar height is 44 when it has notch
        // is 20 when it doesn't have notch
        return UIDevice.hasNotch ? 22: 10
    }

    private func handleStatusBar(add: Bool) {
        if #available(iOS 13.0, *) {
            // iOS 13 above, the height of the status bar still keep even it is hidden
            self.addAdditionalHeight(add)
        } else {
            // iOS 12, the height of the status bar will be removed after hidden
            // So can't hide the bar, setting alpha to keep the status bar
            self.hideStatusBar(hide: add)
        }
    }

    /// add placeholder height to substitute status bar
    private func addAdditionalHeight(_ add: Bool) {
        if UIDevice.hasNotch && UIDevice.current.userInterfaceIdiom == .phone { return }

        let navigationController = self.contentViewController as? UINavigationController
        let top: CGFloat = add ? additionalHeight: 0.0
        self.additionalSafeAreaInsets.top = top
        navigationController?.additionalSafeAreaInsets.top = top
    }

    private func hideStatusBar(hide: Bool) {
        // We use a non-public key here to obtain the `statusBarWindow` window.
        // We have been using it in real world app and it won't be rejected by the review team for using this key.
        // From SideMenu library
        let s = "status", b = "Bar", w = "Window"
        var statusBar: UIWindow?
        if #available(iOS 13, *) {
            statusBar = nil
        } else {
            statusBar = UIApplication.shared.value(forKey: s + b + w) as? UIWindow
        }
        statusBar?.alpha = hide ? 0: 1
    }
}
