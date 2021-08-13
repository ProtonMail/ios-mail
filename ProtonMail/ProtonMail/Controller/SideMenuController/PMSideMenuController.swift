import SideMenuSwift

class PMSideMenuController: SideMenuController, SideMenuControllerDelegate {

    var willRevealMenu: (() -> Void)?
    var willHideMenu: (() -> Void)?

    private var isMenuPresented = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)

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
        self.addAdditionalHeight(true)
        setNeedsStatusBarAppearanceUpdate()
        sideMenuController.contentViewController.view.accessibilityElementsHidden = true
        sideMenuController.contentViewController.view.isUserInteractionEnabled = false
    }

    func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
        isMenuPresented = false
        willHideMenu?()
        self.addAdditionalHeight(false)
        setNeedsStatusBarAppearanceUpdate()
        sideMenuController.contentViewController.view.accessibilityElementsHidden = false
        sideMenuController.contentViewController.view.isUserInteractionEnabled = true
    }

}

extension PMSideMenuController {
    var additionalHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height / 2
    }
    
    /// add placeholder height to substitute status bar
    func addAdditionalHeight(_ add: Bool) {
        if UIDevice.hasNotch { return }
        let navigationController = self.contentViewController as? UINavigationController
        let top = add ? additionalHeight: 0.0
        self.additionalSafeAreaInsets.top = top
        navigationController?.additionalSafeAreaInsets.top = top
    }
}
