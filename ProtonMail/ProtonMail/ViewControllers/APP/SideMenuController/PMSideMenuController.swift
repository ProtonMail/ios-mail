import SideMenuSwift

class PMSideMenuController: SideMenuController, SideMenuControllerDelegate {

    var willRevealMenu: (() -> Void)?
    var willHideMenu: (() -> Void)?

    private var isMenuPresented = false

    convenience init() {
        let skeletonVC = SkeletonViewController()
        let contentViewController = UINavigationController(rootViewController: skeletonVC)
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
            self.addAdditionalHeight(add)
    }

    /// add placeholder height to substitute status bar
    private func addAdditionalHeight(_ add: Bool) {
        if UIDevice.hasNotch && UIDevice.current.userInterfaceIdiom == .phone { return }

        let navigationController = self.contentViewController as? UINavigationController
        let top: CGFloat = add ? additionalHeight: 0.0
        self.additionalSafeAreaInsets.top = top
        navigationController?.additionalSafeAreaInsets.top = top
    }
}
